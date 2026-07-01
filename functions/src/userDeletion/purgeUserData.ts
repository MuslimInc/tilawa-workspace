import {
  DocumentReference,
  FieldValue,
  Firestore,
} from "firebase-admin/firestore";

import { AuthGateway } from "./authGateway";
import {
  ANONYMIZED_PLACEHOLDER,
  PURGE_STEPS,
  PurgeStep,
  TEACHER_PROFILE_PII_FIELDS,
  TEACHER_PROFILE_SUBCOLLECTIONS,
} from "./deletionManifest";
import {
  appendDeletionAuditEvent,
  deletionStateRef,
  DeletionStateDoc,
} from "./deletionStateService";
import { walletIdForUser } from "../quranSessions/walletService";

const QUERY_PAGE_SIZE = 200;

export interface PurgeResult {
  status: "purged" | "skipped";
  stepsRun: PurgeStep[];
}

interface PurgeContext {
  db: Firestore;
  auth: AuthGateway;
  uid: string;
  state: DeletionStateDoc;
  stateRef: DocumentReference;
}

/** Purge blocked on data that needs a human decision (e.g. wallet funds). */
export class PurgeBlockedError extends Error {
  constructor(
    readonly step: PurgeStep,
    message: string,
  ) {
    super(message);
    this.name = "PurgeBlockedError";
  }
}

/**
 * Exports a compact financial snapshot to the state doc BEFORE the owned
 * tree is deleted — support/ops may need the Play Billing trail post-purge.
 */
async function stepFinancialSummary(ctx: PurgeContext): Promise<void> {
  const userRef = ctx.db.collection("users").doc(ctx.uid);
  const [purchases, cancellations, walletSnap] = await Promise.all([
    userRef.collection("purchases").get(),
    userRef.collection("cancellations").get(),
    ctx.db.collection("user_wallets").doc(walletIdForUser(ctx.uid)).get(),
  ]);
  const wallet = walletSnap.data() ?? {};
  await ctx.stateRef.update({
    financialSummary: {
      purchaseCount: purchases.size,
      purchaseIds: purchases.docs.map((doc) => doc.id).slice(0, 100),
      cancellationCount: cancellations.size,
      walletExisted: walletSnap.exists,
      walletAvailableBalance: Number(wallet.availableBalance ?? 0),
      walletHeldBalance: Number(wallet.heldBalance ?? 0),
      capturedAt: FieldValue.serverTimestamp(),
    },
  });
}

async function stepFcmTokens(ctx: PurgeContext): Promise<void> {
  const refs = await ctx.db
    .collection("users")
    .doc(ctx.uid)
    .collection("fcm_tokens")
    .listDocuments();
  await deleteRefs(ctx.db, refs);
}

async function stepTeacherApplication(ctx: PurgeContext): Promise<void> {
  await deleteByQueryLoop(ctx.db, () =>
    ctx.db
      .collection("quran_teacher_applications")
      .where("userId", "==", ctx.uid)
      .limit(QUERY_PAGE_SIZE)
      .get(),
  );
}

/**
 * Anonymizes the profile doc in place (other users' bookings reference the
 * doc id) and hard-deletes its subcollections.
 */
async function stepTeacherProfile(ctx: PurgeContext): Promise<void> {
  const profileId = ctx.state.teacherProfileId;
  if (!profileId) return;
  const profileRef = ctx.db
    .collection("quran_teacher_profiles")
    .doc(profileId);
  const snap = await profileRef.get();
  if (snap.exists) {
    const patch: Record<string, unknown> = {
      isActive: false,
      isPubliclyVisible: false,
      isDeleted: true,
    };
    for (const field of TEACHER_PROFILE_PII_FIELDS) {
      patch[field] =
        field === "displayName" ? ANONYMIZED_PLACEHOLDER : FieldValue.delete();
    }
    await profileRef.update(patch);
  }
  for (const name of TEACHER_PROFILE_SUBCOLLECTIONS) {
    await ctx.db.recursiveDelete(profileRef.collection(name));
  }
}

/**
 * Blanks the free-text reason on reschedule requests the user authored.
 * Cursor-paged (not query-until-empty): the patch does not change query
 * membership, so an until-empty loop would never terminate.
 */
async function stepRescheduleRequests(ctx: PurgeContext): Promise<void> {
  let cursor: FirebaseFirestore.QueryDocumentSnapshot | null = null;
  for (;;) {
    let query = ctx.db
      .collection("quran_reschedule_requests")
      .where("requestedByUserId", "==", ctx.uid)
      .orderBy("__name__")
      .limit(QUERY_PAGE_SIZE);
    if (cursor) query = query.startAfter(cursor);
    const snap = await query.get();
    if (snap.empty) return;
    const batch = ctx.db.batch();
    for (const doc of snap.docs) {
      batch.update(doc.ref, { reason: ANONYMIZED_PLACEHOLDER });
    }
    await batch.commit();
    cursor = snap.docs[snap.docs.length - 1];
  }
}

/**
 * Notification outbox: removes the uid from recipients; deletes docs where
 * the user was the sole recipient. Multi-recipient docs survive for the
 * other party.
 */
async function stepNotificationOutbox(ctx: PurgeContext): Promise<void> {
  for (;;) {
    const snap = await ctx.db
      .collection("quran_session_notifications")
      .where("recipientUserIds", "array-contains", ctx.uid)
      .limit(QUERY_PAGE_SIZE)
      .get();
    if (snap.empty) return;
    const batch = ctx.db.batch();
    for (const doc of snap.docs) {
      const recipients = (doc.data().recipientUserIds ?? []) as string[];
      if (recipients.length <= 1) {
        batch.delete(doc.ref);
      } else {
        batch.update(doc.ref, {
          recipientUserIds: FieldValue.arrayRemove(ctx.uid),
        });
      }
    }
    await batch.commit();
  }
}

/** Campaign docs target many users — only the uid is removed. */
async function stepCampaignTargets(ctx: PurgeContext): Promise<void> {
  await updateByQueryLoop(
    ctx.db,
    () =>
      ctx.db
        .collection("notifications")
        .where("targetUserIds", "array-contains", ctx.uid)
        .limit(QUERY_PAGE_SIZE)
        .get(),
    { targetUserIds: FieldValue.arrayRemove(ctx.uid) },
  );
}

async function stepMetrics(ctx: PurgeContext): Promise<void> {
  const refs = [
    ctx.db.collection("quran_student_metrics").doc(ctx.uid),
  ];
  if (ctx.state.teacherProfileId) {
    refs.push(
      ctx.db
        .collection("quran_teacher_metrics")
        .doc(ctx.state.teacherProfileId),
    );
  }
  await deleteRefs(ctx.db, refs);
}

/**
 * Balance was verified zero at request time; re-verify here because credits
 * (refunds/compensations) may have posted during the grace period.
 */
async function stepWallet(ctx: PurgeContext): Promise<void> {
  const walletRef = ctx.db
    .collection("user_wallets")
    .doc(walletIdForUser(ctx.uid));
  const snap = await walletRef.get();
  if (!snap.exists) return;
  const data = snap.data() ?? {};
  const available = Number(data.availableBalance ?? 0);
  const held = Number(data.heldBalance ?? 0);
  if (available > 0 || held > 0) {
    throw new PurgeBlockedError(
      "wallet",
      `Wallet balance is not zero (available ${available}, held ${held}); ` +
        "manual refund or write-off required before purge can proceed.",
    );
  }
  await walletRef.delete();
}

async function stepOwnedTree(ctx: PurgeContext): Promise<void> {
  await ctx.db.recursiveDelete(ctx.db.collection("users").doc(ctx.uid));
}

async function stepAuthUser(ctx: PurgeContext): Promise<void> {
  await ctx.auth.deleteUser(ctx.uid);
}

const STEP_HANDLERS: Record<PurgeStep, (ctx: PurgeContext) => Promise<void>> =
  {
    financial_summary: stepFinancialSummary,
    fcm_tokens: stepFcmTokens,
    teacher_application: stepTeacherApplication,
    teacher_profile: stepTeacherProfile,
    reschedule_requests: stepRescheduleRequests,
    notification_outbox: stepNotificationOutbox,
    campaign_targets: stepCampaignTargets,
    metrics: stepMetrics,
    wallet: stepWallet,
    owned_tree: stepOwnedTree,
    auth_user: stepAuthUser,
  };

/**
 * Runs the manifest for one user. Idempotent and resumable: each completed
 * step is checkpointed on the state doc (arrayUnion), so a crashed or timed
 * out run picks up where it left off on the next invocation. Auth deletion
 * is the last step by construction (PURGE_STEPS order).
 */
export async function purgeUser(input: {
  db: Firestore;
  auth: AuthGateway;
  uid: string;
  actorUid: string;
}): Promise<PurgeResult> {
  const { db, auth, uid, actorUid } = input;
  const stateRef = deletionStateRef(db, uid);
  const stateSnap = await stateRef.get();
  if (!stateSnap.exists) return { status: "skipped", stepsRun: [] };
  const state = stateSnap.data() as DeletionStateDoc;
  if (state.status !== "pending_deletion" && state.status !== "purging") {
    return { status: "skipped", stepsRun: [] };
  }

  if (state.status === "pending_deletion") {
    await stateRef.update({ status: "purging" });
    await appendDeletionAuditEvent(db, {
      targetUserId: uid,
      action: "purge_started",
      actorUid,
      targetEmailHash: state.targetEmailHash,
    });
  }

  const ctx: PurgeContext = { db, auth, uid, state, stateRef };
  const completed = new Set(state.completedSteps ?? []);
  const stepsRun: PurgeStep[] = [];

  try {
    for (const step of PURGE_STEPS) {
      if (completed.has(step)) continue;
      if (step === "auth_user" && state.firestoreOnly === true) {
        await stateRef.update({ completedSteps: FieldValue.arrayUnion(step) });
        stepsRun.push(step);
        continue;
      }
      await STEP_HANDLERS[step](ctx);
      await stateRef.update({ completedSteps: FieldValue.arrayUnion(step) });
      stepsRun.push(step);
    }
  } catch (error) {
    await appendDeletionAuditEvent(db, {
      targetUserId: uid,
      action: "purge_failed",
      actorUid,
      targetEmailHash: state.targetEmailHash,
      details: {
        message: error instanceof Error ? error.message : String(error),
        completedSteps: [...completed, ...stepsRun],
      },
    });
    throw error;
  }

  await stateRef.update({
    status: "purged",
    purgedAt: FieldValue.serverTimestamp(),
  });
  await appendDeletionAuditEvent(db, {
    targetUserId: uid,
    action: "purged",
    actorUid,
    targetEmailHash: state.targetEmailHash,
    details: { stepsRun },
  });

  console.info("purgeUser completed", { targetUserId: uid, stepsRun });
  return { status: "purged", stepsRun };
}

async function deleteRefs(
  db: Firestore,
  refs: DocumentReference[],
): Promise<void> {
  for (let i = 0; i < refs.length; i += 400) {
    const batch = db.batch();
    for (const ref of refs.slice(i, i + 400)) {
      batch.delete(ref);
    }
    await batch.commit();
  }
}

async function deleteByQueryLoop(
  db: Firestore,
  runQuery: () => Promise<FirebaseFirestore.QuerySnapshot>,
): Promise<void> {
  for (;;) {
    const snap = await runQuery();
    if (snap.empty) return;
    await deleteRefs(
      db,
      snap.docs.map((doc) => doc.ref),
    );
  }
}

async function updateByQueryLoop(
  db: Firestore,
  runQuery: () => Promise<FirebaseFirestore.QuerySnapshot>,
  patch: Record<string, unknown>,
): Promise<void> {
  for (;;) {
    const snap = await runQuery();
    if (snap.empty) return;
    const batch = db.batch();
    for (const doc of snap.docs) {
      batch.update(doc.ref, patch);
    }
    await batch.commit();
  }
}


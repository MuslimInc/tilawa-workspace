import * as logger from "firebase-functions/logger";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import {
  FieldValue,
  Firestore,
  Query,
  Timestamp,
  Transaction,
  getFirestore,
} from "firebase-admin/firestore";

import {
  DASHBOARD_SUMMARY_DOC_TYPE,
  MAX_DASHBOARD_SESSION_ENTRIES,
  SourceDoc,
  buildOverridesSection,
  buildSessionsSection,
  buildTeacherSection,
  buildWeeklyScheduleSection,
  overrideWindow,
  resolveHorizonDays,
  resolveSchedulingConfigSection,
  sessionsWindowStart,
} from "./dashboardSummaryService";

/**
 * Teacher dashboard read-model projector.
 *
 * Every rebuild re-queries the source of truth for the affected section
 * inside a transaction and merge-writes the summary doc — recompute, not
 * patch — so replayed or out-of-order trigger events converge without an
 * outbox (see docs/plans/teacher_dashboard_read_model_plan.md §3.2).
 */

export type SummarySection =
  | "sessions"
  | "weeklySchedule"
  | "overrides"
  | "teacherAndConfig";

const TEACHER_PROFILES = "quran_teacher_profiles";
const SESSIONS = "quran_sessions";
const AVAILABILITY_CONFIG = "availability_config";
const SCHEDULE_DOC = "schedule";
const AVAILABILITY_OVERRIDES = "availability_overrides";
const MARKET_CONFIGS = "quran_session_market_configs";
const PLATFORM_CONFIG = "quran_session_platform_config";
const GLOBAL_POLICY_DOC = "global";
const USERS = "users";

/// Prune batch bound — safety valve against unbounded collection-group scans.
const PRUNE_QUERY_LIMIT = 500;
/// Summaries untouched for this long get their windows refreshed by the
/// daily prune; anything younger was refreshed by a recent mutation.
const PRUNE_STALENESS_HOURS = 24;

export function summaryRef(db: Firestore, teacherProfileId: string) {
  return db
    .collection(TEACHER_PROFILES)
    .doc(teacherProfileId)
    .collection("dashboard")
    .doc("summary");
}

function scheduleRef(db: Firestore, teacherProfileId: string) {
  return db
    .collection(TEACHER_PROFILES)
    .doc(teacherProfileId)
    .collection(AVAILABILITY_CONFIG)
    .doc(SCHEDULE_DOC);
}

function sessionsQuery(db: Firestore, teacherProfileId: string, now: Date): Query {
  return db
    .collection(SESSIONS)
    .where("teacherId", "==", teacherProfileId)
    .where("endsAt", ">=", sessionsWindowStart(now))
    .orderBy("endsAt")
    // +1 row as the truncation probe (see buildSessionsSection).
    .limit(MAX_DASHBOARD_SESSION_ENTRIES + 1);
}

function toSourceDocs(
  snap: FirebaseFirestore.QuerySnapshot,
): SourceDoc[] {
  return snap.docs.map((doc) => ({ id: doc.id, data: doc.data() ?? {} }));
}

async function readHorizonDays(
  tx: Transaction,
  db: Firestore,
  teacherProfileId: string,
): Promise<number> {
  const summarySnap = await tx.get(summaryRef(db, teacherProfileId));
  const stored = summarySnap.data()?.horizonDays;
  return typeof stored === "number" && stored > 0
    ? stored
    : resolveHorizonDays({});
}

async function buildTeacherAndConfigPatch(
  tx: Transaction,
  db: Firestore,
  teacherProfileId: string,
): Promise<Record<string, unknown> | null> {
  const profileSnap = await tx.get(
    db.collection(TEACHER_PROFILES).doc(teacherProfileId),
  );
  if (!profileSnap.exists) {
    return null;
  }
  const profileData = profileSnap.data() ?? {};
  const ownerUserId =
    typeof profileData.userId === "string" && profileData.userId !== ""
      ? profileData.userId
      : teacherProfileId;

  const userSnap = await tx.get(db.collection(USERS).doc(ownerUserId));
  const sessionsProfile = userSnap.data()?.quranSessionsProfile as
    | Record<string, unknown>
    | undefined;
  const countryCode =
    typeof sessionsProfile?.countryCode === "string" &&
    sessionsProfile.countryCode !== ""
      ? sessionsProfile.countryCode
      : null;

  const marketSnap =
    countryCode != null
      ? await tx.get(db.collection(MARKET_CONFIGS).doc(countryCode))
      : null;
  const globalSnap = await tx.get(
    db.collection(PLATFORM_CONFIG).doc(GLOBAL_POLICY_DOC),
  );

  const resolved = resolveSchedulingConfigSection(
    (marketSnap?.data()?.scheduling as Record<string, unknown> | undefined) ??
      null,
    (globalSnap.data()?.scheduling as Record<string, unknown> | undefined) ??
      null,
  );

  return {
    teacher: buildTeacherSection(profileData, countryCode),
    schedulingConfig: resolved.config,
    schedulingConfigSource: resolved.source,
    horizonDays: resolveHorizonDays(resolved.config),
  };
}

/**
 * Rebuilds [sections] of the summary doc for [teacherProfileId] in one
 * transaction. Returns false when the teacher profile does not exist (the
 * summary is deleted instead of rebuilt).
 */
export async function rebuildSummarySections(
  db: Firestore,
  teacherProfileId: string,
  sections: ReadonlySet<SummarySection>,
  now: Date = new Date(),
): Promise<boolean> {
  return db.runTransaction(async (tx) => {
    const patch: Record<string, unknown> = {};

    if (sections.has("teacherAndConfig")) {
      const teacherPatch = await buildTeacherAndConfigPatch(
        tx,
        db,
        teacherProfileId,
      );
      if (teacherPatch == null) {
        tx.delete(summaryRef(db, teacherProfileId));
        return false;
      }
      Object.assign(patch, teacherPatch);
    }

    if (sections.has("sessions")) {
      const snap = await tx.get(sessionsQuery(db, teacherProfileId, now));
      const section = buildSessionsSection(toSourceDocs(snap));
      if (section.sessionsTruncated) {
        logger.warn(
          "[TeacherDashboardProjection] sessions truncated; client will fall back to direct queries",
          {
            teacherProfileId,
            cap: MAX_DASHBOARD_SESSION_ENTRIES,
          },
        );
      }
      patch.sessions = section.sessions;
      patch.sessionsTruncated = section.sessionsTruncated;
    }

    if (sections.has("weeklySchedule")) {
      const snap = await tx.get(scheduleRef(db, teacherProfileId));
      patch.weeklySchedule = buildWeeklyScheduleSection(
        snap.exists ? (snap.data() ?? {}) : null,
      );
    }

    if (sections.has("overrides")) {
      const horizonDays =
        typeof patch.horizonDays === "number"
          ? patch.horizonDays
          : await readHorizonDays(tx, db, teacherProfileId);
      const window = overrideWindow(now, horizonDays);
      const snap = await tx.get(
        db
          .collection(TEACHER_PROFILES)
          .doc(teacherProfileId)
          .collection(AVAILABILITY_OVERRIDES)
          .where("date", ">=", window.fromKey)
          .where("date", "<", window.toKeyExclusive),
      );
      patch.overrides = buildOverridesSection(toSourceDocs(snap));
    }

    tx.set(
      summaryRef(db, teacherProfileId),
      {
        ...patch,
        docType: DASHBOARD_SUMMARY_DOC_TYPE,
        teacherProfileId,
        revision: FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    return true;
  });
}

// ── Triggers ────────────────────────────────────────────────────────────────

export const projectDashboardOnSessionWrite = onDocumentWritten(
  `${SESSIONS}/{sessionId}`,
  async (event) => {
    const after = event.data?.after.data();
    const before = event.data?.before.data();
    const teacherIds = new Set<string>();
    for (const data of [before, after]) {
      const teacherId = data?.teacherId;
      if (typeof teacherId === "string" && teacherId !== "") {
        teacherIds.add(teacherId);
      }
    }
    for (const teacherId of teacherIds) {
      await rebuildSummarySections(getFirestore(), teacherId, new Set(["sessions"]));
    }
  },
);

export const projectDashboardOnScheduleWrite = onDocumentWritten(
  `${TEACHER_PROFILES}/{teacherId}/${AVAILABILITY_CONFIG}/{configDocId}`,
  async (event) => {
    if (event.params.configDocId !== SCHEDULE_DOC) {
      return;
    }
    await rebuildSummarySections(
      getFirestore(),
      event.params.teacherId,
      new Set(["weeklySchedule"]),
    );
  },
);

export const projectDashboardOnOverrideWrite = onDocumentWritten(
  `${TEACHER_PROFILES}/{teacherId}/${AVAILABILITY_OVERRIDES}/{dateKey}`,
  async (event) => {
    await rebuildSummarySections(
      getFirestore(),
      event.params.teacherId,
      new Set(["overrides"]),
    );
  },
);

export const projectDashboardOnTeacherProfileWrite = onDocumentWritten(
  `${TEACHER_PROFILES}/{teacherId}`,
  async (event) => {
    const db = getFirestore();
    if (!event.data?.after.exists) {
      // Teacher profile removed — drop the projection with it.
      await summaryRef(db, event.params.teacherId).delete();
      return;
    }
    await rebuildSummarySections(
      db,
      event.params.teacherId,
      new Set(["teacherAndConfig"]),
    );
  },
);

export const projectDashboardOnUserCountryChange = onDocumentWritten(
  `${USERS}/{userId}`,
  async (event) => {
    const countryOf = (data: Record<string, unknown> | undefined) => {
      const profile = data?.quranSessionsProfile as
        | Record<string, unknown>
        | undefined;
      return typeof profile?.countryCode === "string"
        ? profile.countryCode
        : null;
    };
    const before = countryOf(event.data?.before.data());
    const after = countryOf(event.data?.after.data());
    if (before === after) {
      return;
    }

    const db = getFirestore();
    const teacherSnap = await db
      .collection(TEACHER_PROFILES)
      .where("userId", "==", event.params.userId)
      .limit(1)
      .get();
    if (teacherSnap.empty) {
      return;
    }
    await rebuildSummarySections(
      db,
      teacherSnap.docs[0].id,
      // Config resolution depends on countryCode; horizon (and thus the
      // overrides window) may change with it.
      new Set(["teacherAndConfig", "overrides"]),
    );
  },
);

// ── Scheduled prune ─────────────────────────────────────────────────────────

export async function pruneStaleDashboardSummaries(
  db: Firestore,
  now: Date = new Date(),
): Promise<number> {
  const cutoff = Timestamp.fromMillis(
    now.getTime() - PRUNE_STALENESS_HOURS * 60 * 60 * 1000,
  );
  const stale = await db
    .collectionGroup("dashboard")
    .where("docType", "==", DASHBOARD_SUMMARY_DOC_TYPE)
    .where("updatedAt", "<", cutoff)
    .orderBy("updatedAt")
    .limit(PRUNE_QUERY_LIMIT)
    .get();

  let refreshed = 0;
  for (const doc of stale.docs) {
    const teacherProfileId = doc.data().teacherProfileId;
    if (typeof teacherProfileId !== "string" || teacherProfileId === "") {
      continue;
    }
    await rebuildSummarySections(
      db,
      teacherProfileId,
      new Set(["sessions", "overrides"]),
      now,
    );
    refreshed += 1;
  }
  if (refreshed > 0) {
    logger.info("[TeacherDashboardProjection] pruned stale summaries", {
      refreshed,
    });
  }
  return refreshed;
}

export const pruneDashboardSummaries = onSchedule(
  "every 24 hours",
  async () => {
    await pruneStaleDashboardSummaries(getFirestore());
  },
);

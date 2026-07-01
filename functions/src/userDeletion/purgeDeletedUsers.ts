import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { Timestamp, getFirestore } from "firebase-admin/firestore";

import { adminAuthGateway } from "./authGateway";
import { USER_DELETION_STATE_COLLECTION } from "./deletionManifest";
import { deletionStateRef, DeletionStateDoc } from "./deletionStateService";
import { purgeUser } from "./purgeUserData";
import { mapGuardError } from "./requestUserDeletion";
import { DeletionGuardError } from "./userDeletionLogic";

/**
 * Bound each run; the daily cadence drains any backlog. `purging` is included
 * so interrupted runs resume (crash/timeout mid-purge).
 */
const PURGE_BATCH_LIMIT = 10;

export const purgeDeletedUsers = onSchedule(
  { schedule: "every day 03:00", timeZone: "UTC", timeoutSeconds: 540 },
  async () => {
    const db = getFirestore();
    const auth = adminAuthGateway();
    const due = await db
      .collection(USER_DELETION_STATE_COLLECTION)
      .where("status", "in", ["pending_deletion", "purging"])
      .where("purgeAfter", "<=", Timestamp.now())
      .orderBy("purgeAfter")
      .limit(PURGE_BATCH_LIMIT)
      .get();

    for (const doc of due.docs) {
      const uid = (doc.data() as DeletionStateDoc).userId ?? doc.id;
      try {
        await purgeUser({ db, auth, uid, actorUid: "system" });
      } catch (error) {
        // Error isolation: one blocked user (e.g. nonzero wallet) must not
        // starve the rest of the batch. purge_failed audit already written.
        console.error(`purgeDeletedUsers failed for ${uid}:`, error);
      }
    }

    if (!due.empty) {
      console.log(`purgeDeletedUsers processed ${due.docs.length} user(s).`);
    }
  },
);

/**
 * Admin-only: runs the purge pipeline for one user immediately. Used by ops
 * and integration tests. Refuses to run before purgeAfter unless
 * `overrideGracePeriod: true` is passed explicitly.
 * Requires custom claim `{ admin: true }`.
 */
export const forcePurgeUser = onCall(
  { enforceAppCheck: false, timeoutSeconds: 540 },
  async (request) => {
    if (!request.auth?.token.admin) {
      throw new HttpsError("permission-denied", "Admin access required.");
    }
    const data = (request.data ?? {}) as {
      targetUserId?: string;
      overrideGracePeriod?: boolean;
    };
    const targetUserId = data.targetUserId?.trim();
    if (!targetUserId) {
      throw new HttpsError("invalid-argument", "targetUserId required.");
    }

    const db = getFirestore();
    try {
      const stateSnap = await deletionStateRef(db, targetUserId).get();
      if (!stateSnap.exists) {
        throw new DeletionGuardError(
          "not-found",
          "No deletion is pending for this user.",
        );
      }
      const state = stateSnap.data() as DeletionStateDoc;
      if (state.status !== "pending_deletion" && state.status !== "purging") {
        throw new DeletionGuardError(
          "failed-precondition",
          `Deletion state is '${state.status}'; nothing to purge.`,
        );
      }
      if (
        state.purgeAfter.toMillis() > Date.now() &&
        data.overrideGracePeriod !== true
      ) {
        throw new DeletionGuardError(
          "failed-precondition",
          "Grace period has not elapsed. Pass overrideGracePeriod: true to " +
            "purge immediately.",
        );
      }

      const result = await purgeUser({
        db,
        auth: adminAuthGateway(),
        uid: targetUserId,
        actorUid: request.auth.uid,
      });
      console.info("forcePurgeUser", {
        adminUid: request.auth.uid,
        targetUserId,
        overrideGracePeriod: data.overrideGracePeriod === true,
        result: result.status,
      });
      return result;
    } catch (error) {
      mapGuardError(error);
    }
  },
);

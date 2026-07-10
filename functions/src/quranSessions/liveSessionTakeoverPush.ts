import { FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import * as logger from "firebase-functions/logger";

import { DEVICES_SUBCOLLECTION } from "../deviceRegistry";

/**
 * Device-targeted `session_taken_over` FCM — ADR-008 Phase 2.
 *
 * Sent to the **old** device when a user takes over a live session from
 * another device. Distinct from the legacy whole-app `session_revoked`: this
 * is session-scoped and never triggers a sign-out — the receiver leaves the RTC
 * room and shows a "Moved to another device" UI.
 */

export const SESSION_TAKEN_OVER_ACTION = "session_taken_over";

export interface SendSessionTakenOverPushInput {
  db: FirebaseFirestore.Firestore;
  uid: string;
  /** Device being evicted (the previous lock holder). */
  deviceId: string;
  sessionId: string;
}

export type TakeoverPushFn = (
  input: SendSessionTakenOverPushInput,
) => Promise<void>;

async function readDeviceFcmToken(
  db: FirebaseFirestore.Firestore,
  uid: string,
  deviceId: string,
): Promise<string | null> {
  const snap = await db
    .collection("users")
    .doc(uid)
    .collection(DEVICES_SUBCOLLECTION)
    .doc(deviceId)
    .get();
  if (!snap.exists) {
    return null;
  }
  if (snap.get("revokedAt") != null) {
    return null;
  }
  const token = snap.get("fcmToken");
  return typeof token === "string" && token.length > 0 ? token : null;
}

function isStaleTokenError(error: unknown): boolean {
  if (!error || typeof error !== "object") return false;
  const code = (error as { code?: string }).code;
  return (
    code === "messaging/invalid-registration-token"
    || code === "messaging/registration-token-not-registered"
  );
}

async function pruneDeviceFcmToken(
  db: FirebaseFirestore.Firestore,
  uid: string,
  deviceId: string,
): Promise<void> {
  try {
    await db
      .collection("users")
      .doc(uid)
      .collection(DEVICES_SUBCOLLECTION)
      .doc(deviceId)
      .set(
        {
          fcmToken: FieldValue.delete(),
          revokedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
  } catch (error) {
    logger.warn("session_taken_over prune token failed", {
      uid,
      deviceId,
      error: error instanceof Error ? error.message : String(error),
    });
  }
}

/**
 * Sends a `session_taken_over` push to the evicted device. Best-effort: a send
 * failure never fails the RTC token issuance. Stale tokens are pruned.
 */
export const sendSessionTakenOverPush: TakeoverPushFn = async (input) => {
  const token = await readDeviceFcmToken(
    input.db,
    input.uid,
    input.deviceId,
  );
  if (token == null) {
    return;
  }
  try {
    await getMessaging().send({
      token,
      data: {
        actionType: SESSION_TAKEN_OVER_ACTION,
        type: SESSION_TAKEN_OVER_ACTION,
        sessionId: input.sessionId,
      },
      android: { priority: "high" },
      apns: {
        payload: {
          aps: {
            "content-available": 1,
          },
        },
      },
    });
  } catch (error) {
    if (isStaleTokenError(error)) {
      await pruneDeviceFcmToken(input.db, input.uid, input.deviceId);
    }
    logger.warn("session_taken_over push failed", {
      uid: input.uid,
      deviceId: input.deviceId,
      error: error instanceof Error ? error.message : String(error),
    });
  }
};

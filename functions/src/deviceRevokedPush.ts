import { FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import * as logger from "firebase-functions/logger";

import { DEVICES_SUBCOLLECTION } from "./deviceRegistry";

/**
 * Device-targeted `device_revoked` FCM — ADR-008 Phase 3 (Manage Devices).
 *
 * Sent to a device that was signed out remotely (via "Sign out this device" or
 * "Sign out all other devices"). Unlike the session-scoped `session_taken_over`
 * push, this instructs the receiver to sign out of the whole app. Best-effort:
 * a send failure never fails the revoking callable — the device also discovers
 * its own `revokedAt` on next resume / token refresh.
 */
export const DEVICE_REVOKED_ACTION = "device_revoked";

export interface SendDeviceRevokedPushInput {
  db: FirebaseFirestore.Firestore;
  uid: string;
  /** Device being signed out. */
  deviceId: string;
  /** Push token captured before `revokedAt` cleared it, if available. */
  token: string | null;
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
      .set({ fcmToken: FieldValue.delete() }, { merge: true });
  } catch (error) {
    logger.warn("device_revoked prune token failed", {
      uid,
      deviceId,
      error: error instanceof Error ? error.message : String(error),
    });
  }
}

/**
 * Sends a `device_revoked` push to a signed-out device. Best-effort; stale
 * tokens are pruned. No-op when [token] is null.
 */
export async function sendDeviceRevokedPush(
  input: SendDeviceRevokedPushInput,
): Promise<void> {
  if (input.token == null || input.token.length === 0) {
    return;
  }
  try {
    await getMessaging().send({
      token: input.token,
      data: {
        actionType: DEVICE_REVOKED_ACTION,
        type: DEVICE_REVOKED_ACTION,
        deviceId: input.deviceId,
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
    logger.warn("device_revoked push failed", {
      uid: input.uid,
      deviceId: input.deviceId,
      error: error instanceof Error ? error.message : String(error),
    });
  }
}

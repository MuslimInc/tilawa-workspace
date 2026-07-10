import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { onCall, HttpsError } from "firebase-functions/v2/https";

import { DEVICES_SUBCOLLECTION } from "./deviceRegistry";
import { sendDeviceRevokedPush } from "./deviceRevokedPush";
import { sessionCallableHttpsOptions } from "./quranSessions/sessionCallableOptions";

/**
 * Manage Devices write callables — ADR-008 Phase 3.
 *
 * Soft, per-device server-side revocation: Firebase cannot revoke a single
 * device's refresh token (`revokeRefreshTokens` kills *all* sessions), so
 * "sign out this device" / "sign out all other devices" set `revokedAt` on the
 * target `users/{uid}/devices/{deviceId}` docs. Each targeted device discovers
 * this on next resume / token refresh (and via the `device_revoked` push) and
 * signs itself out. We **never** call `revokeRefreshTokens` here — the current
 * device must stay signed in. Reads (the device list) stay client-side
 * (owner-read); only these writes are Cloud-Functions-only.
 */

export interface RevokeDeviceRequest {
  deviceId?: unknown;
}

export interface SignOutOtherDevicesRequest {
  currentDeviceId?: unknown;
}

/** Pure: device ids to sign out — every active id except the current one. */
export function selectOtherDeviceIds(
  activeDeviceIds: readonly string[],
  currentDeviceId: string,
): string[] {
  return activeDeviceIds.filter((id) => id !== currentDeviceId);
}

function requireAuthUid(uid: string | undefined): string {
  if (!uid) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  return uid;
}

function requireDeviceId(value: unknown, field: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new HttpsError("invalid-argument", `${field} is required.`);
  }
  return value;
}

/**
 * Signs out one device the caller owns by setting `revokedAt` and clearing its
 * push token. Idempotent: a missing/already-revoked device returns ok.
 */
export const revokeDevice = onCall(
  sessionCallableHttpsOptions,
  async (request): Promise<{ revoked: boolean; deviceId: string }> => {
    const uid = requireAuthUid(request.auth?.uid);
    const data = (request.data ?? {}) as RevokeDeviceRequest;
    const deviceId = requireDeviceId(data.deviceId, "deviceId");

    const db = getFirestore();
    const deviceRef = db
      .collection("users")
      .doc(uid)
      .collection(DEVICES_SUBCOLLECTION)
      .doc(deviceId);

    const snap = await deviceRef.get();
    if (!snap.exists) {
      return { revoked: false, deviceId };
    }
    const token = snap.get("fcmToken");
    const pushToken = typeof token === "string" && token.length > 0
      ? token
      : null;

    await deviceRef.set(
      {
        revokedAt: FieldValue.serverTimestamp(),
        fcmToken: FieldValue.delete(),
      },
      { merge: true },
    );

    await sendDeviceRevokedPush({ db, uid, deviceId, token: pushToken });
    logger.info("revokeDevice", { uid, deviceId });
    return { revoked: true, deviceId };
  },
);

/**
 * Signs out every device the caller owns *except* the current one. Never
 * revokes the caller's own refresh token, so the current device stays live.
 */
export const signOutOtherDevices = onCall(
  sessionCallableHttpsOptions,
  async (request): Promise<{ revokedDeviceIds: string[] }> => {
    const uid = requireAuthUid(request.auth?.uid);
    const data = (request.data ?? {}) as SignOutOtherDevicesRequest;
    const currentDeviceId = requireDeviceId(
      data.currentDeviceId,
      "currentDeviceId",
    );

    const db = getFirestore();
    const devicesCol = db
      .collection("users")
      .doc(uid)
      .collection(DEVICES_SUBCOLLECTION);
    const devicesSnap = await devicesCol.get();

    const activeIds: string[] = [];
    const tokenByDeviceId = new Map<string, string | null>();
    for (const doc of devicesSnap.docs) {
      if (doc.get("revokedAt") != null) {
        continue; // already signed out
      }
      activeIds.push(doc.id);
      const token = doc.get("fcmToken");
      tokenByDeviceId.set(
        doc.id,
        typeof token === "string" && token.length > 0 ? token : null,
      );
    }

    const targets = selectOtherDeviceIds(activeIds, currentDeviceId);
    if (targets.length === 0) {
      return { revokedDeviceIds: [] };
    }

    const batch = db.batch();
    for (const deviceId of targets) {
      batch.set(
        devicesCol.doc(deviceId),
        {
          revokedAt: FieldValue.serverTimestamp(),
          fcmToken: FieldValue.delete(),
        },
        { merge: true },
      );
    }
    await batch.commit();

    await Promise.all(
      targets.map((deviceId) =>
        sendDeviceRevokedPush({
          db,
          uid,
          deviceId,
          token: tokenByDeviceId.get(deviceId) ?? null,
        })
      ),
    );

    logger.info("signOutOtherDevices", {
      uid,
      currentDeviceId,
      revokedCount: targets.length,
    });
    return { revokedDeviceIds: targets };
  },
);

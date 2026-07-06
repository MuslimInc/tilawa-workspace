import { getAuth } from "firebase-admin/auth";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { logger } from "firebase-functions/v2";
import { onCall, HttpsError } from "firebase-functions/v2/https";

import { sessionCallableHttpsOptions } from "./quranSessions/sessionCallableOptions";
import {
  type DevicePlatform,
  type DeviceRegistrationMode,
  type DeviceRegistrationStatus,
  planDeviceRegistration,
  readServerSessionEpoch,
} from "./quranSessions/sessionRegistration";
import { buildSessionRevokedNotificationCopy } from "./quranSessions/sessionRevokedNotification";
import {
  buildDeviceRegistryDoc,
  DEVICES_SUBCOLLECTION,
  isDeviceCapExceeded,
} from "./deviceRegistry";

export const SESSION_REVOKED_ACTION = "session_revoked";

const SAFE_DEVICE_INFO_KEYS = new Set([
  "manufacturer",
  "model",
  "os",
  "osVersion",
  "appBuildNumber",
  "appVersion",
]);

const UNSAFE_DEVICE_INFO_KEYS = new Set([
  "adid",
  "advertisingid",
  "androidid",
  "android_id",
  "imei",
  "mac",
  "macaddress",
  "mac_address",
  "meid",
  "phone",
  "phonenumber",
  "phone_number",
  "serial",
  "serialnumber",
  "serial_number",
]);

interface RegisterActiveDeviceRequest {
  deviceId?: unknown;
  fcmToken?: unknown;
  platform?: unknown;
  appVersion?: unknown;
  registrationMode?: unknown;
  deviceInfo?: unknown;
  signOut?: unknown;
  writeDeviceRegistry?: unknown;
}

interface RegisterActiveDeviceResponse {
  status: DeviceRegistrationStatus;
  sessionEpoch?: number;
  epoch?: number;
  activeDeviceId?: string;
  // ADR-008 Phase 0 — populated only when device-registry write was requested.
  deviceCapExceeded?: boolean;
  registeredDeviceCount?: number;
}

interface DeviceRegistryOutcome {
  deviceCapExceeded: boolean;
  registeredDeviceCount: number;
}

interface TransactionResult extends RegisterActiveDeviceResponse {
  deviceChanged: boolean;
  noOp: boolean;
  previousToken: string | null;
}

export function parseDevicePlatform(value: unknown): DevicePlatform | null {
  if (value === "android" || value === "ios" || value === "web") {
    return value;
  }
  return null;
}

export function parseRegistrationMode(
  value: unknown,
): DeviceRegistrationMode | null {
  if (value === "explicit_sign_in" || value === "passive_sync") {
    return value;
  }
  return null;
}

export function sanitizeDeviceInfo(
  value: unknown,
): Record<string, string> | undefined {
  if (value == null) {
    return undefined;
  }
  if (typeof value !== "object" || Array.isArray(value)) {
    throw new HttpsError("invalid-argument", "deviceInfo must be an object.");
  }

  const sanitized: Record<string, string> = {};
  for (const [key, raw] of Object.entries(value as Record<string, unknown>)) {
    const normalizedKey = key.toLowerCase();
    if (UNSAFE_DEVICE_INFO_KEYS.has(normalizedKey)) {
      throw new HttpsError(
        "invalid-argument",
        `Unsafe deviceInfo field rejected: ${key}.`,
      );
    }
    if (!SAFE_DEVICE_INFO_KEYS.has(key) || raw == null) {
      continue;
    }
    if (typeof raw !== "string") {
      throw new HttpsError(
        "invalid-argument",
        `deviceInfo.${key} must be a string.`,
      );
    }
    const trimmed = raw.trim();
    if (trimmed.length > 0) {
      sanitized[key] = trimmed.slice(0, 120);
    }
  }

  return Object.keys(sanitized).length === 0 ? undefined : sanitized;
}

function optionalString(value: unknown, fieldName: string): string | undefined {
  if (value == null) {
    return undefined;
  }
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", `${fieldName} must be a string.`);
  }
  const trimmed = value.trim();
  return trimmed.length === 0 ? undefined : trimmed.slice(0, 240);
}

function requiredString(value: unknown, fieldName: string): string {
  const parsed = optionalString(value, fieldName);
  if (parsed == null) {
    throw new HttpsError("invalid-argument", `${fieldName} is required.`);
  }
  return parsed;
}

export async function deleteLegacyFcmTokens(
  userRef: FirebaseFirestore.DocumentReference,
): Promise<void> {
  const tokensSnap = await userRef.collection("fcm_tokens").get();
  if (tokensSnap.empty) {
    return;
  }
  const batch = userRef.firestore.batch();
  for (const doc of tokensSnap.docs) {
    batch.delete(doc.ref);
  }
  await batch.commit();
}

async function sendSessionRevokedPush(
  token: string,
  userData: Record<string, unknown> | undefined | null,
): Promise<void> {
  const copy = buildSessionRevokedNotificationCopy(userData);
  try {
    await getMessaging().send({
      token,
      data: {
        actionType: SESSION_REVOKED_ACTION,
        type: SESSION_REVOKED_ACTION,
        title: copy.title,
        body: copy.body,
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
    logger.warn("session_revoked push failed", {
      error: error instanceof Error ? error.message : String(error),
    });
  }
}

function activeDeviceWrite(
  plan: ReturnType<typeof planDeviceRegistration>,
  input: {
    appVersion?: string;
    deviceInfo?: Record<string, string>;
    fcmToken?: string;
    platform: DevicePlatform;
  },
  now: FirebaseFirestore.FieldValue,
): Record<string, unknown> {
  const sessionUpdate: Record<string, unknown> = {
    epoch: plan.nextEpoch,
    activeDeviceId: plan.nextActiveDeviceId,
    lastSeenAt: now,
    platform: input.platform,
  };
  if (plan.deviceChanged) {
    sessionUpdate.registeredAt = now;
  }
  if (input.appVersion) {
    sessionUpdate.appVersion = input.appVersion;
  }
  if (input.deviceInfo) {
    sessionUpdate.deviceInfo = input.deviceInfo;
  }

  const notifications: Record<string, unknown> = {
    platform: input.platform,
  };
  if (input.fcmToken) {
    notifications.activeFcmToken = input.fcmToken;
    notifications.tokenUpdatedAt = now;
  } else if (plan.deviceChanged) {
    notifications.activeFcmToken = FieldValue.delete();
    notifications.tokenUpdatedAt = FieldValue.delete();
  }

  return {
    session: sessionUpdate,
    notifications,
    updatedAt: now,
  };
}

function activeSessionClearWrite(
  now: FirebaseFirestore.FieldValue,
): Record<string, unknown> {
  return {
    session: {
      activeDeviceId: FieldValue.delete(),
      registeredAt: FieldValue.delete(),
      lastSeenAt: FieldValue.delete(),
      platform: FieldValue.delete(),
      appVersion: FieldValue.delete(),
      deviceInfo: FieldValue.delete(),
    },
    notifications: {
      activeFcmToken: FieldValue.delete(),
      tokenUpdatedAt: FieldValue.delete(),
      platform: FieldValue.delete(),
    },
    updatedAt: now,
  };
}

function responseFor(
  status: DeviceRegistrationStatus,
  sessionEpoch: number,
  activeDeviceId: string,
): RegisterActiveDeviceResponse {
  return {
    status,
    sessionEpoch,
    epoch: sessionEpoch,
    activeDeviceId: activeDeviceId || undefined,
  };
}

/**
 * Registers or passively refreshes the caller's active device.
 *
 * Only `explicit_sign_in` may replace `session.activeDeviceId`. `passive_sync`
 * can update last-seen/device token data for the already-active device only.
 */
export const registerActiveDevice = onCall(
  sessionCallableHttpsOptions,
  async (request): Promise<RegisterActiveDeviceResponse> => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const data = (request.data ?? {}) as RegisterActiveDeviceRequest;
    const deviceId = requiredString(data.deviceId, "deviceId");
    const fcmToken = optionalString(data.fcmToken, "fcmToken");
    const platform = parseDevicePlatform(data.platform);
    const registrationMode = parseRegistrationMode(data.registrationMode);
    const appVersion = optionalString(data.appVersion, "appVersion");
    const deviceInfo = sanitizeDeviceInfo(data.deviceInfo);
    const signOut = data.signOut === true;
    // ADR-008 Phase 0: client (gated by `deviceRegistryWriteEnabled`) opts into
    // the additive, non-exclusive device registry. Never written on sign-out.
    const writeDeviceRegistry = data.writeDeviceRegistry === true && !signOut;

    if (!platform) {
      throw new HttpsError("invalid-argument", "platform is required.");
    }
    if (!registrationMode) {
      throw new HttpsError(
        "invalid-argument",
        "registrationMode must be explicit_sign_in or passive_sync.",
      );
    }

    const db = getFirestore();
    const userRef = db.collection("users").doc(uid);
    const now = FieldValue.serverTimestamp();

    let supersededUserData: Record<string, unknown> | undefined;
    let deviceRegistryOutcome: DeviceRegistryOutcome | undefined;
    const result = await db.runTransaction(async (tx) => {
      const userSnap = await tx.get(userRef);
      const userData = userSnap.data() ?? {};
      supersededUserData = userData;

      // All transaction reads must precede all writes: read the registry (if
      // requested) here, then stage its write below alongside the session write.
      const devicesCol = userRef.collection(DEVICES_SUBCOLLECTION);
      if (writeDeviceRegistry) {
        const devicesSnap = await tx.get(devicesCol);
        let deviceExists = false;
        const activeDeviceIds: string[] = [];
        for (const doc of devicesSnap.docs) {
          if (doc.id === deviceId) {
            deviceExists = true;
          }
          if (doc.get("revokedAt") == null) {
            activeDeviceIds.push(doc.id);
          }
        }
        const alreadyActive = activeDeviceIds.includes(deviceId);
        deviceRegistryOutcome = {
          deviceCapExceeded: isDeviceCapExceeded(activeDeviceIds, deviceId),
          registeredDeviceCount: alreadyActive
            ? activeDeviceIds.length
            : activeDeviceIds.length + 1,
        };
        // Additive: never blocks or logs out; the write proceeds even past the
        // legacy session cap. Runs on every plan branch (incl. noOp) so a real
        // second device is still recorded.
        tx.set(
          devicesCol.doc(deviceId),
          buildDeviceRegistryDoc(
            { platform, fcmToken, appVersion, deviceInfo, existing: deviceExists },
            now,
          ),
          { merge: true },
        );
      }

      const currentSession = userData.session as
        | { epoch?: number; activeDeviceId?: string }
        | undefined;
      const currentNotifications = userData.notifications as
        | { activeFcmToken?: string }
        | undefined;

      const plan = planDeviceRegistration(
        currentSession
          ? {
              epoch: readServerSessionEpoch(userData),
              activeDeviceId: String(currentSession.activeDeviceId ?? ""),
            }
          : null,
        {
          deviceId,
          fcmToken,
          platform,
          appVersion,
          registrationMode,
          signOut,
        },
      );

      const previousToken =
        typeof currentNotifications?.activeFcmToken === "string"
          ? currentNotifications.activeFcmToken
          : null;

      if (plan.noOp) {
        return {
          ...responseFor(
            plan.status,
            plan.nextEpoch,
            plan.nextActiveDeviceId,
          ),
          previousToken: null,
          deviceChanged: false,
          noOp: true,
        } satisfies TransactionResult;
      }

      if (plan.clearActiveSession) {
        tx.set(userRef, activeSessionClearWrite(now), { merge: true });
        return {
          ...responseFor(
            plan.status,
            plan.nextEpoch,
            plan.nextActiveDeviceId,
          ),
          previousToken: null,
          deviceChanged: false,
          noOp: false,
        } satisfies TransactionResult;
      }

      tx.set(
        userRef,
        activeDeviceWrite(
          plan,
          {
            appVersion,
            deviceInfo,
            fcmToken,
            platform,
          },
          now,
        ),
        { merge: true },
      );

      return {
        ...responseFor(plan.status, plan.nextEpoch, plan.nextActiveDeviceId),
        previousToken:
          plan.deviceChanged && previousToken && previousToken !== fcmToken
            ? previousToken
            : null,
        deviceChanged: plan.deviceChanged,
        noOp: false,
      } satisfies TransactionResult;
    });

    if (!result.noOp) {
      await deleteLegacyFcmTokens(userRef);
    }

    if (result.deviceChanged) {
      await getAuth().revokeRefreshTokens(uid);
      if (result.previousToken) {
        await sendSessionRevokedPush(result.previousToken, supersededUserData);
      }
    }

    return {
      status: result.status,
      sessionEpoch: result.sessionEpoch,
      epoch: result.epoch,
      activeDeviceId: result.activeDeviceId,
      ...(deviceRegistryOutcome ?? {}),
    };
  },
);

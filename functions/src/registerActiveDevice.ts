import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { getAuth } from "firebase-admin/auth";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

import {
  type DevicePlatform,
  planDeviceRegistration,
  readServerSessionEpoch,
} from "./quranSessions/sessionRegistration";
import { buildSessionRevokedNotificationCopy } from "./quranSessions/sessionRevokedNotification";

export const SESSION_REVOKED_ACTION = "session_revoked";

interface RegisterActiveDeviceRequest {
  deviceId: string;
  fcmToken: string;
  platform: DevicePlatform;
  appVersion?: string;
  signOut?: boolean;
}

interface RegisterActiveDeviceResponse {
  epoch: number;
  activeDeviceId: string;
}

function parsePlatform(value: unknown): DevicePlatform | null {
  if (value === "android" || value === "ios" || value === "web") {
    return value;
  }
  return null;
}

async function deleteLegacyFcmTokens(
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

/**
 * Registers the caller's active device + FCM token (server-authoritative).
 *
 * Bumps [session.epoch] when [deviceId] changes, revokes refresh tokens, and
 * notifies the superseded device via FCM data message `session_revoked`.
 */
export const registerActiveDevice = onCall(
  { enforceAppCheck: false },
  async (request): Promise<RegisterActiveDeviceResponse> => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const data = request.data as RegisterActiveDeviceRequest;
    const deviceId = data.deviceId?.trim() ?? "";
    const fcmToken = data.fcmToken?.trim() ?? "";
    const platform = parsePlatform(data.platform);
    const signOut = data.signOut === true;

    if (!signOut) {
      if (!deviceId) {
        throw new HttpsError("invalid-argument", "deviceId is required.");
      }
      if (!fcmToken) {
        throw new HttpsError("invalid-argument", "fcmToken is required.");
      }
      if (!platform) {
        throw new HttpsError("invalid-argument", "platform is required.");
      }
    }

    const db = getFirestore();
    const userRef = db.collection("users").doc(uid);
    const now = FieldValue.serverTimestamp();

    let supersededUserData: Record<string, unknown> | undefined;
    const result = await db.runTransaction(async (tx) => {
      const userSnap = await tx.get(userRef);
      const userData = userSnap.data() ?? {};
      supersededUserData = userData;
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
          platform: platform ?? "android",
          appVersion: data.appVersion,
          signOut,
        },
      );

      const previousToken = currentNotifications?.activeFcmToken ?? null;

      if (plan.clearTokenOnly) {
        tx.set(
          userRef,
          {
            notifications: {
              activeFcmToken: FieldValue.delete(),
              tokenUpdatedAt: FieldValue.delete(),
              platform: FieldValue.delete(),
            },
            updatedAt: now,
          },
          { merge: true },
        );
        return {
          epoch: plan.nextEpoch,
          activeDeviceId: plan.nextActiveDeviceId,
          previousToken: null as string | null,
          deviceChanged: false,
        };
      }

      const sessionUpdate: Record<string, unknown> = {
        epoch: plan.nextEpoch,
        activeDeviceId: plan.nextActiveDeviceId,
        registeredAt: now,
        platform,
      };
      if (data.appVersion) {
        sessionUpdate.appVersion = data.appVersion;
      }

      tx.set(
        userRef,
        {
          session: sessionUpdate,
          notifications: {
            activeFcmToken: fcmToken,
            tokenUpdatedAt: now,
            platform,
          },
          updatedAt: now,
        },
        { merge: true },
      );

      return {
        epoch: plan.nextEpoch,
        activeDeviceId: plan.nextActiveDeviceId,
        previousToken:
          plan.deviceChanged && previousToken && previousToken !== fcmToken
            ? previousToken
            : null,
        deviceChanged: plan.deviceChanged,
      };
    });

    await deleteLegacyFcmTokens(userRef);

    if (result.deviceChanged) {
      await getAuth().revokeRefreshTokens(uid);
      if (result.previousToken) {
        await sendSessionRevokedPush(result.previousToken, supersededUserData);
      }
    }

    return {
      epoch: result.epoch,
      activeDeviceId: result.activeDeviceId,
    };
  },
);

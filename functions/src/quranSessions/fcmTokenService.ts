import { FieldValue } from "firebase-admin/firestore";
import { getMessaging, MulticastMessage } from "firebase-admin/messaging";

import { DEVICES_SUBCOLLECTION } from "../deviceRegistry";
import { isMultiDeviceLoginEnabled } from "../multiDeviceLogin";

export interface UserFcmToken {
  userId: string;
  deviceId?: string;
  token: string;
}

export async function getActiveFcmToken(
  db: FirebaseFirestore.Firestore,
  userId: string,
): Promise<string | null> {
  if (isMultiDeviceLoginEnabled()) {
    const tokens = await collectDeviceRegistryFcmTokens(db, userId);
    return tokens[0]?.token ?? null;
  }
  const snap = await db.collection("users").doc(userId).get();
  const token = snap.data()?.notifications?.activeFcmToken;
  return typeof token === "string" && token.length > 0 ? token : null;
}

export async function collectActiveFcmTokens(
  db: FirebaseFirestore.Firestore,
  userIds: string[],
): Promise<UserFcmToken[]> {
  if (isMultiDeviceLoginEnabled()) {
    return collectDeviceRegistryFcmTokensForUsers(db, userIds);
  }
  const tokens: UserFcmToken[] = [];
  const batchSize = 10;

  for (let i = 0; i < userIds.length; i += batchSize) {
    const batch = userIds.slice(i, i + batchSize);
    const snapshots = await Promise.all(
      batch.map((userId) => db.collection("users").doc(userId).get()),
    );
    for (let index = 0; index < snapshots.length; index += 1) {
      const snap = snapshots[index];
      const token = snap.data()?.notifications?.activeFcmToken;
      if (typeof token === "string" && token.length > 0) {
        tokens.push({ userId: batch[index], token });
      }
    }
  }

  return tokens;
}

async function collectDeviceRegistryFcmTokensForUsers(
  db: FirebaseFirestore.Firestore,
  userIds: string[],
): Promise<UserFcmToken[]> {
  const tokens: UserFcmToken[] = [];
  const batchSize = 10;

  for (let i = 0; i < userIds.length; i += batchSize) {
    const batch = userIds.slice(i, i + batchSize);
    const entries = await Promise.all(
      batch.map((userId) => collectDeviceRegistryFcmTokens(db, userId)),
    );
    for (const userEntries of entries) {
      tokens.push(...userEntries);
    }
  }

  return tokens;
}

async function collectDeviceRegistryFcmTokens(
  db: FirebaseFirestore.Firestore,
  userId: string,
): Promise<UserFcmToken[]> {
  const devicesSnap = await db
    .collection("users")
    .doc(userId)
    .collection(DEVICES_SUBCOLLECTION)
    .get();
  const tokens: UserFcmToken[] = [];

  for (const doc of devicesSnap.docs) {
    if (doc.get("revokedAt") != null) {
      continue;
    }
    const token = doc.get("fcmToken");
    if (typeof token === "string" && token.length > 0) {
      tokens.push({ userId, deviceId: doc.id, token });
    }
  }

  return tokens;
}

/** @deprecated Use [collectActiveFcmTokens]. */
export async function collectFcmTokens(
  db: FirebaseFirestore.Firestore,
  userIds: string[],
): Promise<string[]> {
  const entries = await collectActiveFcmTokens(db, userIds);
  return entries.map((entry) => entry.token);
}

export async function clearInvalidActiveFcmTokens(
  db: FirebaseFirestore.Firestore,
  entries: UserFcmToken[],
  response: { responses: Array<{ success: boolean; error?: { code: string } }> },
): Promise<void> {
  const invalidEntries = new Map<string, UserFcmToken>();

  response.responses.forEach((resp, index) => {
    if (
      !resp.success &&
      resp.error &&
      (resp.error.code === "messaging/invalid-registration-token" ||
        resp.error.code === "messaging/registration-token-not-registered")
    ) {
      const entry = entries[index];
      if (entry) {
        invalidEntries.set(
          `${entry.userId}/${entry.deviceId ?? "legacy"}`,
          entry,
        );
      }
    }
  });

  if (invalidEntries.size === 0) {
    return;
  }

  const batch = db.batch();
  for (const entry of invalidEntries.values()) {
    const userRef = db.collection("users").doc(entry.userId);
    if (entry.deviceId) {
      batch.set(
        userRef.collection(DEVICES_SUBCOLLECTION).doc(entry.deviceId),
        {
          fcmToken: FieldValue.delete(),
          revokedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    } else {
      batch.set(
        userRef,
        {
          notifications: {
            activeFcmToken: FieldValue.delete(),
            tokenUpdatedAt: FieldValue.delete(),
          },
        },
        { merge: true },
      );
    }
    // Legacy cleanup if token doc still exists.
    batch.delete(userRef.collection("fcm_tokens").doc(entry.token));
  }
  await batch.commit();
}

/** @deprecated Use [clearInvalidActiveFcmTokens]. */
export async function cleanupInvalidFcmTokens(
  db: FirebaseFirestore.Firestore,
  tokens: string[],
  response: { responses: Array<{ success: boolean; error?: { code: string } }> },
  userIds: string[],
): Promise<void> {
  const entries: UserFcmToken[] = [];
  for (let i = 0; i < tokens.length; i += 1) {
    entries.push({
      userId: userIds[Math.min(i, userIds.length - 1)] ?? "",
      token: tokens[i],
    });
  }
  await clearInvalidActiveFcmTokens(db, entries, response);
}

export interface PushDeliveryResult {
  successCount: number;
  failureCount: number;
}

export async function sendPushToUsers(
  db: FirebaseFirestore.Firestore,
  userIds: string[],
  title: string,
  body: string,
  actionType: string,
  actionData?: Record<string, string>,
): Promise<PushDeliveryResult> {
  const entries = await collectActiveFcmTokens(db, userIds);
  if (entries.length === 0) {
    throw new Error("No FCM tokens found");
  }

  const tokens = entries.map((entry) => entry.token);
  const dataPayload: Record<string, string> = {
    title,
    body,
    actionType,
    ...actionData,
  };

  const isIncomingCall = actionType === "incoming_quran_session_call";

  const message: MulticastMessage = {
    tokens,
    // For incoming calls, omit top-level notification so Android receives a pure data message
    // and our background isolate can show the full-screen intent without a duplicate system notification.
    notification: isIncomingCall ? undefined : { title, body },
    data: dataPayload,
    android: { priority: "high" },
    apns: {
      payload: {
        aps: {
          // Ensure iOS still shows a notification for incoming calls
          alert: isIncomingCall ? { title, body } : undefined,
          sound: "default",
          badge: 1,
        },
      },
    },
  };

  const response = await getMessaging().sendEachForMulticast(message);
  await clearInvalidActiveFcmTokens(db, entries, response);

  return {
    successCount: response.successCount,
    failureCount: response.failureCount,
  };
}

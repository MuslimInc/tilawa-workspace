import { FieldValue } from "firebase-admin/firestore";
import { getMessaging, MulticastMessage } from "firebase-admin/messaging";

export interface UserFcmToken {
  userId: string;
  token: string;
}

export async function getActiveFcmToken(
  db: FirebaseFirestore.Firestore,
  userId: string,
): Promise<string | null> {
  const snap = await db.collection("users").doc(userId).get();
  const token = snap.data()?.notifications?.activeFcmToken;
  return typeof token === "string" && token.length > 0 ? token : null;
}

export async function collectActiveFcmTokens(
  db: FirebaseFirestore.Firestore,
  userIds: string[],
): Promise<UserFcmToken[]> {
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
  const invalidByUser = new Map<string, string>();

  response.responses.forEach((resp, index) => {
    if (
      !resp.success &&
      resp.error &&
      (resp.error.code === "messaging/invalid-registration-token" ||
        resp.error.code === "messaging/registration-token-not-registered")
    ) {
      const entry = entries[index];
      if (entry) {
        invalidByUser.set(entry.userId, entry.token);
      }
    }
  });

  if (invalidByUser.size === 0) {
    return;
  }

  const batch = db.batch();
  for (const [userId, token] of invalidByUser) {
    const userRef = db.collection("users").doc(userId);
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
    // Legacy cleanup if token doc still exists.
    batch.delete(userRef.collection("fcm_tokens").doc(token));
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

  const message: MulticastMessage = {
    tokens,
    notification: { title, body },
    data: dataPayload,
    android: { priority: "high" },
    apns: {
      payload: {
        aps: {
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

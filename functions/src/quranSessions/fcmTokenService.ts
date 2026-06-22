import { getMessaging, MulticastMessage } from "firebase-admin/messaging";

export async function collectFcmTokens(
  db: FirebaseFirestore.Firestore,
  userIds: string[],
): Promise<string[]> {
  const tokens: string[] = [];
  const batchSize = 10;

  for (let i = 0; i < userIds.length; i += batchSize) {
    const batch = userIds.slice(i, i + batchSize);
    const snapshots = await Promise.all(
      batch.map((userId) =>
        db.collection("users").doc(userId).collection("fcm_tokens").get(),
      ),
    );
    for (const snapshot of snapshots) {
      for (const doc of snapshot.docs) {
        const token = doc.data().token as string | undefined;
        if (token) {
          tokens.push(token);
        }
      }
    }
  }

  return tokens;
}

export async function cleanupInvalidFcmTokens(
  db: FirebaseFirestore.Firestore,
  tokens: string[],
  response: { responses: Array<{ success: boolean; error?: { code: string } }> },
  userIds: string[],
): Promise<void> {
  const invalidTokens: string[] = [];

  response.responses.forEach((resp, index) => {
    if (
      !resp.success &&
      resp.error &&
      (resp.error.code === "messaging/invalid-registration-token" ||
        resp.error.code === "messaging/registration-token-not-registered")
    ) {
      invalidTokens.push(tokens[index]);
    }
  });

  if (invalidTokens.length === 0) {
    return;
  }

  const deletePromises: Promise<FirebaseFirestore.WriteResult>[] = [];
  for (const userId of userIds) {
    for (const token of invalidTokens) {
      deletePromises.push(
        db
          .collection("users")
          .doc(userId)
          .collection("fcm_tokens")
          .doc(token)
          .delete(),
      );
    }
  }

  await Promise.all(deletePromises);
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
  const tokens = await collectFcmTokens(db, userIds);
  if (tokens.length === 0) {
    throw new Error("No FCM tokens found");
  }

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
  await cleanupInvalidFcmTokens(db, tokens, response, userIds);

  return {
    successCount: response.successCount,
    failureCount: response.failureCount,
  };
}

export { verifySupportPurchase } from "./verifySupportPurchase";
export { crashlyticsToGithubIssue } from "./crashlyticsToGithubIssue";

import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging, MulticastMessage } from "firebase-admin/messaging";

initializeApp();

interface NotificationDoc {
  title: string;
  body: string;
  targetType: "all" | "single" | "selected";
  targetUserIds: string[];
  actionType: string;
  actionData?: string;
  status: "pending" | "sent" | "failed";
}

/**
 * Triggered when a new notification document is created in Firestore.
 * Reads the target users' FCM tokens and sends push notifications.
 */
export const sendNotification = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const notification = snapshot.data() as NotificationDoc;
    const notificationRef = snapshot.ref;

    if (notification.status !== "pending") return;

    const db = getFirestore();

    try {
      // 1. Resolve target user IDs
      const userIds = await resolveUserIds(db, notification);
      if (userIds.length === 0) {
        await notificationRef.update({ status: "failed", error: "No target users found" });
        return;
      }

      // 2. Collect all FCM tokens for target users
      const tokens = await collectTokens(db, userIds);
      if (tokens.length === 0) {
        await notificationRef.update({ status: "failed", error: "No FCM tokens found" });
        return;
      }

      // 3. Build and send FCM message
      const dataPayload: Record<string, string> = {
        title: notification.title,
        body: notification.body,
        actionType: notification.actionType,
      };
      if (notification.actionData) {
        dataPayload.actionData = notification.actionData;
      }

      const message: MulticastMessage = {
        tokens,
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: dataPayload,
        android: {
          priority: "high",
        },
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

      // 4. Clean up invalid tokens
      await cleanupInvalidTokens(db, tokens, response, userIds);

      // 5. Update notification status
      await notificationRef.update({
        status: "sent",
        sentAt: Date.now(),
        successCount: response.successCount,
        failureCount: response.failureCount,
      });
    } catch (error) {
      console.error("Failed to send notification:", error);
      await notificationRef.update({
        status: "failed",
        error: error instanceof Error ? error.message : "Unknown error",
      });
    }
  }
);

/**
 * Resolve target user IDs based on targetType.
 */
async function resolveUserIds(
  db: FirebaseFirestore.Firestore,
  notification: NotificationDoc
): Promise<string[]> {
  if (notification.targetType === "all") {
    const usersSnapshot = await db.collection("users").get();
    return usersSnapshot.docs.map((doc) => doc.id);
  }
  return notification.targetUserIds;
}

/**
 * Collect all FCM tokens for a list of user IDs.
 * Returns a flat array of token strings.
 */
async function collectTokens(
  db: FirebaseFirestore.Firestore,
  userIds: string[]
): Promise<string[]> {
  const tokens: string[] = [];

  // Process in batches of 10 to avoid excessive parallel reads
  const batchSize = 10;
  for (let i = 0; i < userIds.length; i += batchSize) {
    const batch = userIds.slice(i, i + batchSize);
    const promises = batch.map((userId) =>
      db.collection("users").doc(userId).collection("fcm_tokens").get()
    );
    const snapshots = await Promise.all(promises);
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

/**
 * Remove tokens that FCM reports as invalid (unregistered).
 */
async function cleanupInvalidTokens(
  db: FirebaseFirestore.Firestore,
  tokens: string[],
  response: { responses: Array<{ success: boolean; error?: { code: string } }> },
  userIds: string[]
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

  if (invalidTokens.length === 0) return;

  // Delete invalid tokens from all target users
  const deletePromises: Promise<FirebaseFirestore.WriteResult>[] = [];
  for (const userId of userIds) {
    for (const token of invalidTokens) {
      deletePromises.push(
        db
          .collection("users")
          .doc(userId)
          .collection("fcm_tokens")
          .doc(token)
          .delete()
      );
    }
  }

  await Promise.all(deletePromises);
  console.log(`Cleaned up ${invalidTokens.length} invalid token(s)`);
}

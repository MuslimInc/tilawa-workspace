import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import {
  buildNotificationCopy,
  computeRetryBackoffMs,
  MAX_NOTIFICATION_RETRIES,
  SessionNotificationKind,
} from "./notificationOutboxService";
import { sendPushToUsers } from "./fcmTokenService";

interface SessionNotificationRecord {
  sessionId: string;
  kind: SessionNotificationKind;
  recipientUserIds: string[];
  payload?: Record<string, unknown>;
  deliveryStatus?: { push?: string; email?: string };
  retryCount?: number;
  nextRetryAt?: Timestamp | null;
  scheduledFor?: Timestamp | null;
}

export async function deliverSessionNotificationDoc(
  ref: FirebaseFirestore.DocumentReference,
  notification: SessionNotificationRecord,
): Promise<void> {
  const db = getFirestore();
  const pushStatus = notification.deliveryStatus?.push ?? "pending";
  if (pushStatus === "sent" || pushStatus === "failed") {
    return;
  }

  const retryCount = notification.retryCount ?? 0;
  if (retryCount >= MAX_NOTIFICATION_RETRIES && pushStatus !== "sent") {
    await ref.update({
      "deliveryStatus.push": "failed",
      lastError: "Max retries exceeded",
    });
    return;
  }

  const nextRetryAt = notification.nextRetryAt ?? null;
  if (nextRetryAt && nextRetryAt.toMillis() > Date.now()) {
    return;
  }

  const scheduledFor = notification.scheduledFor ?? null;
  if (scheduledFor && scheduledFor.toMillis() > Date.now()) {
    return;
  }

  const recipientUserIds = notification.recipientUserIds ?? [];
  if (recipientUserIds.length === 0) {
    await ref.update({
      "deliveryStatus.push": "failed",
      "deliveryStatus.email": "skipped",
      lastError: "No recipients",
    });
    return;
  }

  const payload = notification.payload ?? {};
  const copy = buildNotificationCopy(notification.kind, payload);
  const actionData: Record<string, string> = {
    sessionId: notification.sessionId,
  };

  try {
    const result = await sendPushToUsers(
      db,
      recipientUserIds,
      copy.title,
      copy.body,
      copy.actionType,
      actionData,
    );

    if (result.successCount === 0) {
      throw new Error("FCM delivery failed for all tokens");
    }

    await ref.update({
      "deliveryStatus.push": "sent",
      "deliveryStatus.email": "skipped",
      sentAt: Timestamp.now(),
      lastError: null,
      successCount: result.successCount,
      failureCount: result.failureCount,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown error";
    const nextRetry = retryCount + 1;

    if (nextRetry >= MAX_NOTIFICATION_RETRIES) {
      await ref.update({
        "deliveryStatus.push": "failed",
        "deliveryStatus.email": "skipped",
        retryCount: nextRetry,
        nextRetryAt: null,
        lastError: message,
      });
      return;
    }

    await ref.update({
      "deliveryStatus.push": "pending",
      "deliveryStatus.email": "skipped",
      retryCount: nextRetry,
      nextRetryAt: Timestamp.fromMillis(
        Date.now() + computeRetryBackoffMs(nextRetry),
      ),
      lastError: message,
    });
  }
}

export async function processDueNotificationRetries(
  db: FirebaseFirestore.Firestore,
): Promise<number> {
  const now = Timestamp.now();
  const pending = await db
    .collection("quran_session_notifications")
    .where("deliveryStatus.push", "==", "pending")
    .where("retryCount", ">", 0)
    .where("nextRetryAt", "<=", now)
    .limit(50)
    .get();

  let processed = 0;
  for (const doc of pending.docs) {
    await deliverSessionNotificationDoc(
      doc.ref,
      doc.data() as SessionNotificationRecord,
    );
    processed += 1;
  }
  return processed;
}

export const deliverSessionNotification = onDocumentCreated(
  "quran_session_notifications/{notificationId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }
    await deliverSessionNotificationDoc(
      snapshot.ref,
      snapshot.data() as SessionNotificationRecord,
    );
  },
);

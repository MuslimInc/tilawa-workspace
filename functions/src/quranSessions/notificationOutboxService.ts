import {
  Timestamp,
  WriteBatch,
} from "firebase-admin/firestore";
import { nowServer } from "./sessionLifecycleService";

export type SessionNotificationKind =
  | "bookingConfirmed"
  | "cancellation"
  | "rescheduleRequested"
  | "rescheduleConfirmed"
  | "noShowMarked"
  | "compensationIssued"
  | "reminder";

export interface EnqueueSessionNotificationInput {
  sessionId: string;
  aggregateId: string;
  kind: SessionNotificationKind;
  recipientUserIds: string[];
  payload?: Record<string, unknown>;
  scheduledFor?: Timestamp;
}

export interface SessionNotificationDoc {
  notificationId: string;
  sessionId: string;
  aggregateId: string;
  kind: SessionNotificationKind;
  recipientUserIds: string[];
  payload: Record<string, unknown>;
  channels: string[];
  deliveryStatus: { push: string; email: string };
  retryCount: number;
  nextRetryAt: Timestamp | null;
  scheduledFor: Timestamp | null;
  createdAt: FirebaseFirestore.FieldValue;
  sentAt: Timestamp | null;
  lastError: string | null;
}

export interface NotificationCopy {
  title: string;
  body: string;
  actionType: string;
}

const DEFAULT_CHANNELS = ["push", "email"];

export function buildSessionNotificationDoc(
  notificationId: string,
  input: EnqueueSessionNotificationInput,
): SessionNotificationDoc {
  return {
    notificationId,
    sessionId: input.sessionId,
    aggregateId: input.aggregateId,
    kind: input.kind,
    recipientUserIds: input.recipientUserIds,
    payload: input.payload ?? {},
    channels: DEFAULT_CHANNELS,
    deliveryStatus: { push: "pending", email: "pending" },
    retryCount: 0,
    nextRetryAt: null,
    scheduledFor: input.scheduledFor ?? null,
    createdAt: nowServer(),
    sentAt: null,
    lastError: null,
  };
}

export function buildNotificationCopy(
  kind: SessionNotificationKind,
  payload: Record<string, unknown>,
): NotificationCopy {
  switch (kind) {
    case "bookingConfirmed":
      return {
        title: "Session booked",
        body: "Your Quran session is confirmed.",
        actionType: "quran_session_booking_confirmed",
      };
    case "cancellation":
      return {
        title: "Session cancelled",
        body:
          typeof payload.reason === "string" && payload.reason.length > 0
            ? `Session cancelled: ${payload.reason}`
            : "A Quran session was cancelled.",
        actionType: "quran_session_cancelled",
      };
    case "rescheduleRequested":
      return {
        title: "Reschedule requested",
        body: "A reschedule request needs your response.",
        actionType: "quran_session_reschedule_requested",
      };
    case "rescheduleConfirmed":
      return {
        title: "Reschedule confirmed",
        body: "Your session has a new time.",
        actionType: "quran_session_reschedule_confirmed",
      };
    case "noShowMarked":
      return {
        title: "No-show recorded",
        body: "A no-show was recorded for your session.",
        actionType: "quran_session_no_show",
      };
    case "compensationIssued":
      return {
        title: "Compensation issued",
        body: "Compensation was applied to your session.",
        actionType: "quran_session_compensation",
      };
    case "reminder": {
      const hours =
        typeof payload.hoursBefore === "number" ? payload.hoursBefore : 24;
      return {
        title: "Session reminder",
        body: `Your Quran session starts in ${hours} hour${hours === 1 ? "" : "s"}.`,
        actionType: "quran_session_reminder",
      };
    }
  }
}

export async function enqueueSessionNotification(
  db: FirebaseFirestore.Firestore,
  input: EnqueueSessionNotificationInput,
): Promise<string> {
  const ref = db.collection("quran_session_notifications").doc();
  await ref.set(buildSessionNotificationDoc(ref.id, input));
  return ref.id;
}

export function enqueueSessionNotificationInBatch(
  batch: WriteBatch,
  db: FirebaseFirestore.Firestore,
  input: EnqueueSessionNotificationInput,
): string {
  const ref = db.collection("quran_session_notifications").doc();
  batch.set(ref, buildSessionNotificationDoc(ref.id, input));
  return ref.id;
}

export const MAX_NOTIFICATION_RETRIES = 3;

export function computeRetryBackoffMs(retryCount: number): number {
  const baseMs = 60_000;
  return baseMs * 2 ** Math.max(retryCount - 1, 0);
}

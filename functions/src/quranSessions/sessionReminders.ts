import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { enqueueSessionNotification } from "./notificationOutboxService";
import { resolveTeacherProfileUserId } from "./teacherProfileUserId";
import { processDueNotificationRetries } from "./deliverSessionNotification";

export const DEFAULT_REMINDER_HOURS = [24, 1];
export const REMINDER_WINDOW_MINUTES = 30;

export interface ReminderWindow {
  hoursBefore: number;
  windowStart: Date;
  windowEnd: Date;
}

export function computeReminderWindow(
  hoursBefore: number,
  now: Date,
  windowMinutes: number = REMINDER_WINDOW_MINUTES,
): ReminderWindow {
  const targetMs = now.getTime() + hoursBefore * 60 * 60 * 1000;
  const halfWindowMs = windowMinutes * 60 * 1000;
  return {
    hoursBefore,
    windowStart: new Date(targetMs - halfWindowMs),
    windowEnd: new Date(targetMs + halfWindowMs),
  };
}

export function reminderFieldKey(hoursBefore: number): string {
  return `reminder${hoursBefore}hEnqueued`;
}

export async function enqueueDueSessionReminders(
  db: FirebaseFirestore.Firestore,
  now: Date = new Date(),
  reminderHours: number[] = DEFAULT_REMINDER_HOURS,
): Promise<number> {
  let enqueued = 0;

  for (const hoursBefore of reminderHours) {
    const window = computeReminderWindow(hoursBefore, now);
    const sessions = await db
      .collection("quran_sessions")
      .where("lifecycleStatus", "in", ["scheduled", "confirmed"])
      .where(
        "startsAt",
        ">=",
        Timestamp.fromDate(window.windowStart),
      )
      .where("startsAt", "<=", Timestamp.fromDate(window.windowEnd))
      .get();

    for (const doc of sessions.docs) {
      const data = doc.data();
      const fieldKey = reminderFieldKey(hoursBefore);
      if (data[fieldKey] === true) {
        continue;
      }

      const teacherId = data.teacherId as string | undefined;
      const studentId = data.studentId as string | undefined;
      if (!teacherId || !studentId) {
        continue;
      }

      const aggregateId =
        (data.aggregateId as string | undefined) ??
        (data.bookingId as string | undefined) ??
        doc.id;

      await enqueueSessionNotification(db, {
        sessionId: doc.id,
        aggregateId,
        kind: "reminder",
        recipientUserIds: [
          await resolveTeacherProfileUserId(db, teacherId),
          studentId,
        ],
        payload: { hoursBefore },
      });

      await doc.ref.set({ [fieldKey]: true }, { merge: true });
      enqueued += 1;
    }
  }

  return enqueued;
}

export const sessionReminders = onSchedule("every 1 hours", async () => {
  const db = getFirestore();
  await enqueueDueSessionReminders(db);
  await processDueNotificationRetries(db);
});

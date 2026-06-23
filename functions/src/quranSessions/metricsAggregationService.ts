import { FieldValue, Firestore, Timestamp } from "firebase-admin/firestore";
import { LifecycleStatus } from "./sessionLifecycleService";

export type TerminalTransition =
  | {
      type: "booking_confirmed";
      teacherId: string;
      studentId: string;
    }
  | {
      type: "completed";
      teacherId: string;
      studentId: string;
    }
  | {
      type: "cancelled_by_teacher";
      teacherId: string;
    }
  | {
      type: "cancelled_by_student";
      studentId: string;
    }
  | {
      type: "teacher_no_show";
      teacherId: string;
    }
  | {
      type: "student_no_show";
      studentId: string;
    }
  | {
      type: "both_no_show";
      teacherId: string;
      studentId: string;
    };

export function terminalTransitionForLifecycleStatus(
  lifecycleStatus: LifecycleStatus,
  teacherId: string,
  studentId: string,
): TerminalTransition | null {
  switch (lifecycleStatus) {
    case "scheduled":
    case "confirmed":
      return { type: "booking_confirmed", teacherId, studentId };
    case "completed":
      return { type: "completed", teacherId, studentId };
    case "cancelled_by_teacher":
      return { type: "cancelled_by_teacher", teacherId };
    case "cancelled_by_student":
      return { type: "cancelled_by_student", studentId };
    case "teacher_no_show":
      return { type: "teacher_no_show", teacherId };
    case "student_no_show":
      return { type: "student_no_show", studentId };
    case "both_no_show":
      return { type: "both_no_show", teacherId, studentId };
    default:
      return null;
  }
}

export function computeCancellationRate90d(
  cancellationCount: number,
  confirmedCount: number,
): number {
  if (confirmedCount <= 0) {
    return 0;
  }
  return Number((cancellationCount / confirmedCount).toFixed(4));
}

export async function recordTerminalTransition(
  db: Firestore,
  transition: TerminalTransition,
  now: Timestamp = Timestamp.now(),
): Promise<void> {
  switch (transition.type) {
    case "booking_confirmed":
      await incrementTeacherMetrics(db, transition.teacherId, {
        confirmedSessionCount: 1,
      }, now);
      await incrementStudentMetrics(db, transition.studentId, {
        bookedSessionCount: 1,
      }, now);
      break;
    case "completed":
      await incrementTeacherMetrics(db, transition.teacherId, {
        completedSessionCount: 1,
      }, now);
      break;
    case "cancelled_by_teacher":
      await incrementTeacherMetrics(db, transition.teacherId, {
        teacherCancellationCount: 1,
        lastCancellationAt: now,
      }, now);
      await recalculateTeacherCancellationRate(db, transition.teacherId);
      break;
    case "cancelled_by_student":
      await incrementStudentMetrics(db, transition.studentId, {
        studentCancellationCount: 1,
      }, now);
      break;
    case "teacher_no_show":
      await incrementTeacherMetrics(db, transition.teacherId, {
        teacherNoShowCount: 1,
      }, now);
      break;
    case "student_no_show":
      await incrementStudentMetrics(db, transition.studentId, {
        studentNoShowCount: 1,
        lastNoShowAt: now,
      }, now);
      break;
    case "both_no_show":
      await incrementTeacherMetrics(db, transition.teacherId, {
        teacherNoShowCount: 1,
      }, now);
      await incrementStudentMetrics(db, transition.studentId, {
        studentNoShowCount: 1,
        lastNoShowAt: now,
      }, now);
      break;
  }
}

async function incrementTeacherMetrics(
  db: Firestore,
  teacherId: string,
  fields: Record<string, FieldValue | Timestamp | number>,
  now: Timestamp,
): Promise<void> {
  const increments: Record<string, FieldValue | Timestamp> = {
    updatedAt: now,
  };
  for (const [key, value] of Object.entries(fields)) {
    if (typeof value === "number") {
      increments[key] = FieldValue.increment(value);
    } else {
      increments[key] = value;
    }
  }
  await db.collection("quran_teacher_metrics").doc(teacherId).set(
    { teacherId, ...increments },
    { merge: true },
  );
}

async function incrementStudentMetrics(
  db: Firestore,
  studentId: string,
  fields: Record<string, FieldValue | Timestamp | number>,
  now: Timestamp,
): Promise<void> {
  const increments: Record<string, FieldValue | Timestamp> = {
    updatedAt: now,
  };
  for (const [key, value] of Object.entries(fields)) {
    if (typeof value === "number") {
      increments[key] = FieldValue.increment(value);
    } else {
      increments[key] = value;
    }
  }
  await db.collection("quran_student_metrics").doc(studentId).set(
    { studentId, ...increments },
    { merge: true },
  );
}

async function recalculateTeacherCancellationRate(
  db: Firestore,
  teacherId: string,
): Promise<void> {
  const snap = await db.collection("quran_teacher_metrics").doc(teacherId).get();
  const data = snap.data() ?? {};
  const cancellationCount = (data.teacherCancellationCount as number | undefined) ?? 0;
  const confirmedCount = (data.confirmedSessionCount as number | undefined) ?? 0;
  await db.collection("quran_teacher_metrics").doc(teacherId).set(
    {
      cancellationRate90d: computeCancellationRate90d(
        cancellationCount,
        confirmedCount,
      ),
      updatedAt: Timestamp.now(),
    },
    { merge: true },
  );
}

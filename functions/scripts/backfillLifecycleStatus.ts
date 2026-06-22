import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

initializeApp();

function bookingLegacyToLifecycle(status: string | undefined): string {
  switch (status) {
    case "confirmed":
      return "scheduled";
    case "cancelled":
      return "cancelled_by_student";
    case "completed":
      return "completed";
    case "refunded":
      return "refunded";
    case "rejected":
      return "expired";
    default:
      return "pending_payment";
  }
}

function sessionLegacyToLifecycle(status: string | undefined): string {
  switch (status) {
    case "inProgress":
      return "in_progress";
    case "completed":
      return "completed";
    case "cancelledByStudent":
    case "cancelled_by_student":
      return "cancelled_by_student";
    case "cancelledByTeacher":
    case "cancelled_by_teacher":
      return "cancelled_by_teacher";
    case "noShow":
    case "no_show":
      return "both_no_show";
    default:
      return "scheduled";
  }
}

async function run() {
  const db = getFirestore();
  const bookings = await db.collection("quran_bookings").get();
  const sessions = await db.collection("quran_sessions").get();

  let updatedBookings = 0;
  let updatedSessions = 0;
  const batch = db.batch();

  for (const doc of bookings.docs) {
    const data = doc.data();
    if (data.lifecycleStatus) continue;
    updatedBookings += 1;
    batch.set(
      doc.ref,
      {
        lifecycleStatus: bookingLegacyToLifecycle(data.status as string | undefined),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }

  for (const doc of sessions.docs) {
    const data = doc.data();
    if (data.lifecycleStatus) continue;
    updatedSessions += 1;
    batch.set(
      doc.ref,
      {
        lifecycleStatus: sessionLegacyToLifecycle(data.status as string | undefined),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }

  if (updatedBookings > 0 || updatedSessions > 0) {
    await batch.commit();
  }
  // eslint-disable-next-line no-console
  console.log(
    `backfill complete: bookings=${updatedBookings}, sessions=${updatedSessions}`,
  );
}

run().catch((error) => {
  // eslint-disable-next-line no-console
  console.error("backfill failed", error);
  process.exit(1);
});

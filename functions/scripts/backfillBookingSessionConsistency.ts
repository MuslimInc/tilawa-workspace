/**
 * Backfill script: align quran_sessions.lifecycleStatus with quran_bookings.
 *
 * Usage:
 *   npx ts-node --project tsconfig.scripts.json scripts/backfillBookingSessionConsistency.ts --dry-run
 *   npx ts-node --project tsconfig.scripts.json scripts/backfillBookingSessionConsistency.ts --apply
 */
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

const PROJECT_ID = process.env.FIREBASE_PROJECT_ID ?? "quran-playera-app";
initializeApp({ projectId: PROJECT_ID });

const dryRun = !process.argv.includes("--apply");

async function main(): Promise<void> {
  const db = getFirestore();
  const bookings = await db.collection("quran_bookings").get();
  let fixed = 0;

  for (const bookingDoc of bookings.docs) {
    const booking = bookingDoc.data();
    const sessionId = booking.sessionId as string | undefined;
    const bookingStatus = booking.lifecycleStatus as string | undefined;
    if (!sessionId || !bookingStatus) {
      continue;
    }

    const sessionRef = db.collection("quran_sessions").doc(sessionId);
    const sessionSnap = await sessionRef.get();
    if (!sessionSnap.exists) {
      continue;
    }

    const sessionStatus = sessionSnap.data()?.lifecycleStatus as string | undefined;
    if (sessionStatus === bookingStatus) {
      continue;
    }

    console.log(
      `Mismatch booking=${bookingDoc.id} bookingStatus=${bookingStatus} sessionStatus=${sessionStatus}`,
    );

    if (!dryRun) {
      await sessionRef.set(
        { lifecycleStatus: bookingStatus, updatedAt: new Date() },
        { merge: true },
      );
      await db.collection("quran_session_events").add({
        aggregateId: booking.aggregateId ?? bookingDoc.id,
        bookingId: bookingDoc.id,
        sessionId,
        actorId: "system",
        actorRole: "system",
        action: "backfill_session_lifecycle_sync",
        previousStatus: sessionStatus ?? null,
        newStatus: bookingStatus,
        source: "backendJob",
        timestamp: new Date(),
      });
    }
    fixed += 1;
  }

  console.log(
    dryRun
      ? `Dry run complete. ${fixed} session(s) would be updated.`
      : `Backfill complete. ${fixed} session(s) updated.`,
  );
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

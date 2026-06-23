/**
 * Lists pending teacher applications (MVO admin ops).
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=... npm run admin:list-pending-applications
 */
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

initializeApp();

async function main(): Promise<void> {
  const db = getFirestore();
  const snapshot = await db
    .collection("quran_teacher_applications")
    .where("status", "==", "pending")
    .orderBy("submittedAt", "desc")
    .get();

  if (snapshot.empty) {
    console.log("No pending teacher applications.");
    return;
  }

  for (const doc of snapshot.docs) {
    const data = doc.data();
    console.log(
      JSON.stringify({
        id: doc.id,
        userId: data.userId,
        submittedAt: data.submittedAt?.toDate?.()?.toISOString?.() ?? null,
        teachingLanguages: data.teachingLanguages,
        specializations: data.specializations,
      }),
    );
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

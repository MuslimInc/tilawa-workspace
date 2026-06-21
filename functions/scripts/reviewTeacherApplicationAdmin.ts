/**
 * Reviews a teacher application via the reviewTeacherApplication callable logic
 * using Admin SDK directly (MVO ops without in-app admin UI).
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=... npm run admin:review-teacher-application -- \
 *     --applicationId=APP_ID --action=approve
 *
 * Actions: approve | reject | suspend | revoke
 */
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import {
  buildApprovedTeacherProfile,
} from "../src/quranSessions/teacherProfileApproval";

initializeApp();

type ReviewAction = "approve" | "reject" | "suspend" | "revoke";

function parseArgs(): { applicationId: string; action: ReviewAction; reason?: string } {
  const args = process.argv.slice(2);
  let applicationId = "";
  let action: ReviewAction = "approve";
  let reason: string | undefined;

  for (const arg of args) {
    if (arg.startsWith("--applicationId=")) {
      applicationId = arg.split("=")[1] ?? "";
    } else if (arg.startsWith("--action=")) {
      action = arg.split("=")[1] as ReviewAction;
    } else if (arg.startsWith("--reason=")) {
      reason = arg.split("=").slice(1).join("=");
    }
  }

  if (!applicationId) {
    throw new Error("--applicationId is required");
  }

  return { applicationId, action, reason };
}

async function main(): Promise<void> {
  const { applicationId, action, reason } = parseArgs();
  const db = getFirestore();
  const appRef = db.collection("quran_teacher_applications").doc(applicationId);
  const appSnap = await appRef.get();

  if (!appSnap.exists) {
    throw new Error(`Application not found: ${applicationId}`);
  }

  const app = appSnap.data()!;
  const now = FieldValue.serverTimestamp();
  const nextStatus =
    action === "approve"
      ? "approved"
      : action === "reject"
        ? "rejected"
        : action === "suspend"
          ? "suspended"
          : "revoked";

  await appRef.set(
    {
      status: nextStatus,
      reviewedAt: now,
      reviewedBy: "admin-script",
      rejectionReason: reason ?? null,
      updatedAt: now,
    },
    { merge: true },
  );

  if (action === "approve") {
    const userSnap = await db.collection("users").doc(app.userId).get();
    const userData = userSnap.data() ?? {};
    await db.collection("quran_teacher_profiles").doc(applicationId).set(
      buildApprovedTeacherProfile({ app, user: userData, now }),
      { merge: true },
    );
  }

  if (action === "suspend" || action === "revoke") {
    await db
      .collection("quran_teacher_profiles")
      .doc(applicationId)
      .set(
        { isActive: false, isPubliclyVisible: false, updatedAt: now },
        { merge: true },
      );
  }

  console.log(`Application ${applicationId} → ${nextStatus}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

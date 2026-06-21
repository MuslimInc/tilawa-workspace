import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { buildApprovedTeacherProfile } from "./quranSessions/teacherProfileApproval";

type ReviewAction = "approve" | "reject" | "suspend" | "revoke";

interface ReviewTeacherApplicationRequest {
  applicationId: string;
  action: ReviewAction;
  reason?: string;
}

/**
 * Admin-only moderation for teacher applications.
 *
 * On approve: sets application status and creates `quran_teacher_profiles/{id}`.
 * Requires custom claim `{ admin: true }` on the caller's ID token.
 */
export const reviewTeacherApplication = onCall(
  { enforceAppCheck: false },
  async (request) => {
    if (!request.auth?.token.admin) {
      throw new HttpsError("permission-denied", "Admin access required.");
    }

    const data = request.data as ReviewTeacherApplicationRequest;
    const applicationId = data.applicationId?.trim();
    const action = data.action;

    if (!applicationId || !action) {
      throw new HttpsError("invalid-argument", "applicationId and action required.");
    }

    const db = getFirestore();
    const appRef = db.collection("quran_teacher_applications").doc(applicationId);
    const appSnap = await appRef.get();

    if (!appSnap.exists) {
      throw new HttpsError("not-found", "Application not found.");
    }

    const app = appSnap.data()!;
    const reviewedBy = request.auth.uid;
    const now = FieldValue.serverTimestamp();

    const nextStatus = action === "approve"
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
        reviewedBy,
        rejectionReason: data.reason ?? null,
        updatedAt: now,
      },
      { merge: true },
    );

    if (action === "approve") {
      const userSnap = await db.collection("users").doc(app.userId).get();
      const userData = userSnap.data() ?? {};
      const profileRef = db.collection("quran_teacher_profiles").doc(applicationId);
      await profileRef.set(
        buildApprovedTeacherProfile({ app, user: userData, now }),
        { merge: true },
      );
    }

    if (action === "suspend" || action === "revoke") {
      const profileRef = db.collection("quran_teacher_profiles").doc(applicationId);
      await profileRef.set(
        {
          isActive: false,
          isPubliclyVisible: false,
          updatedAt: now,
        },
        { merge: true },
      );
    }

    return { applicationId, status: nextStatus };
  },
);

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { recomputeVisibilityFields } from "./quranSessions/teacherProfileApproval";

type ProfileAction = "activate" | "deactivate";

interface ModerateTeacherProfileRequest {
  teacherId: string;
  action: ProfileAction;
  reason?: string;
}

/**
 * Admin-only activation toggle for teacher profiles.
 * Requires custom claim `{ admin: true }`.
 */
export const moderateTeacherProfile = onCall(
  { enforceAppCheck: false },
  async (request) => {
    if (!request.auth?.token.admin) {
      throw new HttpsError("permission-denied", "Admin access required.");
    }

    const data = request.data as ModerateTeacherProfileRequest;
    const teacherId = data.teacherId?.trim();
    const action = data.action;

    if (!teacherId || !action) {
      throw new HttpsError("invalid-argument", "teacherId and action required.");
    }

    const db = getFirestore();
    const profileRef = db.collection("quran_teacher_profiles").doc(teacherId);
    const profileSnap = await profileRef.get();

    if (!profileSnap.exists) {
      throw new HttpsError("not-found", "Teacher profile not found.");
    }

    const profileData = profileSnap.data() ?? {};
    const isActive = action === "activate";
    const now = FieldValue.serverTimestamp();
    const visibility = recomputeVisibilityFields({
      ...profileData,
      isActive,
    });

    await profileRef.set(
      {
        isActive,
        isPubliclyVisible: visibility.isPubliclyVisible,
        updatedAt: now,
        ...(data.reason ? { moderationNote: data.reason } : {}),
      },
      { merge: true },
    );

    return { teacherId, isActive, isPubliclyVisible: visibility.isPubliclyVisible };
  },
);

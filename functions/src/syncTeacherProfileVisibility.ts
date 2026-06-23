import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { FieldValue } from "firebase-admin/firestore";
import {
  computeIsPubliclyVisible,
  computeProfileCompleteness,
} from "./quranSessions/teacherProfileApproval";

/**
 * Recomputes server-owned visibility fields when a teacher edits public profile
 * fields. Client rules freeze `profileCompleteness` / `isPubliclyVisible`.
 */
export const syncTeacherProfileVisibility = onDocumentWritten(
  "quran_teacher_profiles/{teacherId}",
  async (event) => {
    const after = event.data?.after;
    if (!after?.exists) {
      return;
    }

    const data = after.data() ?? {};
    const displayName = typeof data.displayName === "string" ? data.displayName : "";
    const publicBio = typeof data.publicBio === "string" ? data.publicBio : "";
    const teachingLanguages = Array.isArray(data.teachingLanguages)
      ? data.teachingLanguages.filter((value): value is string => typeof value === "string")
      : [];
    const specializations = Array.isArray(data.specializations)
      ? data.specializations.filter((value): value is string => typeof value === "string")
      : [];
    const verificationStatus =
      typeof data.verificationStatus === "string" ? data.verificationStatus : "pending";
    const isActive = data.isActive === true;

    const profileCompleteness = computeProfileCompleteness({
      displayName,
      publicBio,
      teachingLanguages,
      specializations,
    });
    const isPubliclyVisible = computeIsPubliclyVisible({
      profileCompleteness,
      verificationStatus,
      isActive,
    });

    if (
      data.profileCompleteness === profileCompleteness
      && data.isPubliclyVisible === isPubliclyVisible
    ) {
      return;
    }

    await after.ref.set(
      {
        profileCompleteness,
        isPubliclyVisible,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  },
);

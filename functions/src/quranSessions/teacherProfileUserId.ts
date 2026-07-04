import type { Firestore } from "firebase-admin/firestore";

/**
 * Resolves the Firebase Auth uid for a teacher profile document id.
 * Legacy profiles may use the auth uid as the profile doc id.
 */
export function teacherProfileUserIdFromData(
  teacherProfileId: string,
  profileData: FirebaseFirestore.DocumentData | undefined,
): string {
  const userId = profileData?.userId;
  if (typeof userId === "string" && userId.trim().length > 0) {
    return userId;
  }
  return teacherProfileId;
}

export async function resolveTeacherProfileUserId(
  db: Firestore,
  teacherProfileId: string,
): Promise<string> {
  const snap = await db
    .collection("quran_teacher_profiles")
    .doc(teacherProfileId)
    .get();
  return teacherProfileUserIdFromData(teacherProfileId, snap.data());
}

/**
 * Reads denormalized teacher auth uid from session/booking docs (P2 perf).
 * Returns undefined when legacy rows omit the field.
 */
export function teacherUserIdFromDenormalizedSessionData(
  data: FirebaseFirestore.DocumentData,
): string | undefined {
  const direct = data.teacherUserId;
  if (typeof direct === "string" && direct.trim().length > 0) {
    return direct.trim();
  }
  return undefined;
}

/**
 * Resolves teacher auth uid for session authorization.
 *
 * Legacy rows may denormalize `teacherUserId` to the profile doc id when the
 * profile lacked `userId` at booking time — those values are ignored so the
 * live profile remains authoritative.
 */
export function teacherUserIdForSessionAuth(
  data: FirebaseFirestore.DocumentData,
  profileResolvedUserId: string,
): string {
  const teacherProfileId = (data.teacherId as string) ?? "";
  const denormalized = teacherUserIdFromDenormalizedSessionData(data);
  if (denormalized != null && denormalized !== teacherProfileId) {
    return denormalized;
  }
  return profileResolvedUserId;
}

export async function resolveTeacherUserIdForSessionAuth(
  db: Firestore,
  data: FirebaseFirestore.DocumentData,
): Promise<string> {
  const teacherProfileId = (data.teacherId as string) ?? "";
  const profileResolvedUserId = await resolveTeacherProfileUserId(
    db,
    teacherProfileId,
  );
  return teacherUserIdForSessionAuth(data, profileResolvedUserId);
}

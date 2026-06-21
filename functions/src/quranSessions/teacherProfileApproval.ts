import { FieldValue } from "firebase-admin/firestore";

export const TEACHER_DISPLAY_NAME_PLACEHOLDERS = [
  "Quran Teacher",
  "محفظ قرآن",
] as const;

export type ProfileCompleteness = "complete" | "incomplete";

export interface TeacherApplicationData {
  userId?: string;
  publicDisplayName?: unknown;
  teacherDisplayName?: unknown;
  displayName?: unknown;
  bio?: unknown;
  teachingLanguages?: unknown;
  specializations?: unknown;
}

export interface UserProfileData {
  displayName?: unknown;
}

function trimString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function isPlaceholderDisplayName(name: string): boolean {
  return TEACHER_DISPLAY_NAME_PLACEHOLDERS.includes(
    name as (typeof TEACHER_DISPLAY_NAME_PLACEHOLDERS)[number],
  );
}

function isValidDisplayName(name: string): boolean {
  return name.length > 0 && !isPlaceholderDisplayName(name);
}

function applicationHasDisplayNameField(app: TeacherApplicationData): boolean {
  return (
    trimString(app.publicDisplayName).length > 0
    || trimString(app.teacherDisplayName).length > 0
    || trimString(app.displayName).length > 0
  );
}

/**
 * Resolves TeacherProfile.displayName on approve.
 *
 * Priority:
 * 1. application.publicDisplayName / teacherDisplayName / legacy displayName
 * 2. users/{userId}.displayName only when application has no display-name field
 *
 * Never uses bio. Never returns placeholder marketplace names.
 */
export function resolveTeacherProfileDisplayName(
  app: TeacherApplicationData,
  user: UserProfileData,
): string {
  for (const candidate of [
    app.publicDisplayName,
    app.teacherDisplayName,
    app.displayName,
  ]) {
    const trimmed = trimString(candidate);
    if (isValidDisplayName(trimmed)) {
      return trimmed;
    }
  }

  if (!applicationHasDisplayNameField(app)) {
    const userDisplayName = trimString(user.displayName);
    if (isValidDisplayName(userDisplayName)) {
      return userDisplayName;
    }
  }

  return "";
}

export function computeProfileCompleteness(profile: {
  displayName: string;
  publicBio: string;
  teachingLanguages: string[];
  specializations: string[];
}): ProfileCompleteness {
  const displayName = profile.displayName.trim();
  const publicBio = profile.publicBio.trim();

  if (!isValidDisplayName(displayName)) {
    return "incomplete";
  }
  if (publicBio.length === 0) {
    return "incomplete";
  }
  if (profile.teachingLanguages.length === 0) {
    return "incomplete";
  }
  if (profile.specializations.length === 0) {
    return "incomplete";
  }

  return "complete";
}

export function computeIsPubliclyVisible(profile: {
  profileCompleteness: ProfileCompleteness;
  verificationStatus: string;
  isActive: boolean;
}): boolean {
  return (
    profile.profileCompleteness === "complete"
    && profile.verificationStatus === "verified"
    && profile.isActive
  );
}

export function buildApprovedTeacherProfile(params: {
  app: TeacherApplicationData;
  user: UserProfileData;
  now: FieldValue;
}): Record<string, unknown> {
  const { app, user, now } = params;
  const displayName = resolveTeacherProfileDisplayName(app, user);
  const publicBio = trimString(app.bio);
  const teachingLanguages = Array.isArray(app.teachingLanguages)
    ? app.teachingLanguages.filter((value): value is string => typeof value === "string")
    : [];
  const specializations = Array.isArray(app.specializations)
    ? app.specializations.filter((value): value is string => typeof value === "string")
    : [];

  const profileCompleteness = computeProfileCompleteness({
    displayName,
    publicBio,
    teachingLanguages,
    specializations,
  });
  const verificationStatus = "verified";
  const isActive = true;
  const isPubliclyVisible = computeIsPubliclyVisible({
    profileCompleteness,
    verificationStatus,
    isActive,
  });

  return {
    userId: app.userId,
    displayName,
    publicBio,
    teachingLanguages,
    specializations,
    verificationStatus,
    teacherStatus: "approved",
    profileCompleteness,
    isPubliclyVisible,
    isActive,
    averageRating: 0,
    reviewCount: 0,
    totalSessionsCompleted: 0,
    createdAt: now,
    updatedAt: now,
  };
}

export function recomputeVisibilityFields(profile: {
  profileCompleteness?: unknown;
  verificationStatus?: unknown;
  isActive?: unknown;
}): { isPubliclyVisible: boolean } {
  const profileCompleteness =
    profile.profileCompleteness === "complete" ? "complete" : "incomplete";
  const verificationStatus =
    typeof profile.verificationStatus === "string"
      ? profile.verificationStatus
      : "pending";
  const isActive = profile.isActive === true;

  return {
    isPubliclyVisible: computeIsPubliclyVisible({
      profileCompleteness,
      verificationStatus,
      isActive,
    }),
  };
}

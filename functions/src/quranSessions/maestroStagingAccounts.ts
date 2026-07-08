import type { UserRecord } from "firebase-admin/auth";
import { FieldValue } from "firebase-admin/firestore";

import { FIREBASE_PROJECT_ID } from "../github";
import {
  computeIsPubliclyVisible,
  computeProfileCompleteness,
} from "./teacherProfileApproval";

/** Staging Firebase project from `.firebaserc` — scripts must not run elsewhere. */
export const MAESTRO_STAGING_PROJECT_ID = FIREBASE_PROJECT_ID;

/** Known production project ids — hard fail if targeted by mistake. */
export const MAESTRO_BLOCKED_PRODUCTION_PROJECT_IDS = [
  "tilawa-production",
  "tilawa-prod",
  "quran-player-prod",
  "quran-playera-prod",
] as const;

export const MAESTRO_TEACHER_EMAIL = "mu7ammadkamel@hotmail.com";
export const MAESTRO_STUDENT_EMAIL = "mohammad.kamel@othaimmarkets.com";

/** Auth uids for staging Maestro QA accounts (Google sign-in). */
export const MAESTRO_TEACHER_UID = "WV0m6tenTJPDLZE4EdWXBzjADF12";
export const MAESTRO_STUDENT_UID = "U33e4w08bYWFOuS7NTxoHmvDFxM2";

export const MAESTRO_TEACHER_PASSWORD_ENV = "MAESTRO_QURAN_TEACHER_PASSWORD";
export const MAESTRO_STUDENT_PASSWORD_ENV = "MAESTRO_QURAN_STUDENT_PASSWORD";

export interface MaestroAccountSpec {
  role: "teacher" | "student";
  email: string;
  passwordEnvVar: string;
}

export const MAESTRO_ACCOUNT_SPECS: readonly MaestroAccountSpec[] = [
  {
    role: "teacher",
    email: MAESTRO_TEACHER_EMAIL,
    passwordEnvVar: MAESTRO_TEACHER_PASSWORD_ENV,
  },
  {
    role: "student",
    email: MAESTRO_STUDENT_EMAIL,
    passwordEnvVar: MAESTRO_STUDENT_PASSWORD_ENV,
  },
];

export interface UserEmailRecord {
  id: string;
  email?: string | null;
}

export interface AuthAccountSummary {
  uid: string;
  email: string | undefined;
  providers: string[];
  emailVerified: boolean;
  displayName: string | undefined;
}

export interface PasswordLinkAssessment {
  canLinkPasswordToSameUid: boolean;
  reason: string;
  hasGoogleProvider: boolean;
  hasPasswordProvider: boolean;
}

export interface VerifyAccountResult {
  role: MaestroAccountSpec["role"];
  email: string;
  summary: AuthAccountSummary | null;
  passwordLink: PasswordLinkAssessment | null;
  firestoreUserDocIds: string[];
  errors: string[];
  pass: boolean;
}

export interface GeneratedAvailabilitySlot {
  slotId: string;
  startsAt: Date;
  endsAt: Date;
}

const WEEKDAY_KEYS = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"] as const;

export function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

export function resolveMaestroProjectId(): string {
  return process.env.FIREBASE_PROJECT_ID?.trim() || MAESTRO_STAGING_PROJECT_ID;
}

export function assertMaestroStagingProject(projectId: string): void {
  if (
    (MAESTRO_BLOCKED_PRODUCTION_PROJECT_IDS as readonly string[]).includes(
      projectId,
    )
  ) {
    throw new Error(
      `Refusing to run Maestro staging scripts against production project "${projectId}".`,
    );
  }

  if (projectId !== MAESTRO_STAGING_PROJECT_ID) {
    throw new Error(
      `Refusing to run: expected staging project "${MAESTRO_STAGING_PROJECT_ID}", got "${projectId}".`,
    );
  }
}

export function summarizeAuthUser(user: UserRecord): AuthAccountSummary {
  return {
    uid: user.uid,
    email: user.email,
    providers: user.providerData.map((provider) => provider.providerId),
    emailVerified: user.emailVerified,
    displayName: user.displayName,
  };
}

/**
 * Firebase Admin `updateUser({ password })` on an existing uid adds the
 * password provider without creating a new Auth user.
 */
export function assessPasswordLinking(user: UserRecord): PasswordLinkAssessment {
  const providers = user.providerData.map((provider) => provider.providerId);
  const hasGoogleProvider = providers.includes("google.com");
  const hasPasswordProvider = providers.includes("password");

  if (hasPasswordProvider) {
    return {
      canLinkPasswordToSameUid: true,
      reason: "password provider already linked — updateUser(password) refreshes credential on same uid",
      hasGoogleProvider,
      hasPasswordProvider,
    };
  }

  if (hasGoogleProvider) {
    return {
      canLinkPasswordToSameUid: true,
      reason: "google.com account — updateUser(password) links password to same uid",
      hasGoogleProvider,
      hasPasswordProvider,
    };
  }

  if (providers.length === 0) {
    return {
      canLinkPasswordToSameUid: true,
      reason: "no linked providers — updateUser(password) attaches password to existing uid",
      hasGoogleProvider,
      hasPasswordProvider,
    };
  }

  return {
    canLinkPasswordToSameUid: true,
    reason: `existing providers [${providers.join(", ")}] — updateUser(password) adds password on same uid`,
    hasGoogleProvider,
    hasPasswordProvider,
  };
}

export function findFirestoreUsersByEmail(
  users: readonly UserEmailRecord[],
  email: string,
): string[] {
  const normalized = normalizeEmail(email);
  return users
    .filter((user) => normalizeEmail(user.email ?? "") === normalized)
    .map((user) => user.id)
    .sort();
}

export function wouldCreateDuplicateUser(params: {
  authUid: string | null;
  firestoreUserIds: readonly string[];
}): boolean {
  if (params.authUid == null) {
    return false;
  }

  return params.firestoreUserIds.some((id) => id !== params.authUid);
}

export function buildVerifyAccountResult(params: {
  spec: MaestroAccountSpec;
  authUser: UserRecord | null;
  firestoreUserIds: readonly string[];
}): VerifyAccountResult {
  const errors: string[] = [];

  if (!params.authUser) {
    errors.push("Auth user missing — account must exist before Maestro seed");
    return {
      role: params.spec.role,
      email: params.spec.email,
      summary: null,
      passwordLink: null,
      firestoreUserDocIds: [...params.firestoreUserIds],
      errors,
      pass: false,
    };
  }

  const summary = summarizeAuthUser(params.authUser);
  const passwordLink = assessPasswordLinking(params.authUser);

  if (!passwordLink.canLinkPasswordToSameUid) {
    errors.push(`Cannot link password on same uid: ${passwordLink.reason}`);
  }

  if (
    params.firestoreUserIds.length > 0
    && wouldCreateDuplicateUser({
      authUid: summary.uid,
      firestoreUserIds: params.firestoreUserIds,
    })
  ) {
    errors.push(
      `Duplicate Firestore profiles for email: ${params.firestoreUserIds.join(", ")} (auth uid=${summary.uid})`,
    );
  } else if (
    params.firestoreUserIds.length === 1
    && params.firestoreUserIds[0] !== summary.uid
  ) {
    errors.push(
      `Firestore users doc id ${params.firestoreUserIds[0]} does not match auth uid ${summary.uid}`,
    );
  }

  return {
    role: params.spec.role,
    email: params.spec.email,
    summary,
    passwordLink,
    firestoreUserDocIds: [...params.firestoreUserIds],
    errors,
    pass: errors.length === 0,
  };
}

export function formatAuthAccountReport(result: VerifyAccountResult): string {
  const lines = [
    `=== ${result.role.toUpperCase()} — ${result.email} ===`,
    result.pass ? "PASS" : "FAIL",
  ];

  if (result.summary) {
    lines.push(`uid: ${result.summary.uid}`);
    lines.push(`providers: ${result.summary.providers.join(", ") || "(none)"}`);
    lines.push(`emailVerified: ${String(result.summary.emailVerified)}`);
    lines.push(`displayName: ${result.summary.displayName ?? "(none)"}`);
  } else {
    lines.push("Auth user: (missing)");
  }

  if (result.passwordLink) {
    lines.push(`passwordLink: ${result.passwordLink.reason}`);
  }

  lines.push(
    `firestore users docs: ${result.firestoreUserDocIds.length === 0 ? "(none)" : result.firestoreUserDocIds.join(", ")}`,
  );

  for (const error of result.errors) {
    lines.push(`ERROR: ${error}`);
  }

  return lines.join("\n");
}

export function buildMaestroPlatformConfig(): Record<string, unknown> {
  return {
    quranSessionsEnabled: true,
    studentEntryEnabled: true,
    bookingEnabled: true,
    bookingMode: "requiresTutorApproval",
    sessionMode: "videoOnly",
    enabledCallProviders: ["mock", "agora"],
    childAgeThreshold: 14,
    genderMatchingEnabled: true,
    globalAllowMaleTeacherFemaleStudent: true,
    globalAllowFemaleTeacherMaleStudent: true,
    requireGuardianApprovalForChildren: false,
    enableForAllMarkets: false,
    enabledMarketCodes: ["EG"],
    updatedAt: FieldValue.serverTimestamp(),
  };
}

export function buildMaestroUserDoc(params: {
  uid: string;
  email: string;
  displayName: string | undefined;
  authProvider: string;
  profileCompleted: boolean;
}): Record<string, unknown> {
  return {
    email: params.email,
    displayName: params.displayName ?? params.email.split("@")[0],
    authProvider: params.authProvider,
    profileCompleted: params.profileCompleted,
    updatedAt: FieldValue.serverTimestamp(),
  };
}

export function buildMaestroStudentQuranProfile(nowIso: string): Record<string, unknown> {
  return {
    role: "student",
    accountStatus: "active",
    gender: "male",
    dateOfBirth: "1990-01-01T00:00:00.000Z",
    countryCode: "EG",
    cityId: "cairo",
    profileCompleted: true,
    createdAt: nowIso,
    updatedAt: nowIso,
  };
}

export function buildMaestroTeacherApplication(params: {
  userId: string;
  displayName: string;
  now: FieldValue;
}): Record<string, unknown> {
  return {
    userId: params.userId,
    status: "approved",
    publicDisplayName: params.displayName,
    bio: "محفظ قرآن — حساب Maestro staging للاختبار الآلي.",
    teachingLanguages: ["ar"],
    specializations: ["tajweed"],
    reviewedAt: params.now,
    reviewedBy: "maestro-staging-seed",
    updatedAt: params.now,
  };
}

export function buildMaestroTeacherProfile(params: {
  userId: string;
  displayName: string;
  now: FieldValue;
}): Record<string, unknown> {
  const publicBio = "محفظ قرآن — حساب Maestro staging للاختبار الآلي.";
  const teachingLanguages = ["ar"];
  const specializations = ["tajweed"];
  const profileCompleteness = computeProfileCompleteness({
    displayName: params.displayName,
    publicBio,
    teachingLanguages,
    specializations,
  });
  const verificationStatus = "verified";
  const isActive = true;

  return {
    userId: params.userId,
    displayName: params.displayName,
    verificationStatus,
    profileCompleteness,
    gender: "male",
    allowedStudentGender: "both",
    canTeachChildren: true,
    requiresGuardianApprovalForChildren: false,
    isPubliclyVisible: computeIsPubliclyVisible({
      profileCompleteness,
      verificationStatus,
      isActive,
    }),
    isActive,
    publicBio,
    teachingLanguages,
    specializations,
    averageRating: 0,
    reviewCount: 0,
    countryCode: "EG",
    cityId: "cairo",
    pricingType: "free",
    updatedAt: params.now,
  };
}

export function buildMaestroWeeklySchedule(teacherId: string): Record<string, unknown> {
  return {
    teacherId,
    timezone: "Africa/Cairo",
    slotDurationMinutes: 30,
    minNoticeMinutes: 120,
    maxHorizonDays: 30,
    bufferBeforeMinutes: 0,
    bufferAfterMinutes: 0,
    weeklyRules: {
      sat: [],
      sun: [{ start: "09:00", end: "12:00" }],
      mon: [{ start: "09:00", end: "12:00" }],
      tue: [{ start: "09:00", end: "12:00" }],
      wed: [{ start: "09:00", end: "12:00" }],
      thu: [{ start: "09:00", end: "12:00" }],
      fri: [],
    },
    version: 1,
    updatedAt: FieldValue.serverTimestamp(),
  };
}

function weekdayKey(date: Date): (typeof WEEKDAY_KEYS)[number] {
  return WEEKDAY_KEYS[date.getUTCDay()];
}

function pad2(value: number): string {
  return value.toString().padStart(2, "0");
}

export function buildMaestroAvailabilitySlotId(startsAt: Date): string {
  const y = startsAt.getUTCFullYear();
  const m = pad2(startsAt.getUTCMonth() + 1);
  const d = pad2(startsAt.getUTCDate());
  const h = pad2(startsAt.getUTCHours());
  const min = pad2(startsAt.getUTCMinutes());
  return `maestro_${y}${m}${d}_${h}${min}`;
}

/**
 * Deterministic open slots for the next [minDays, maxDays] window on weekdays
 * matching the Maestro weekly template (09:00–12:00 UTC weekdays).
 */
export function generateMaestroAvailabilitySlots(params: {
  teacherId: string;
  now: Date;
  minDays?: number;
  maxDays?: number;
  slotDurationMinutes?: number;
}): GeneratedAvailabilitySlot[] {
  const minDays = params.minDays ?? 7;
  const maxDays = params.maxDays ?? 14;
  const slotDurationMinutes = params.slotDurationMinutes ?? 30;
  const slots: GeneratedAvailabilitySlot[] = [];

  for (let dayOffset = minDays; dayOffset <= maxDays; dayOffset += 1) {
    const day = new Date(params.now);
    day.setUTCDate(day.getUTCDate() + dayOffset);
    day.setUTCHours(0, 0, 0, 0);

    const key = weekdayKey(day);
    if (key === "fri" || key === "sat") {
      continue;
    }

    for (let hour = 9; hour < 12; hour += 1) {
      for (let minute = 0; minute < 60; minute += slotDurationMinutes) {
        if (hour === 11 && minute + slotDurationMinutes > 60) {
          continue;
        }

        const startsAt = new Date(day);
        startsAt.setUTCHours(hour, minute, 0, 0);
        const endsAt = new Date(startsAt);
        endsAt.setUTCMinutes(endsAt.getUTCMinutes() + slotDurationMinutes);

        slots.push({
          slotId: buildMaestroAvailabilitySlotId(startsAt),
          startsAt,
          endsAt,
        });
      }
    }
  }

  return slots;
}

export function buildLegacyAvailabilitySlotDoc(params: {
  teacherId: string;
  slot: GeneratedAvailabilitySlot;
  now: Date;
}): Record<string, unknown> {
  return {
    teacherId: params.teacherId,
    startsAt: params.slot.startsAt,
    endsAt: params.slot.endsAt,
    isBooked: false,
    status: "open",
    createdAt: params.now,
    updatedAt: params.now,
  };
}

export function mergeTeacherWhitelist(
  existing: unknown,
  teacherProfileId: string,
): string[] {
  const current = Array.isArray(existing)
    ? existing.filter((value): value is string => typeof value === "string")
    : [];
  if (current.includes(teacherProfileId)) {
    return current;
  }
  return [...current, teacherProfileId].sort();
}

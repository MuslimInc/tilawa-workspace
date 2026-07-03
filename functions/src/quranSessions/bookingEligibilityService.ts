import { Firestore, Timestamp } from "firebase-admin/firestore";

import { lifecycleError } from "./lifecycleErrors";
import {
  loadEffectiveMarketPolicy,
  assertBookingPolicyConfigured,
  type ResolvedMarketPolicy,
} from "./sessionPolicyResolver";

/**
 * Server-side parity with the domain `ValidateBookingEligibilityUseCase`
 * (packages/quran_sessions/.../validate_booking_eligibility_usecase.dart).
 *
 * The mobile client runs the same rules, but client checks are advisory only —
 * a modified client can skip them. These checks are authoritative: child-safety
 * (gender / age), teacher verification, and pricing are enforced here before
 * any booking document is written.
 */

export type Gender = "male" | "female";
export type AllowedStudentGender = "maleOnly" | "femaleOnly" | "both";

export interface StudentEligibilityProfile {
  exists: boolean;
  accountStatus: string;
  gender: Gender | null;
  dateOfBirth: Date | null;
  countryCode: string | null;
  cityId: string | null;
  restrictionReason: string | null;
}

export interface TeacherEligibilityProfile {
  exists: boolean;
  verificationStatus: string;
  gender: Gender;
  allowedStudentGender: AllowedStudentGender;
  canTeachChildren: boolean;
}

export interface GlobalSafetyPolicy {
  childAgeThreshold: number;
  globalAllowMaleTeacherFemaleStudent: boolean;
  globalAllowFemaleTeacherMaleStudent: boolean;
}

export interface ResolvedPricing {
  /** True when the teacher has a price configured for the student's market. */
  isPaid: boolean;
  amount: number;
  currencyCode: string;
}

export interface BookingEligibilityContext {
  student: StudentEligibilityProfile;
  teacher: TeacherEligibilityProfile;
  policy: GlobalSafetyPolicy;
  market: ResolvedMarketPolicy;
  /** Only blocking when the market doc explicitly disables the country. */
  marketEnabled: boolean;
  pricing: ResolvedPricing;
}

// ── Pure helpers (unit-tested, no I/O) ──────────────────────────────────────

/** Calendar age in whole years, matching the domain `_calendarAge`. */
export function calendarAge(dob: Date, now: Date): number {
  let age = now.getUTCFullYear() - dob.getUTCFullYear();
  const monthDelta = now.getUTCMonth() - dob.getUTCMonth();
  const birthdayPassed =
    monthDelta > 0 || (monthDelta === 0 && now.getUTCDate() >= dob.getUTCDate());
  if (!birthdayPassed) age -= 1;
  return age;
}

/** A null DOB is treated as adult — the safe default, matching the domain. */
export function isChild(
  dob: Date | null,
  childAgeThreshold: number,
  now: Date,
): boolean {
  if (dob == null) return false;
  return calendarAge(dob, now) < childAgeThreshold;
}

/** Mirrors `QuranSessionSafetyPolicy.isGenderCombinationAllowed`. */
export function isGenderCombinationAllowed(args: {
  teacherGender: Gender;
  studentGender: Gender;
  allowedStudentGender: AllowedStudentGender;
  globalAllowMaleTeacherFemaleStudent: boolean;
  globalAllowFemaleTeacherMaleStudent: boolean;
}): boolean {
  // 1. Teacher-level allowed student genders.
  if (args.allowedStudentGender === "maleOnly" && args.studentGender !== "male") {
    return false;
  }
  if (
    args.allowedStudentGender === "femaleOnly" &&
    args.studentGender !== "female"
  ) {
    return false;
  }

  // 2. Global policy ceiling (applies even when the teacher allows both).
  if (
    args.teacherGender === "male" &&
    args.studentGender === "female" &&
    !args.globalAllowMaleTeacherFemaleStudent
  ) {
    return false;
  }
  if (
    args.teacherGender === "female" &&
    args.studentGender === "male" &&
    !args.globalAllowFemaleTeacherMaleStudent
  ) {
    return false;
  }

  return true;
}

/**
 * Throws a typed `lifecycleError` when the booking is not eligible. Returns the
 * server-derived pricing when eligible (callers use it to gate paid bookings
 * and to record the authoritative price).
 */
export function assertBookingEligible(
  ctx: BookingEligibilityContext,
  now: Date,
  options?: {
    teacherId?: string;
    startsAt?: Date;
    upcomingCount?: number;
  },
): ResolvedPricing {
  const { student, teacher, policy, market } = ctx;

  if (!student.exists) {
    throw lifecycleError("profile_incomplete", "Student profile not found.", {
      missingFields: ["profile"],
    });
  }
  if (student.accountStatus !== "active") {
    throw lifecycleError("account_blocked", "Student account is not active.", {
      restrictionReason: student.restrictionReason,
    });
  }

  const missing: string[] = [];
  if (student.gender == null) missing.push("gender");
  if (student.dateOfBirth == null) missing.push("dateOfBirth");
  if (student.countryCode == null) missing.push("countryCode");
  if (student.cityId == null) missing.push("cityId");
  if (missing.length > 0) {
    throw lifecycleError("profile_incomplete", "Student profile is incomplete.", {
      missingFields: missing,
    });
  }

  if (!ctx.marketEnabled || !market.marketEnabled) {
    throw lifecycleError("market_not_enabled", "Market is not enabled.", {
      countryCode: student.countryCode,
      cityId: student.cityId,
    });
  }

  const teacherId = options?.teacherId;
  if (
    teacherId != null &&
    market.teacherWhitelist != null &&
    !market.teacherWhitelist.includes(teacherId)
  ) {
    throw lifecycleError("teacher_not_whitelisted", "Teacher is not enabled in this market.", {
      teacherId,
      countryCode: student.countryCode,
    });
  }

  if (!teacher.exists || teacher.verificationStatus !== "verified") {
    throw lifecycleError("teacher_not_verified", "Teacher is not verified.", {
      verificationStatus: teacher.verificationStatus,
    });
  }

  if (
    market.genderMatchingEnabled &&
    !isGenderCombinationAllowed({
      teacherGender: teacher.gender,
      studentGender: student.gender as Gender,
      allowedStudentGender: teacher.allowedStudentGender,
      globalAllowMaleTeacherFemaleStudent:
        policy.globalAllowMaleTeacherFemaleStudent,
      globalAllowFemaleTeacherMaleStudent:
        policy.globalAllowFemaleTeacherMaleStudent,
    })
  ) {
    throw lifecycleError("gender_not_allowed", "Gender combination not allowed.", {
      teacherGender: teacher.gender,
      studentGender: student.gender,
    });
  }

  if (isChild(student.dateOfBirth, policy.childAgeThreshold, now)) {
    if (!teacher.canTeachChildren) {
      throw lifecycleError("age_not_allowed", "Teacher does not teach children.", {
        studentAgeGroup: "child",
      });
    }
  }

  if (options?.startsAt != null) {
    const noticeMs = options.startsAt.getTime() - now.getTime();
    if (noticeMs < market.minBookingNoticeMs) {
      throw lifecycleError(
        "min_notice_violation",
        "Booking is too close to session start.",
        { minNoticeMinutes: market.minBookingNoticeMs / (60 * 1000) },
      );
    }
  }

  if (
    options?.upcomingCount != null &&
    options.upcomingCount >= market.maxConcurrentUpcomingPerStudent
  ) {
    throw lifecycleError(
      "max_upcoming_exceeded",
      "Student has reached the maximum upcoming sessions.",
      { maxUpcoming: market.maxConcurrentUpcomingPerStudent },
    );
  }

  return ctx.pricing;
}

// ── Firestore loader (I/O, reads outside the booking transaction) ───────────

function parseGender(raw: unknown): Gender | null {
  if (raw === "female") return "female";
  if (raw === "male") return "male";
  return null;
}

function parseDate(raw: unknown): Date | null {
  if (raw instanceof Timestamp) return raw.toDate();
  if (typeof raw === "string" && raw.length > 0) {
    const d = new Date(raw);
    return Number.isNaN(d.getTime()) ? null : d;
  }
  // Admin SDK Timestamps expose toDate(); guard structurally too.
  if (raw && typeof (raw as { toDate?: unknown }).toDate === "function") {
    return (raw as { toDate(): Date }).toDate();
  }
  return null;
}

function parseAllowedStudentGender(raw: unknown): AllowedStudentGender {
  if (raw === "maleOnly") return "maleOnly";
  if (raw === "femaleOnly") return "femaleOnly";
  return "both";
}

export async function loadBookingEligibilityContext(
  db: Firestore,
  studentId: string,
  teacherId: string,
): Promise<BookingEligibilityContext> {
  const [studentSnap, teacherSnap, policySnap] = await Promise.all([
    db.collection("users").doc(studentId).get(),
    db.collection("quran_teacher_profiles").doc(teacherId).get(),
    db.collection("quran_session_platform_config").doc("global").get(),
  ]);

  const platformConfig = policySnap.data() ?? {};

  const studentProfile =
    (studentSnap.data()?.quranSessionsProfile as Record<string, unknown>) ?? {};
  const student: StudentEligibilityProfile = {
    exists: studentSnap.exists && studentSnap.data()?.quranSessionsProfile != null,
    accountStatus: (studentProfile.accountStatus as string) ?? "active",
    gender: parseGender(studentProfile.gender),
    dateOfBirth: parseDate(studentProfile.dateOfBirth),
    countryCode: (studentProfile.countryCode as string) ?? null,
    cityId: (studentProfile.cityId as string) ?? null,
    restrictionReason: (studentProfile.restrictionReason as string) ?? null,
  };

  const teacherData = teacherSnap.data() ?? {};
  const teacher: TeacherEligibilityProfile = {
    exists: teacherSnap.exists,
    verificationStatus: (teacherData.verificationStatus as string) ?? "pending",
    gender: parseGender(teacherData.gender) ?? "male",
    allowedStudentGender: parseAllowedStudentGender(teacherData.allowedStudentGender),
    canTeachChildren: (teacherData.canTeachChildren as boolean) ?? true,
  };

  const policyData = platformConfig;
  const policy: GlobalSafetyPolicy = {
    childAgeThreshold: (policyData.childAgeThreshold as number) ?? 14,
    globalAllowMaleTeacherFemaleStudent:
      (policyData.globalAllowMaleTeacherFemaleStudent as boolean) ?? true,
    globalAllowFemaleTeacherMaleStudent:
      (policyData.globalAllowFemaleTeacherMaleStudent as boolean) ?? true,
  };

  let marketEnabled = true;
  let market: ResolvedMarketPolicy = {
    countryCode: student.countryCode ?? "",
    cityId: student.cityId ?? "",
    marketEnabled: true,
    cityEnabled: true,
    sessionFeeAmount: 0,
    currencyCode: "USD",
    bookingMode: "requiresTutorApproval",
    genderMatchingEnabled: true,
    teacherWhitelist: null,
    tutorApprovalSlaMs: 24 * 60 * 60 * 1000,
    minBookingNoticeMs: 60 * 60 * 1000,
    maxConcurrentUpcomingPerStudent: 3,
    joinWindowLeadMs: 15 * 60 * 1000,
    sessionMode: "videoOnly",
    policyVersion: null,
    effectiveFrom: null,
  };
  let pricing: ResolvedPricing = { isPaid: false, amount: 0, currencyCode: "USD" };

  if (student.countryCode != null && student.cityId != null) {
    const marketSnap = await db
      .collection("quran_session_market_configs")
      .doc(student.countryCode)
      .get();
    assertBookingPolicyConfigured({
      platformConfig,
      marketData: marketSnap.data(),
      countryCode: student.countryCode,
      cityId: student.cityId,
      marketDocExists: marketSnap.exists,
    });

    market = await loadEffectiveMarketPolicy(
      db,
      student.countryCode,
      student.cityId,
      platformConfig,
    );
    marketEnabled = market.marketEnabled;
    pricing = {
      isPaid: market.sessionFeeAmount > 0,
      amount: market.sessionFeeAmount,
      currencyCode: market.currencyCode,
    };
  }

  return { student, teacher, policy, market, marketEnabled, pricing };
}

export async function countStudentUpcomingBookings(
  db: Firestore,
  studentId: string,
): Promise<number> {
  const upcomingStatuses = [
    "scheduled",
    "confirmed",
    "in_progress",
    "pending_tutor_approval",
    "pending_payment",
    "rescheduled",
  ];
  const snap = await db
    .collection("quran_bookings")
    .where("studentId", "==", studentId)
    .where("lifecycleStatus", "in", upcomingStatuses)
    .limit(20)
    .get();
  return snap.size;
}

import test from "node:test";
import assert from "node:assert/strict";

import {
  assertBookingEligible,
  calendarAge,
  isChild,
  isGenderCombinationAllowed,
  type BookingEligibilityContext,
} from "../../src/quranSessions/bookingEligibilityService";

const NOW = new Date("2024-06-01T00:00:00.000Z");

function baseContext(
  overrides: {
    student?: Partial<BookingEligibilityContext["student"]>;
    teacher?: Partial<BookingEligibilityContext["teacher"]>;
    policy?: Partial<BookingEligibilityContext["policy"]>;
    marketEnabled?: boolean;
    pricing?: BookingEligibilityContext["pricing"];
  } = {},
): BookingEligibilityContext {
  return {
    student: {
      exists: true,
      accountStatus: "active",
      gender: "male",
      dateOfBirth: new Date("1990-01-01T00:00:00.000Z"),
      countryCode: "EG",
      cityId: "cairo",
      guardianId: null,
      guardianChildBookingApprovedAt: null,
      restrictionReason: null,
      ...overrides.student,
    },
    teacher: {
      exists: true,
      verificationStatus: "verified",
      gender: "male",
      allowedStudentGender: "both",
      canTeachChildren: true,
      requiresGuardianApprovalForChildren: false,
      ...overrides.teacher,
    },
    policy: {
      childAgeThreshold: 14,
      globalAllowMaleTeacherFemaleStudent: true,
      globalAllowFemaleTeacherMaleStudent: true,
      requireGuardianApprovalForChildren: false,
      ...overrides.policy,
    },
    marketEnabled: overrides.marketEnabled ?? true,
    pricing: overrides.pricing ?? { isPaid: false, amount: 0, currencyCode: "USD" },
  };
}

function expectCode(fn: () => unknown, code: string) {
  assert.throws(fn, (err: unknown) => {
    const details = (err as { details?: { code?: string } }).details;
    assert.equal(details?.code, code, `expected eligibility code "${code}"`);
    return true;
  });
}

test("calendarAge subtracts a year when birthday has not occurred yet", () => {
  assert.equal(calendarAge(new Date("2000-12-31T00:00:00Z"), NOW), 23);
  assert.equal(calendarAge(new Date("2000-01-01T00:00:00Z"), NOW), 24);
});

test("isChild treats a null DOB as adult (safe default)", () => {
  assert.equal(isChild(null, 14, NOW), false);
  assert.equal(isChild(new Date("2015-01-01Z"), 14, NOW), true); // age 9
  assert.equal(isChild(new Date("2008-01-01Z"), 14, NOW), false); // age 16
});

test("gender matrix: teacher maleOnly rejects female student", () => {
  assert.equal(
    isGenderCombinationAllowed({
      teacherGender: "male",
      studentGender: "female",
      allowedStudentGender: "maleOnly",
      globalAllowMaleTeacherFemaleStudent: true,
      globalAllowFemaleTeacherMaleStudent: true,
    }),
    false,
  );
});

test("gender matrix: global ceiling blocks male teacher / female student", () => {
  assert.equal(
    isGenderCombinationAllowed({
      teacherGender: "male",
      studentGender: "female",
      allowedStudentGender: "both",
      globalAllowMaleTeacherFemaleStudent: false,
      globalAllowFemaleTeacherMaleStudent: true,
    }),
    false,
  );
});

test("gender matrix: same-gender always allowed", () => {
  assert.equal(
    isGenderCombinationAllowed({
      teacherGender: "female",
      studentGender: "female",
      allowedStudentGender: "femaleOnly",
      globalAllowMaleTeacherFemaleStudent: false,
      globalAllowFemaleTeacherMaleStudent: false,
    }),
    true,
  );
});

test("assertBookingEligible passes the happy path and returns pricing", () => {
  const pricing = assertBookingEligible(
    baseContext({ pricing: { isPaid: true, amount: 12, currencyCode: "USD" } }),
    NOW,
  );
  assert.equal(pricing.isPaid, true);
  assert.equal(pricing.amount, 12);
});

test("assertBookingEligible rejects a blocked student account", () => {
  expectCode(
    () => assertBookingEligible(baseContext({ student: { accountStatus: "blocked" } }), NOW),
    "account_blocked",
  );
});

test("assertBookingEligible rejects an incomplete student profile", () => {
  expectCode(
    () => assertBookingEligible(baseContext({ student: { dateOfBirth: null, cityId: null } }), NOW),
    "profile_incomplete",
  );
});

test("assertBookingEligible rejects a disabled market", () => {
  expectCode(
    () => assertBookingEligible(baseContext({ marketEnabled: false }), NOW),
    "market_not_enabled",
  );
});

test("assertBookingEligible rejects an unverified teacher", () => {
  expectCode(
    () => assertBookingEligible(baseContext({ teacher: { verificationStatus: "pending" } }), NOW),
    "teacher_not_verified",
  );
});

test("assertBookingEligible rejects a disallowed gender combination", () => {
  expectCode(
    () =>
      assertBookingEligible(
        baseContext({
          student: { gender: "female" },
          teacher: { allowedStudentGender: "maleOnly" },
        }),
        NOW,
      ),
    "gender_not_allowed",
  );
});

test("assertBookingEligible rejects a child when teacher cannot teach children", () => {
  expectCode(
    () =>
      assertBookingEligible(
        baseContext({
          student: { dateOfBirth: new Date("2015-01-01Z") },
          teacher: { canTeachChildren: false },
        }),
        NOW,
      ),
    "age_not_allowed",
  );
});

test("assertBookingEligible blocks a child when guardian approval is required", () => {
  expectCode(
    () =>
      assertBookingEligible(
        baseContext({
          student: { dateOfBirth: new Date("2015-01-01Z") },
          policy: { requireGuardianApprovalForChildren: true },
        }),
        NOW,
      ),
    "guardian_approval_required",
  );
});

test("assertBookingEligible allows a child when guardian approval is recorded", () => {
  const pricing = assertBookingEligible(
    baseContext({
      student: {
        dateOfBirth: new Date("2015-01-01Z"),
        guardianId: "guardian_uid",
        guardianChildBookingApprovedAt: new Date("2024-01-01Z"),
      },
      policy: { requireGuardianApprovalForChildren: true },
    }),
    NOW,
  );
  assert.equal(pricing.isPaid, false);
});

test("assertBookingEligible allows an eligible child (teacher teaches children, no guardian gate)", () => {
  const pricing = assertBookingEligible(
    baseContext({ student: { dateOfBirth: new Date("2015-01-01Z") } }),
    NOW,
  );
  assert.equal(pricing.isPaid, false);
});

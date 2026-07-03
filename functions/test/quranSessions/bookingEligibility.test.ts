import test from "node:test";
import assert from "node:assert/strict";

import {
  assertBookingEligible,
  assertGuardianCanApproveChildBooking,
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
    market?: Partial<BookingEligibilityContext["market"]> & Pick<
      BookingEligibilityContext["market"],
      "countryCode" | "cityId"
    >;
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
    market: {
      countryCode: "EG",
      cityId: "cairo",
      marketEnabled: true,
      cityEnabled: true,
      sessionFeeAmount: 0,
      currencyCode: "USD",
      bookingMode: "autoConfirm",
      genderMatchingEnabled: true,
      teacherWhitelist: null,
      tutorApprovalSlaMs: 24 * 60 * 60 * 1000,
      minBookingNoticeMs: 60 * 60 * 1000,
      maxConcurrentUpcomingPerStudent: 3,
      joinWindowLeadMs: 15 * 60 * 1000,
      sessionMode: "videoOnly",
      policyVersion: null,
      effectiveFrom: null,
      ...overrides.market,
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
          student: {
            dateOfBirth: new Date("2015-01-01Z"),
            guardianId: "guardian_uid",
          },
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

test("assertBookingEligible blocks child bookings until guardian is linked (Q-EC-01)", () => {
  expectCode(
    () =>
      assertBookingEligible(
        baseContext({ student: { dateOfBirth: new Date("2015-01-01Z") } }),
        NOW,
      ),
    "guardian_approval_required",
  );
});

test("assertBookingEligible allows child with linked guardian when approval not required", () => {
  const pricing = assertBookingEligible(
    baseContext({
      student: {
        dateOfBirth: new Date("2015-01-01Z"),
        guardianId: "guardian_uid",
      },
    }),
    NOW,
  );
  assert.equal(pricing.isPaid, false);
});

test("assertGuardianCanApproveChildBooking rejects missing guardian DOB", () => {
  expectCode(
    () => assertGuardianCanApproveChildBooking(null, 14, NOW),
    "guardian_approval_invalid",
  );
});

test("assertGuardianCanApproveChildBooking rejects child guardian DOB", () => {
  expectCode(
    () =>
      assertGuardianCanApproveChildBooking(
        new Date("2015-01-01Z"),
        14,
        NOW,
      ),
    "guardian_approval_invalid",
  );
});

test("assertGuardianCanApproveChildBooking accepts adult guardian DOB", () => {
  assert.doesNotThrow(() =>
    assertGuardianCanApproveChildBooking(
      new Date("1990-01-01Z"),
      14,
      NOW,
    ),
  );
});

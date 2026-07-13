import test from "node:test";
import assert from "node:assert/strict";

import {
  canReadPackage,
  hasPackageAdminClaim,
  isPackageMarketEligible,
  resolveActingLearner,
} from "../../src/quranSessions/packages/packageAuth";

const EG_ONLY = ["EG"] as const;

test("market eligibility is case/whitespace insensitive", () => {
  assert.equal(isPackageMarketEligible("EG", EG_ONLY), true);
  assert.equal(isPackageMarketEligible(" eg ", EG_ONLY), true);
  assert.equal(isPackageMarketEligible("SA", EG_ONLY), false);
});

test("super admin satisfies every granular claim", () => {
  const claims = { admin: true };
  assert.equal(hasPackageAdminClaim(claims, "packageConfigAdmin"), true);
  assert.equal(hasPackageAdminClaim(claims, "packagePaymentAdmin"), true);
  assert.equal(hasPackageAdminClaim(claims, "packageCreditAdmin"), true);
});

test("granular claim grants only its own scope", () => {
  const claims = { packagePaymentAdmin: true };
  assert.equal(hasPackageAdminClaim(claims, "packagePaymentAdmin"), true);
  assert.equal(hasPackageAdminClaim(claims, "packageCreditAdmin"), false);
  assert.equal(hasPackageAdminClaim(claims, "packageConfigAdmin"), false);
});

test("no claim grants nothing", () => {
  assert.equal(hasPackageAdminClaim({}, "packagePaymentAdmin"), false);
});

test("adult self-service resolves caller as learner", () => {
  const r = resolveActingLearner({
    callerUid: "u1",
    learnerIsChild: false,
    callerIsVerifiedGuardian: false,
  });
  assert.equal(r.ok, true);
  if (r.ok) {
    assert.equal(r.learnerId, "u1");
    assert.equal(r.guardianId, undefined);
  }
});

test("child acting for themselves requires a guardian", () => {
  const r = resolveActingLearner({
    callerUid: "child1",
    learnerIsChild: true,
    callerIsVerifiedGuardian: false,
  });
  assert.equal(r.ok, false);
  if (!r.ok) assert.equal(r.code, "guardian_required");
});

test("verified guardian may act for a child", () => {
  const r = resolveActingLearner({
    callerUid: "guardian1",
    requestedLearnerId: "child1",
    learnerIsChild: true,
    callerIsVerifiedGuardian: true,
  });
  assert.equal(r.ok, true);
  if (r.ok) {
    assert.equal(r.learnerId, "child1");
    assert.equal(r.guardianId, "guardian1");
  }
});

test("non-guardian acting for another learner is rejected", () => {
  const r = resolveActingLearner({
    callerUid: "stranger",
    requestedLearnerId: "child1",
    learnerIsChild: true,
    callerIsVerifiedGuardian: false,
  });
  assert.equal(r.ok, false);
  if (!r.ok) assert.equal(r.code, "unauthorized_guardian");
});

test("canReadPackage allows learner, teacher, guardian, and credit admin", () => {
  const subject = { learnerId: "L", teacherId: "T", guardianId: "G" };
  assert.equal(canReadPackage(subject, { callerUid: "L", claims: {} }), true);
  assert.equal(canReadPackage(subject, { callerUid: "T", claims: {} }), true);
  assert.equal(canReadPackage(subject, { callerUid: "G", claims: {} }), true);
  assert.equal(
    canReadPackage(subject, { callerUid: "X", claims: { packageCreditAdmin: true } }),
    true,
  );
});

test("canReadPackage denies an unrelated user", () => {
  const subject = { learnerId: "L", teacherId: "T" };
  assert.equal(canReadPackage(subject, { callerUid: "X", claims: {} }), false);
});

test("canReadPackage denies a config-only admin (no read scope)", () => {
  const subject = { learnerId: "L", teacherId: "T" };
  assert.equal(
    canReadPackage(subject, { callerUid: "X", claims: { packageConfigAdmin: true } }),
    false,
  );
});

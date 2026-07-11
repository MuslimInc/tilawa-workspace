/**
 * Authorization for Quran learning package commands.
 *
 * The exported predicates are pure (no Firestore, no `CallableRequest`) so they
 * can be exhaustively unit-tested; the `assert*` guards wrap them and throw a
 * typed {@link HttpsError} at the callable boundary. Granular admin claims are
 * modelled so payment resolution, credit adjustment, and plan configuration can
 * be delegated to distinct operator roles rather than a single `admin` bit.
 */

import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";

// ── Claims ────────────────────────────────────────────────────────────────────

/**
 * Granular admin claims. The legacy `admin` bit is a superuser that satisfies
 * every package claim; the specific claims allow least-privilege operators.
 */
export type PackageAdminClaim =
  | "packageConfigAdmin" // configure plans
  | "packagePaymentAdmin" // confirm/reject manual payment
  | "packageCreditAdmin"; // adjust credit / extend validity (finance/support)

export interface PackageAuthContext {
  callerUid: string;
  /** Truthy custom claims from the caller's token. */
  claims: Record<string, unknown>;
}

export function readPackageAuthContext(
  request: CallableRequest<unknown>,
): PackageAuthContext {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  return { callerUid: uid, claims: request.auth?.token ?? {} };
}

export function isSuperAdmin(claims: Record<string, unknown>): boolean {
  return claims.admin === true;
}

export function hasPackageAdminClaim(
  claims: Record<string, unknown>,
  claim: PackageAdminClaim,
): boolean {
  return isSuperAdmin(claims) || claims[claim] === true;
}

// ── Market eligibility ────────────────────────────────────────────────────────

/**
 * Whether a market is open for package sales. `enabledMarkets` is the
 * server-controlled allow-list (Egypt-only during the MVP).
 */
export function isPackageMarketEligible(
  marketCode: string,
  enabledMarkets: readonly string[],
): boolean {
  const normalized = marketCode.trim().toUpperCase();
  return enabledMarkets.some((m) => m.trim().toUpperCase() === normalized);
}

// ── Acting learner resolution (guardian-on-behalf) ────────────────────────────

export interface ActingLearnerInput {
  callerUid: string;
  /** Present when the caller acts on behalf of a child learner. */
  requestedLearnerId?: string;
  /** Whether the requested learner is a child requiring a verified guardian. */
  learnerIsChild: boolean;
  /**
   * Verified guardian link check for (callerUid → requestedLearnerId). Only
   * consulted when the caller and learner differ.
   */
  callerIsVerifiedGuardian: boolean;
}

export type ActingLearnerResult =
  | { ok: true; learnerId: string; guardianId?: string }
  | {
      ok: false;
      code: "guardian_required" | "unauthorized_guardian";
      detail: string;
    };

/**
 * Resolves the effective learner for a command and enforces guardian rules:
 *
 * - Self-service adult: caller is the learner.
 * - Guardian acting for a child: caller must be a verified guardian.
 * - A child acting without a guardian is rejected.
 */
export function resolveActingLearner(
  input: ActingLearnerInput,
): ActingLearnerResult {
  const learnerId = input.requestedLearnerId ?? input.callerUid;
  const isSelf = learnerId === input.callerUid;

  if (isSelf) {
    if (input.learnerIsChild) {
      return {
        ok: false,
        code: "guardian_required",
        detail: "child_learner_requires_guardian",
      };
    }
    return { ok: true, learnerId };
  }

  // Caller differs from learner: only a verified guardian may act.
  if (!input.callerIsVerifiedGuardian) {
    return {
      ok: false,
      code: "unauthorized_guardian",
      detail: "caller_not_verified_guardian",
    };
  }
  return { ok: true, learnerId, guardianId: input.callerUid };
}

// ── Role-safe package reads ───────────────────────────────────────────────────

export interface PackageReadSubject {
  learnerId: string;
  teacherId: string;
  guardianId?: string;
}

/**
 * Whether the caller may read a package projection: the learner, the assigned
 * teacher, the active verified guardian, or a package admin.
 */
export function canReadPackage(
  subject: PackageReadSubject,
  ctx: PackageAuthContext,
): boolean {
  if (ctx.callerUid === subject.learnerId) return true;
  if (ctx.callerUid === subject.teacherId) return true;
  if (subject.guardianId && ctx.callerUid === subject.guardianId) return true;
  return (
    isSuperAdmin(ctx.claims) ||
    hasPackageAdminClaim(ctx.claims, "packagePaymentAdmin") ||
    hasPackageAdminClaim(ctx.claims, "packageCreditAdmin")
  );
}

// ── Guards (throw HttpsError) ─────────────────────────────────────────────────

export function assertPackageAdminClaim(
  ctx: PackageAuthContext,
  claim: PackageAdminClaim,
): void {
  if (!hasPackageAdminClaim(ctx.claims, claim)) {
    throw new HttpsError("permission-denied", "Package admin claim required.", {
      code: "package_admin_claim_required",
      requiredClaim: claim,
    });
  }
}

export function assertPackageMarketEligible(
  marketCode: string,
  enabledMarkets: readonly string[],
): void {
  if (!isPackageMarketEligible(marketCode, enabledMarkets)) {
    throw new HttpsError(
      "failed-precondition",
      "Package sales are not available in this market.",
      { code: "package_market_not_eligible", marketCode },
    );
  }
}

export function assertCanReadPackage(
  subject: PackageReadSubject,
  ctx: PackageAuthContext,
): void {
  if (!canReadPackage(subject, ctx)) {
    throw new HttpsError(
      "permission-denied",
      "You are not authorized to view this package.",
      { code: "package_read_forbidden" },
    );
  }
}

/**
 * Throwing variant of {@link resolveActingLearner}.
 */
export function assertActingLearner(input: ActingLearnerInput): {
  learnerId: string;
  guardianId?: string;
} {
  const result = resolveActingLearner(input);
  if (!result.ok) {
    throw new HttpsError("permission-denied", "Guardian authorization failed.", {
      code: result.code,
      detail: result.detail,
    });
  }
  return { learnerId: result.learnerId, guardianId: result.guardianId };
}

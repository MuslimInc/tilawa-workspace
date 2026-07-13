/**
 * Pure credit-accounting core for Quran learning packages.
 *
 * This module is deliberately framework-free (no Firestore, no HttpsError) so
 * the invariant logic is exhaustively unit-testable. The transactional wrapper
 * ({@link createPackageBooking}, the lifecycle adapter, admin callables) reads
 * the current package, calls one of these operations, and — only when the
 * result is `ok` — persists the returned counters and movement inside a single
 * Firestore transaction, incrementing the package `version`.
 *
 * ## Conservation invariant
 *
 * ```
 * issued + adjustPositive === available + reserved + consumed + expired + adjustNegative
 * ```
 *
 * Every operation returns counters for which
 * {@link isCountersConsistent} holds, or an error. A failed operation never
 * mutates the input counters.
 *
 * ## Determinism / idempotency
 *
 * Each operation derives a deterministic `movementId` from the package id, the
 * movement type, and a caller-supplied semantic event reference (booking id,
 * session id, order id, or admin idempotency key). Re-issuing the same semantic
 * event yields the same id, so the transactional layer can treat an existing
 * movement document as a completed no-op.
 */

import {
  isCountersConsistent,
  isCountersNonNegative,
  type PackageCreditMovementType,
  type StudentPackageCounters,
} from "./packageTypes";

export type PackageCreditErrorCode =
  | "no_credit_available"
  | "no_reservation_to_finalize"
  | "nothing_to_expire"
  | "adjustment_underflow"
  | "invalid_quantity"
  | "invariant_violation";

export interface PackageCreditError {
  code: PackageCreditErrorCode;
  detail: string;
}

/** Fields the transactional layer needs to persist a movement document. */
export interface PendingMovement {
  movementId: string;
  type: PackageCreditMovementType;
  quantity: number;
  reasonCode: string;
  bookingId?: string;
  sessionId?: string;
  orderId?: string;
  actorId?: string;
  idempotencyKey?: string;
}

export type CreditResult =
  | { ok: true; counters: StudentPackageCounters; movement: PendingMovement }
  | { ok: false; error: PackageCreditError };

function err(code: PackageCreditErrorCode, detail: string): CreditResult {
  return { ok: false, error: { code, detail } };
}

/**
 * Deterministic movement id. Same (packageId, type, eventRef) always produces
 * the same id so repeated delivery of one semantic event is idempotent.
 */
export function deterministicMovementId(
  packageId: string,
  type: PackageCreditMovementType,
  eventRef: string,
): string {
  const safeRef = eventRef.replace(/[^A-Za-z0-9_-]/g, "_");
  return `${packageId}__${type}__${safeRef}`;
}

/** Counters for a freshly issued package of `sessionCount` credits. */
export function issuedCounters(sessionCount: number): StudentPackageCounters {
  if (!Number.isInteger(sessionCount) || sessionCount <= 0) {
    throw new RangeError(`sessionCount must be a positive integer: ${sessionCount}`);
  }
  return {
    issuedCredits: sessionCount,
    availableCredits: sessionCount,
    reservedCredits: 0,
    consumedCredits: 0,
    restoredCredits: 0,
    expiredCredits: 0,
    adjustPositiveTotal: 0,
    adjustNegativeTotal: 0,
  };
}

/** Guard applied to every produced counter set before returning `ok`. */
function finalize(
  next: StudentPackageCounters,
  movement: PendingMovement,
): CreditResult {
  if (!isCountersNonNegative(next)) {
    return err("invariant_violation", "negative_counter");
  }
  if (!isCountersConsistent(next)) {
    return err("invariant_violation", "sum_mismatch");
  }
  return { ok: true, counters: next, movement };
}

/**
 * `issue` — mint the initial credits for a newly activated package. Only valid
 * on the empty/zero counters produced at activation.
 */
export function issue(
  packageId: string,
  sessionCount: number,
  orderId: string,
  policyReason = "package_activated",
): CreditResult {
  if (!Number.isInteger(sessionCount) || sessionCount <= 0) {
    return err("invalid_quantity", "session_count_must_be_positive");
  }
  const next = issuedCounters(sessionCount);
  return finalize(next, {
    movementId: deterministicMovementId(packageId, "issue", orderId),
    type: "issue",
    quantity: sessionCount,
    reasonCode: policyReason,
    orderId,
  });
}

/**
 * `reserve` — hold one credit for a new booking. available → reserved.
 */
export function reserve(
  packageId: string,
  counters: StudentPackageCounters,
  bookingId: string,
  reasonCode = "booking_created",
): CreditResult {
  if (counters.availableCredits < 1) {
    return err("no_credit_available", "available_is_zero");
  }
  const next: StudentPackageCounters = {
    ...counters,
    availableCredits: counters.availableCredits - 1,
    reservedCredits: counters.reservedCredits + 1,
  };
  return finalize(next, {
    movementId: deterministicMovementId(packageId, "reserve", bookingId),
    type: "reserve",
    quantity: 1,
    reasonCode,
    bookingId,
  });
}

/**
 * `consume` — finalize a used credit (session completed, or late/no-show
 * cancellation where the credit is forfeit). reserved → consumed.
 */
export function consume(
  packageId: string,
  counters: StudentPackageCounters,
  bookingId: string,
  sessionId: string | undefined,
  reasonCode: string,
): CreditResult {
  if (counters.reservedCredits < 1) {
    return err("no_reservation_to_finalize", "reserved_is_zero");
  }
  const next: StudentPackageCounters = {
    ...counters,
    reservedCredits: counters.reservedCredits - 1,
    consumedCredits: counters.consumedCredits + 1,
  };
  return finalize(next, {
    movementId: deterministicMovementId(packageId, "consume", bookingId),
    type: "consume",
    quantity: 1,
    reasonCode,
    bookingId,
    sessionId,
  });
}

/**
 * `restore` — return a reserved credit to available (eligible early
 * cancellation, teacher cancellation, or teacher no-show). reserved → available
 * and the `restoredCredits` tally increments.
 */
export function restore(
  packageId: string,
  counters: StudentPackageCounters,
  bookingId: string,
  sessionId: string | undefined,
  reasonCode: string,
): CreditResult {
  if (counters.reservedCredits < 1) {
    return err("no_reservation_to_finalize", "reserved_is_zero");
  }
  const next: StudentPackageCounters = {
    ...counters,
    reservedCredits: counters.reservedCredits - 1,
    availableCredits: counters.availableCredits + 1,
    restoredCredits: counters.restoredCredits + 1,
  };
  return finalize(next, {
    movementId: deterministicMovementId(packageId, "restore", bookingId),
    type: "restore",
    quantity: 1,
    reasonCode,
    bookingId,
    sessionId,
  });
}

/**
 * `expire` — retire all still-available credits when the validity window ends.
 * available → expired. Reserved credits are left for their booking lifecycle to
 * finalize; only unreserved credits expire.
 */
export function expire(
  packageId: string,
  counters: StudentPackageCounters,
  reasonCode = "validity_elapsed",
): CreditResult {
  const quantity = counters.availableCredits;
  if (quantity < 1) {
    return err("nothing_to_expire", "available_is_zero");
  }
  const next: StudentPackageCounters = {
    ...counters,
    availableCredits: 0,
    expiredCredits: counters.expiredCredits + quantity,
  };
  return finalize(next, {
    movementId: deterministicMovementId(packageId, "expire", `v${counters.issuedCredits}_${counters.expiredCredits}`),
    type: "expire",
    quantity,
    reasonCode,
  });
}

/**
 * `adjust` — privileged, bounded correction by a finance/support admin.
 * A positive quantity mints available credits; a negative quantity removes
 * available credits (never below zero). Requires a non-empty rationale and a
 * unique idempotency key (used as the movement event ref).
 */
export function adjust(
  packageId: string,
  counters: StudentPackageCounters,
  signedQuantity: number,
  reasonCode: string,
  actorId: string,
  idempotencyKey: string,
): CreditResult {
  if (!Number.isInteger(signedQuantity) || signedQuantity === 0) {
    return err("invalid_quantity", "must_be_nonzero_integer");
  }
  const magnitude = Math.abs(signedQuantity);
  if (signedQuantity > 0) {
    const next: StudentPackageCounters = {
      ...counters,
      availableCredits: counters.availableCredits + magnitude,
      adjustPositiveTotal: counters.adjustPositiveTotal + magnitude,
    };
    return finalize(next, {
      movementId: deterministicMovementId(packageId, "adjust_positive", idempotencyKey),
      type: "adjust_positive",
      quantity: magnitude,
      reasonCode,
      actorId,
      idempotencyKey,
    });
  }
  if (counters.availableCredits < magnitude) {
    return err("adjustment_underflow", "available_below_requested_decrease");
  }
  const next: StudentPackageCounters = {
    ...counters,
    availableCredits: counters.availableCredits - magnitude,
    adjustNegativeTotal: counters.adjustNegativeTotal + magnitude,
  };
  return finalize(next, {
    movementId: deterministicMovementId(packageId, "adjust_negative", idempotencyKey),
    type: "adjust_negative",
    quantity: magnitude,
    reasonCode,
    actorId,
    idempotencyKey,
  });
}

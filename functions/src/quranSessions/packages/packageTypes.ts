/**
 * Shared TypeScript types for the Quran learning packages feature
 * (prepaid eight-session private entitlement).
 *
 * These mirror the Dart domain (`packages/quran_sessions/.../quran_learning_package.dart`)
 * and the Firestore documents described in
 * `specs/042-quran-learning-packages/data-model.md`. Money is always integer
 * minor units; credits are always whole non-negative integers.
 */

import { Timestamp } from "firebase-admin/firestore";

// ── Enums (string unions) ─────────────────────────────────────────────────────

export type PackagePlanStatus = "draft" | "active" | "paused" | "retired";

export type PackageOrderStatus =
  | "pending_payment"
  | "confirmed"
  | "rejected"
  | "expired"
  | "cancelled";

export type StudentPackageStatus =
  | "active"
  | "completed"
  | "expired"
  | "cancelled"
  | "suspended";

export type PackageCreditMovementType =
  | "issue"
  | "reserve"
  | "consume"
  | "restore"
  | "expire"
  | "adjust_positive"
  | "adjust_negative";

export const PRIVILEGED_MOVEMENT_TYPES: ReadonlySet<PackageCreditMovementType> =
  new Set(["adjust_positive", "adjust_negative"]);

// ── Value objects ─────────────────────────────────────────────────────────────

export interface PackageTerms {
  planId: string;
  marketCode: string;
  sessionCount: number;
  sessionDurationMinutes: number;
  validityDays: number;
  cancellationCutoffHours: number;
  priceMinor: number;
  currencyCode: string;
  compatibilityMeetingAllowance: number;
  policyVersion: string;
  allowChildLearner: boolean;
}

export interface PackagePaymentInstruction {
  instructionVersion: string;
  methodCode: string;
  displayInstructions: string;
  paymentReference: string;
}

/**
 * Authoritative credit counters. See {@link isCountersConsistent} for the
 * conservation invariant.
 */
export interface StudentPackageCounters {
  issuedCredits: number;
  availableCredits: number;
  reservedCredits: number;
  consumedCredits: number;
  restoredCredits: number;
  expiredCredits: number;
  adjustPositiveTotal: number;
  adjustNegativeTotal: number;
}

// ── Aggregates ────────────────────────────────────────────────────────────────

export interface PackagePlan {
  planId: string;
  marketCode: string;
  localizedName: Record<string, string>;
  localizedDescription: Record<string, string>;
  terms: PackageTerms;
  status: PackagePlanStatus;
  eligibleTeacherIds: string[];
  policyVersion: string;
  updatedAt: Timestamp;
  autoRenew: boolean;
}

export interface PackageOrder {
  orderId: string;
  planId: string;
  learnerId: string;
  teacherId: string;
  marketCode: string;
  terms: PackageTerms;
  paymentInstruction: PackagePaymentInstruction;
  status: PackageOrderStatus;
  createdAt: Timestamp;
  expiresAt: Timestamp;
  guardianId?: string;
  cityId?: string;
  compatibilityMeetingId?: string;
  idempotencyKey?: string;
  resultingPackageId?: string;
  rejectionReason?: string;
  resolvedByActorId?: string;
  resolvedAt?: Timestamp;
}

export interface StudentPackage {
  packageId: string;
  orderId: string;
  planId: string;
  learnerId: string;
  teacherId: string;
  marketCode: string;
  terms: PackageTerms;
  counters: StudentPackageCounters;
  status: StudentPackageStatus;
  version: number;
  activatedAt: Timestamp;
  expiresAt: Timestamp;
  policyVersion: string;
  guardianId?: string;
  completedAt?: Timestamp;
  lastMovementId?: string;
  suspended: boolean;
}

export interface PackageCreditMovement {
  movementId: string;
  packageId: string;
  type: PackageCreditMovementType;
  quantity: number;
  reasonCode: string;
  policyVersion: string;
  createdAt: Timestamp;
  bookingId?: string;
  sessionId?: string;
  orderId?: string;
  actorId?: string;
  idempotencyKey?: string;
}

// ── Collection paths ──────────────────────────────────────────────────────────

export const PACKAGE_COLLECTIONS = {
  plans: "quran_package_plans",
  orders: "quran_package_orders",
  packages: "quran_student_packages",
  /** Subcollection of a package document. */
  creditMovements: "credit_movements",
} as const;

// ── Consistency helpers ───────────────────────────────────────────────────────

export function isCountersNonNegative(c: StudentPackageCounters): boolean {
  return (
    c.issuedCredits >= 0 &&
    c.availableCredits >= 0 &&
    c.reservedCredits >= 0 &&
    c.consumedCredits >= 0 &&
    c.restoredCredits >= 0 &&
    c.expiredCredits >= 0 &&
    c.adjustPositiveTotal >= 0 &&
    c.adjustNegativeTotal >= 0
  );
}

/**
 * The conservation invariant:
 *
 * ```
 * issuedCredits + adjustPositiveTotal
 *   === availableCredits + reservedCredits + consumedCredits
 *       + expiredCredits + adjustNegativeTotal
 * ```
 *
 * `restoredCredits` is a monotonic tally (a restore moves reserved → available,
 * leaving the sum unchanged) and is intentionally not part of the equation.
 */
export function isCountersConsistent(c: StudentPackageCounters): boolean {
  if (!isCountersNonNegative(c)) return false;
  const sources = c.issuedCredits + c.adjustPositiveTotal;
  const sinks =
    c.availableCredits +
    c.reservedCredits +
    c.consumedCredits +
    c.expiredCredits +
    c.adjustNegativeTotal;
  return sources === sinks;
}

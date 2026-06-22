import {
  Firestore,
  Transaction,
  FieldValue,
} from "firebase-admin/firestore";

import {
  appendAuditEvent,
  sessionRefForBooking,
  writeAggregateLifecycle,
} from "./aggregateWriteService";
import {
  financialExecutionStatus,
  PAYMENT_PROVIDER_ENABLED,
  type FinancialExecutionStatus,
} from "./paymentProviderStatus";
import { validateTransition } from "./sessionLifecycleGuard";
import type { LifecycleStatus } from "./sessionLifecycleService";

export type CompensationType =
  | "restore_credit"
  | "wallet_credit"
  | "replacement_session"
  | "extend_subscription"
  | "manual_review";

export interface IssueRefundRecordInput {
  tx: Transaction;
  db: Firestore;
  bookingRef: FirebaseFirestore.DocumentReference;
  booking: Record<string, unknown>;
  bookingId: string;
  reason: string;
  amountUsd?: number | null;
  actorId: string;
  actorRole: "admin" | "system";
  auditAction: string;
  auditSource: string;
  disputeId?: string;
}

export interface IssueRefundRecordResult {
  refundId: string;
  refundExecutionStatus: FinancialExecutionStatus;
  lifecycleStatus: LifecycleStatus;
  studentId: string;
  sessionId: string;
}

export interface IssueCompensationRecordInput {
  tx: Transaction;
  db: Firestore;
  bookingRef: FirebaseFirestore.DocumentReference;
  booking: Record<string, unknown>;
  bookingId: string;
  compensationType: CompensationType;
  reason: string;
  amountUsd?: number | null;
  actorId: string;
  actorRole: "admin" | "system";
  auditAction: string;
  auditSource: string;
  disputeId?: string;
}

export interface IssueCompensationRecordResult {
  compensationId: string;
  compensationExecutionStatus: FinancialExecutionStatus;
  lifecycleStatus: LifecycleStatus;
  studentId: string;
  sessionId: string;
}

/**
 * Records a refund ledger entry, updates aggregate lifecycle to refunded, and
 * appends audit. Caller must run inside an idempotent transaction.
 */
export function issueRefundRecord(
  input: IssueRefundRecordInput,
): IssueRefundRecordResult {
  const currentStatus = input.booking.lifecycleStatus as
    | LifecycleStatus
    | undefined;
  const guard = validateTransition({
    currentStatus: currentStatus ?? null,
    action: "issue_refund",
    actor: input.actorRole,
    reason: input.reason,
  });

  const sessionRef = sessionRefForBooking(input.db, input.booking);
  const refundRef = input.db.collection("quran_session_refunds").doc();
  const executionStatus = financialExecutionStatus();

  writeAggregateLifecycle(
    input.tx,
    { bookingRef: input.bookingRef, sessionRef },
    guard.to,
    {
      refundId: refundRef.id,
      refundExecutionStatus: executionStatus,
      refundReason: input.reason,
    },
    {
      refundId: refundRef.id,
      refundExecutionStatus: executionStatus,
    },
  );

  input.tx.set(refundRef, {
    refundId: refundRef.id,
    aggregateId: input.booking.aggregateId ?? input.bookingId,
    bookingId: input.bookingId,
    sessionId: input.booking.sessionId ?? null,
    disputeId: input.disputeId ?? null,
    amountUsd: input.amountUsd ?? input.booking.amountPaidUsd ?? null,
    reason: input.reason,
    status: executionStatus,
    paymentProviderEnabled: PAYMENT_PROVIDER_ENABLED,
    approvedByActorId: input.actorId,
    approvedByRole: input.actorRole,
    createdAt: FieldValue.serverTimestamp(),
    completedAt:
      executionStatus === "executed" ? FieldValue.serverTimestamp() : null,
  });

  appendAuditEvent(input.tx, input.db, {
    aggregateId: input.booking.aggregateId ?? input.bookingId,
    bookingId: input.bookingId,
    sessionId: input.booking.sessionId ?? null,
    refundId: refundRef.id,
    disputeId: input.disputeId ?? null,
    actorId: input.actorId,
    actorRole: input.actorRole,
    action: input.auditAction,
    previousStatus: currentStatus ?? null,
    newStatus: guard.to,
    reason: input.reason,
    refundExecutionStatus: executionStatus,
    source: input.auditSource,
  });

  return {
    refundId: refundRef.id,
    refundExecutionStatus: executionStatus,
    lifecycleStatus: guard.to,
    studentId: (input.booking.studentId as string | undefined) ?? "",
    sessionId: (input.booking.sessionId as string | undefined) ?? "",
  };
}

/**
 * Records a compensation ledger entry, updates aggregate lifecycle to
 * compensated, and appends audit. Caller must run inside an idempotent tx.
 */
export function issueCompensationRecord(
  input: IssueCompensationRecordInput,
): IssueCompensationRecordResult {
  const currentStatus = input.booking.lifecycleStatus as
    | LifecycleStatus
    | undefined;
  const guard = validateTransition({
    currentStatus: currentStatus ?? null,
    action: "issue_compensation",
    actor: input.actorRole,
    reason: input.reason,
  });

  const sessionRef = sessionRefForBooking(input.db, input.booking);
  const compensationRef = input.db.collection("quran_session_compensations").doc();
  const executionStatus = financialExecutionStatus();

  writeAggregateLifecycle(
    input.tx,
    { bookingRef: input.bookingRef, sessionRef },
    guard.to,
    {
      lastCompensationId: compensationRef.id,
      compensationExecutionStatus: executionStatus,
    },
    { compensationExecutionStatus: executionStatus },
  );

  input.tx.set(compensationRef, {
    compensationId: compensationRef.id,
    aggregateId: input.booking.aggregateId ?? input.bookingId,
    bookingId: input.bookingId,
    sessionId: input.booking.sessionId ?? null,
    disputeId: input.disputeId ?? null,
    type: input.compensationType,
    status: executionStatus,
    policyRuleId: input.disputeId ? "dispute_resolution" : "admin_manual",
    amountUsd: input.amountUsd ?? null,
    issuedByActorId: input.actorId,
    issuedByRole: input.actorRole,
    reason: input.reason,
    createdAt: FieldValue.serverTimestamp(),
    completedAt:
      executionStatus === "executed" ? FieldValue.serverTimestamp() : null,
  });

  appendAuditEvent(input.tx, input.db, {
    aggregateId: input.booking.aggregateId ?? input.bookingId,
    bookingId: input.bookingId,
    sessionId: input.booking.sessionId ?? null,
    compensationId: compensationRef.id,
    disputeId: input.disputeId ?? null,
    actorId: input.actorId,
    actorRole: input.actorRole,
    action: input.auditAction,
    previousStatus: currentStatus ?? null,
    newStatus: guard.to,
    reason: input.reason,
    compensationExecutionStatus: executionStatus,
    source: input.auditSource,
  });

  return {
    compensationId: compensationRef.id,
    compensationExecutionStatus: executionStatus,
    lifecycleStatus: guard.to,
    studentId: (input.booking.studentId as string | undefined) ?? "",
    sessionId: (input.booking.sessionId as string | undefined) ?? "",
  };
}

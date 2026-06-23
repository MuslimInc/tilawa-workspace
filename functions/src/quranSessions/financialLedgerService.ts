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
  isPaymentProviderEnabled,
  type FinancialExecutionStatus,
} from "./paymentProviderStatus";
import { validateTransition } from "./sessionLifecycleGuard";
import type { LifecycleStatus } from "./sessionLifecycleService";
import {
  compensationWalletIdempotencyKey,
  DEFAULT_WALLET_CURRENCY,
  postWalletCreditInTransaction,
  refundWalletIdempotencyKey,
} from "./walletService";

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
  walletTransactionId: string | null;
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
  walletTransactionId: string | null;
}

async function maybePostRefundWalletCredit(
  input: IssueRefundRecordInput,
  refundId: string,
  executionStatus: FinancialExecutionStatus,
): Promise<string | null> {
  if (executionStatus !== "executed") {
    return null;
  }

  const studentId = input.booking.studentId as string | undefined;
  if (!studentId) {
    return null;
  }

  const amount =
    input.amountUsd ??
    (input.booking.amountPaidUsd as number | undefined) ??
    0;
  if (!Number.isFinite(amount) || amount <= 0) {
    return null;
  }

  const credit = await postWalletCreditInTransaction({
    tx: input.tx,
    db: input.db,
    userId: studentId,
    amount,
    currency: DEFAULT_WALLET_CURRENCY,
    idempotencyKey: refundWalletIdempotencyKey(refundId),
    type: "refund_credit",
    sourceType: "refund",
    sourceId: refundId,
    description: input.reason,
    actorId: input.actorId,
    actorRole: input.actorRole,
    metadata: {
      bookingId: input.bookingId,
      disputeId: input.disputeId ?? null,
    },
  });

  return credit.transactionId;
}

async function maybePostCompensationWalletCredit(
  input: IssueCompensationRecordInput,
  compensationId: string,
  executionStatus: FinancialExecutionStatus,
): Promise<string | null> {
  if (executionStatus !== "executed" || input.compensationType !== "wallet_credit") {
    return null;
  }

  const studentId = input.booking.studentId as string | undefined;
  if (!studentId) {
    return null;
  }

  const amount =
    input.amountUsd ??
    (input.booking.amountPaidUsd as number | undefined) ??
    0;
  if (!Number.isFinite(amount) || amount <= 0) {
    return null;
  }

  const credit = await postWalletCreditInTransaction({
    tx: input.tx,
    db: input.db,
    userId: studentId,
    amount,
    currency: DEFAULT_WALLET_CURRENCY,
    idempotencyKey: compensationWalletIdempotencyKey(compensationId),
    type: "compensation_credit",
    sourceType: "compensation",
    sourceId: compensationId,
    description: input.reason,
    actorId: input.actorId,
    actorRole: input.actorRole,
    metadata: {
      bookingId: input.bookingId,
      disputeId: input.disputeId ?? null,
      compensationType: input.compensationType,
    },
  });

  return credit.transactionId;
}

/**
 * Records a refund ledger entry, updates aggregate lifecycle to refunded, and
 * appends audit. Caller must run inside an idempotent transaction.
 */
export async function issueRefundRecord(
  input: IssueRefundRecordInput,
): Promise<IssueRefundRecordResult> {
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
  const refundAmount =
    input.amountUsd ??
    (input.booking.amountPaidUsd as number | undefined) ??
    null;
  const walletTransactionId = await maybePostRefundWalletCredit(
    input,
    refundRef.id,
    executionStatus,
  );

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
    amountUsd: refundAmount,
    amount: refundAmount,
    currency: DEFAULT_WALLET_CURRENCY,
    reason: input.reason,
    status: executionStatus,
    destination: "wallet",
    walletTransactionId,
    paymentProviderEnabled: isPaymentProviderEnabled(),
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
    walletTransactionId,
  };
}

/**
 * Records a compensation ledger entry, updates aggregate lifecycle to
 * compensated, and appends audit. Caller must run inside an idempotent tx.
 */
export async function issueCompensationRecord(
  input: IssueCompensationRecordInput,
): Promise<IssueCompensationRecordResult> {
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
  const compensationAmount =
    input.amountUsd ??
    (input.booking.amountPaidUsd as number | undefined) ??
    null;
  const walletTransactionId = await maybePostCompensationWalletCredit(
    input,
    compensationRef.id,
    executionStatus,
  );

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
    amountUsd: compensationAmount,
    amount: compensationAmount,
    currency: DEFAULT_WALLET_CURRENCY,
    walletTransactionId,
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
    walletTransactionId,
  };
}

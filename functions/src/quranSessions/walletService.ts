import {
  Firestore,
  Transaction,
  FieldValue,
} from "firebase-admin/firestore";

export const DEFAULT_WALLET_CURRENCY = "EGP";

export const USER_WALLETS_COLLECTION = "user_wallets";
export const WALLET_TRANSACTIONS_COLLECTION = "wallet_transactions";

export type WalletStatus = "active" | "frozen" | "closed";
export type WalletTransactionType =
  | "refund_credit"
  | "compensation_credit"
  | "admin_credit"
  | "promo_credit"
  | "booking_debit"
  | "hold"
  | "hold_release"
  | "admin_reversal"
  | "expiry_debit";
export type WalletTransactionDirection = "credit" | "debit";
export type WalletTransactionStatus =
  | "pending"
  | "posted"
  | "failed"
  | "reversed";
export type WalletSourceType =
  | "refund"
  | "compensation"
  | "booking_payment"
  | "admin_credit"
  | "admin_reversal"
  | "promo";
export type WalletActorRole = "system" | "admin" | "user";

export interface PostWalletCreditInput {
  tx: Transaction;
  db: Firestore;
  userId: string;
  amount: number;
  currency?: string;
  idempotencyKey: string;
  type: WalletTransactionType;
  sourceType: WalletSourceType;
  sourceId?: string | null;
  description: string;
  descriptionAr?: string | null;
  actorId: string;
  actorRole: WalletActorRole;
  metadata?: Record<string, unknown>;
}

export interface PostWalletCreditResult {
  walletId: string;
  transactionId: string;
  balanceAfter: number;
  replayed: boolean;
}

export function walletIdForUser(userId: string): string {
  return `wallet_${userId}`;
}

export function transactionIdFromIdempotencyKey(idempotencyKey: string): string {
  return idempotencyKey.replace(/[/\\.#\[\]]/g, "_").slice(0, 1500);
}

export function refundWalletIdempotencyKey(refundId: string): string {
  return `wallet_credit:refund:${refundId}`;
}

export function compensationWalletIdempotencyKey(compensationId: string): string {
  return `wallet_credit:comp:${compensationId}`;
}

export function adminCreditWalletIdempotencyKey(
  adminId: string,
  clientKey: string,
): string {
  return `admin_credit:${adminId}:${clientKey}`;
}

/**
 * Posts a wallet credit inside an existing Firestore transaction.
 * Duplicate idempotencyKey returns the existing posted transaction.
 */
export async function postWalletCreditInTransaction(
  input: PostWalletCreditInput,
): Promise<PostWalletCreditResult> {
  if (!Number.isFinite(input.amount) || input.amount <= 0) {
    throw new Error("wallet_credit_amount_invalid");
  }

  const currency = input.currency?.trim() || DEFAULT_WALLET_CURRENCY;
  const walletId = walletIdForUser(input.userId);
  const transactionId = transactionIdFromIdempotencyKey(input.idempotencyKey);
  const txnRef = input.db
    .collection(WALLET_TRANSACTIONS_COLLECTION)
    .doc(transactionId);
  const walletRef = input.db.collection(USER_WALLETS_COLLECTION).doc(walletId);

  const existingTxnSnap = await input.tx.get(txnRef);
  if (existingTxnSnap.exists) {
    const existing = existingTxnSnap.data() ?? {};
    if (existing.status === "posted") {
      return {
        walletId,
        transactionId,
        balanceAfter: (existing.balanceAfter as number | undefined) ?? 0,
        replayed: true,
      };
    }
    throw new Error("wallet_transaction_not_posted");
  }

  const walletSnap = await input.tx.get(walletRef);
  const walletData = walletSnap.data() ?? {};
  const availableBalance = walletSnap.exists
    ? Number(walletData.availableBalance ?? 0)
    : 0;
  const heldBalance = walletSnap.exists
    ? Number(walletData.heldBalance ?? 0)
    : 0;
  const balanceAfter = availableBalance + input.amount;
  const now = FieldValue.serverTimestamp();

  if (!walletSnap.exists) {
    input.tx.set(walletRef, {
      walletId,
      userId: input.userId,
      currency,
      status: "active" satisfies WalletStatus,
      availableBalance: balanceAfter,
      heldBalance,
      version: 1,
      createdAt: now,
      updatedAt: now,
      lastTransactionAt: now,
    });
  } else {
    input.tx.update(walletRef, {
      availableBalance: balanceAfter,
      version: (Number(walletData.version ?? 0) || 0) + 1,
      updatedAt: now,
      lastTransactionAt: now,
    });
  }

  input.tx.set(txnRef, {
    transactionId,
    walletId,
    userId: input.userId,
    type: input.type,
    direction: "credit" satisfies WalletTransactionDirection,
    amount: input.amount,
    currency,
    status: "posted" satisfies WalletTransactionStatus,
    balanceAfter,
    idempotencyKey: input.idempotencyKey,
    sourceType: input.sourceType,
    sourceId: input.sourceId ?? null,
    description: input.description,
    descriptionAr: input.descriptionAr ?? null,
    actorId: input.actorId,
    actorRole: input.actorRole,
    metadata: input.metadata ?? {},
    createdAt: now,
    postedAt: now,
    reversalOfTransactionId: null,
  });

  return {
    walletId,
    transactionId,
    balanceAfter,
    replayed: false,
  };
}

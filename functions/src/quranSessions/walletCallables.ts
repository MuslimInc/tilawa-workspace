import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import {
  buildOperationKey,
  runIdempotentOperation,
} from "./idempotencyService";
import {
  adminCreditWalletIdempotencyKey,
  DEFAULT_WALLET_CURRENCY,
  postWalletCreditInTransaction,
  USER_WALLETS_COLLECTION,
  WALLET_TRANSACTIONS_COLLECTION,
  walletIdForUser,
} from "./walletService";
import {
  requireAdmin,
  requireAuthenticatedUid,
  requireValidSessionEpochUnlessAdmin,
} from "./sessionAuth";

interface PostWalletCreditRequest {
  userId: string;
  amount: number;
  currency?: string;
  reason: string;
  idempotencyKey: string;
  descriptionAr?: string;
}

interface GetWalletRequest {
  userId?: string;
  transactionLimit?: number;
}

function serializeTimestamp(value: unknown): string | null {
  if (
    value != null &&
    typeof value === "object" &&
    "toDate" in value &&
    typeof (value as { toDate: () => Date }).toDate === "function"
  ) {
    return (value as { toDate: () => Date }).toDate().toISOString();
  }
  return null;
}

export const getWallet = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const callerUid = requireAuthenticatedUid(request);
    await requireValidSessionEpochUnlessAdmin(request, callerUid);
    const data = (request.data ?? {}) as GetWalletRequest;
    const isAdmin = request.auth?.token?.admin === true;
    const targetUserId = data.userId?.trim() || callerUid;

    if (targetUserId !== callerUid && !isAdmin) {
      throw new HttpsError(
        "permission-denied",
        "Cannot read another user's wallet.",
      );
    }

    const limit = Math.min(Math.max(data.transactionLimit ?? 50, 1), 100);
    const db = getFirestore();
    const walletId = walletIdForUser(targetUserId);
    const walletSnap = await db
      .collection(USER_WALLETS_COLLECTION)
      .doc(walletId)
      .get();

    const transactionsSnap = await db
      .collection(WALLET_TRANSACTIONS_COLLECTION)
      .where("userId", "==", targetUserId)
      .orderBy("createdAt", "desc")
      .limit(limit)
      .get();

    const wallet = walletSnap.exists
      ? {
          ...walletSnap.data(),
          createdAt: serializeTimestamp(walletSnap.data()?.createdAt),
          updatedAt: serializeTimestamp(walletSnap.data()?.updatedAt),
          lastTransactionAt: serializeTimestamp(
            walletSnap.data()?.lastTransactionAt,
          ),
        }
      : null;

    const transactions = transactionsSnap.docs.map((docSnap) => {
      const txn = docSnap.data();
      return {
        ...txn,
        createdAt: serializeTimestamp(txn.createdAt),
        postedAt: serializeTimestamp(txn.postedAt),
      };
    });

    return {
      userId: targetUserId,
      walletId,
      wallet,
      transactions,
    };
  },
);

export const postWalletCredit = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const adminUid = requireAdmin(request);
    const data = request.data as PostWalletCreditRequest;

    if (!data.userId?.trim()) {
      throw new HttpsError("invalid-argument", "userId required.");
    }
    if (!Number.isFinite(data.amount) || data.amount <= 0) {
      throw new HttpsError("invalid-argument", "amount must be positive.");
    }
    if (!data.reason?.trim() || data.reason.trim().length < 20) {
      throw new HttpsError(
        "invalid-argument",
        "reason required (min 20 characters).",
      );
    }
    if (!data.idempotencyKey?.trim()) {
      throw new HttpsError("invalid-argument", "idempotencyKey required.");
    }

    const db = getFirestore();
    const operationKey = buildOperationKey(
      "post_wallet_credit",
      data.userId,
      data.idempotencyKey,
    );
    const walletIdempotencyKey = adminCreditWalletIdempotencyKey(
      adminUid,
      data.idempotencyKey,
    );

    const { result, replayed } = await runIdempotentOperation(
      {
        db,
        operationKey,
        actorId: adminUid,
        action: "post_wallet_credit",
      },
      async (tx) => {
        const credit = await postWalletCreditInTransaction({
          tx,
          db,
          userId: data.userId,
          amount: data.amount,
          currency: data.currency?.trim() || DEFAULT_WALLET_CURRENCY,
          idempotencyKey: walletIdempotencyKey,
          type: "admin_credit",
          sourceType: "admin_credit",
          sourceId: null,
          description: data.reason.trim(),
          descriptionAr: data.descriptionAr?.trim() || null,
          actorId: adminUid,
          actorRole: "admin",
          metadata: { adminReason: data.reason.trim() },
        });

        return {
          userId: data.userId,
          walletId: credit.walletId,
          transactionId: credit.transactionId,
          balanceAfter: credit.balanceAfter,
          walletReplayed: credit.replayed,
        };
      },
    );

    return {
      ...result,
      replayed,
    };
  },
);

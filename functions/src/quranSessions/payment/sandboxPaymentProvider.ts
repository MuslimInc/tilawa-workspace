import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { randomBytes } from "node:crypto";

import type {
  ConfirmPaymentInput,
  ConfirmPaymentResult,
  CreatePaymentIntentInput,
  CreatePaymentIntentResult,
  PaymentProvider,
} from "./types";

export const PAYMENT_INTENTS_COLLECTION = "quran_payment_intents";
export const PAYMENT_TRANSACTIONS_COLLECTION = "quran_payment_transactions";

function sandboxProviderIntentId(bookingId: string): string {
  return `sandbox_pi_${bookingId}`;
}

function sandboxPaymentReference(bookingId: string): string {
  return `sandbox_ref_${bookingId}`;
}

function sandboxClientConfirmToken(bookingId: string): string {
  const nonce = randomBytes(8).toString("hex");
  return `sandbox_confirm_${bookingId}_${nonce}`;
}

export class SandboxPaymentProvider implements PaymentProvider {
  readonly kind = "sandbox" as const;

  async createPaymentIntent(
    input: CreatePaymentIntentInput,
  ): Promise<CreatePaymentIntentResult> {
    const { db, tx, bookingId } = input;
    const paymentIntentId = sandboxProviderIntentId(bookingId);
    const paymentReference = sandboxPaymentReference(bookingId);
    const clientConfirmToken = sandboxClientConfirmToken(bookingId);
    const providerIntentId = paymentIntentId;
    const intentRef = db.collection(PAYMENT_INTENTS_COLLECTION).doc(paymentIntentId);
    const now = FieldValue.serverTimestamp();

    tx.set(intentRef, {
      paymentIntentId,
      bookingId,
      aggregateId: input.aggregateId,
      studentId: input.studentId,
      amount: input.amount,
      currency: input.currency,
      paymentProvider: "sandbox",
      paymentReference,
      providerIntentId,
      clientConfirmToken,
      status: "requires_confirmation",
      platformFee: input.platformFee,
      teacherAmount: input.teacherAmount,
      tax: input.tax,
      idempotencyKey: input.idempotencyKey,
      expiresAt: Timestamp.fromDate(input.expiresAt),
      createdAt: now,
      capturedAt: null,
    });

    return {
      paymentIntentId,
      paymentReference,
      clientConfirmToken,
      providerIntentId,
    };
  }

  async confirmPayment(input: ConfirmPaymentInput): Promise<ConfirmPaymentResult> {
    const intentId = sandboxProviderIntentId(input.bookingId);
    const intentSnap = await input.db
      .collection(PAYMENT_INTENTS_COLLECTION)
      .doc(intentId)
      .get();
    if (!intentSnap.exists) {
      throw new Error("payment_intent_not_found");
    }
    const intent = intentSnap.data() ?? {};
    if (intent.paymentReference !== input.paymentReference) {
      throw new Error("payment_reference_mismatch");
    }
    if (intent.clientConfirmToken !== input.clientConfirmToken) {
      throw new Error("invalid_confirm_token");
    }
    if (intent.studentId !== input.studentId) {
      throw new Error("unauthorized_payment_confirm");
    }
    if (intent.bookingId !== input.bookingId) {
      throw new Error("booking_mismatch");
    }

    if (intent.status === "succeeded") {
      const bookingSnap = await input.db
        .collection("quran_bookings")
        .doc(input.bookingId)
        .get();
      const booking = bookingSnap.data() ?? {};
      return {
        bookingId: input.bookingId,
        sessionId: (booking.sessionId as string) ?? "",
        lifecycleStatus: (booking.lifecycleStatus as string) ?? "scheduled",
        paymentStatus: "captured",
        alreadyConfirmed: true,
      };
    }

    return {
      bookingId: input.bookingId,
      sessionId: "",
      lifecycleStatus: "pending_payment",
      paymentStatus: "pending",
      alreadyConfirmed: false,
    };
  }
}

export function paymentTransactionIdForConfirm(bookingId: string): string {
  return `sandbox_capture_${bookingId}`;
}

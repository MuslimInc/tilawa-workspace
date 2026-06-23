import type { Firestore, Timestamp, Transaction } from "firebase-admin/firestore";

export type PaymentProviderKind = "none" | "sandbox" | "tap" | "stripe";

export type PaymentIntentStatus =
  | "requires_payment_method"
  | "requires_confirmation"
  | "processing"
  | "succeeded"
  | "canceled";

export type BookingPaymentStatus =
  | "not_required"
  | "pending"
  | "authorized"
  | "captured"
  | "partially_refunded"
  | "refunded"
  | "failed"
  | "voided";

export interface BookingPaymentSnapshot {
  pricingType: "free" | "fixedPerSession";
  paymentStatus: BookingPaymentStatus;
  paymentProvider: PaymentProviderKind;
  paymentReference: string;
  providerTransactionId?: string;
  amount: number;
  currency: string;
  platformFee: number;
  teacherAmount: number;
  tax: number;
  capturedAt: Timestamp;
}

export interface CreatePaymentIntentInput {
  db: Firestore;
  tx: Transaction;
  bookingId: string;
  aggregateId: string;
  studentId: string;
  amount: number;
  currency: string;
  platformFee: number;
  teacherAmount: number;
  tax: number;
  idempotencyKey: string;
  expiresAt: Date;
}

export interface CreatePaymentIntentResult {
  paymentIntentId: string;
  paymentReference: string;
  clientConfirmToken: string;
  providerIntentId: string;
}

export interface ConfirmPaymentInput {
  db: Firestore;
  paymentReference: string;
  clientConfirmToken: string;
  bookingId: string;
  studentId: string;
}

export interface ConfirmPaymentResult {
  bookingId: string;
  sessionId: string;
  lifecycleStatus: string;
  paymentStatus: BookingPaymentStatus;
  alreadyConfirmed: boolean;
}

export interface PaymentProvider {
  readonly kind: PaymentProviderKind;
  createPaymentIntent(
    input: CreatePaymentIntentInput,
  ): Promise<CreatePaymentIntentResult>;
  confirmPayment(input: ConfirmPaymentInput): Promise<ConfirmPaymentResult>;
}

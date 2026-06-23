import type {
  ConfirmPaymentInput,
  ConfirmPaymentResult,
  CreatePaymentIntentInput,
  CreatePaymentIntentResult,
  PaymentProvider,
} from "./types";

export class DisabledPaymentProvider implements PaymentProvider {
  readonly kind = "none" as const;

  async createPaymentIntent(
    _input: CreatePaymentIntentInput,
  ): Promise<CreatePaymentIntentResult> {
    throw new Error("payment_provider_unavailable");
  }

  async confirmPayment(
    _input: ConfirmPaymentInput,
  ): Promise<ConfirmPaymentResult> {
    throw new Error("payment_provider_unavailable");
  }
}

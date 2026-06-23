export interface SessionCompensationSummary {
  readonly id: string;
  readonly aggregateId: string;
  readonly bookingId: string;
  readonly type: string;
  readonly status: string;
  readonly policyRuleId: string;
  readonly amountUsd: number | null;
  readonly issuedByActorId: string;
  readonly issuedByRole: string;
  readonly failureReason: string | null;
  readonly createdAt: Date;
  readonly completedAt: Date | null;
}

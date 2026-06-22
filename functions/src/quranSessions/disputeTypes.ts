import { FieldValue } from "firebase-admin/firestore";

export type DisputeStatus =
  | "none"
  | "opened"
  | "under_review"
  | "resolved_favor_student"
  | "resolved_favor_teacher"
  | "resolved_with_compensation"
  | "rejected"
  | "closed";

export interface SessionDisputeRecord {
  disputeId: string;
  aggregateId: string;
  bookingId: string;
  sessionId: string | null;
  status: DisputeStatus;
  reason: string;
  openedByUserId: string;
  openedByRole: string;
  evidenceMetadata?: Record<string, unknown>;
  resolutionReason?: string;
  resolvedByUserId?: string;
  createdAt: FirebaseFirestore.FieldValue;
  updatedAt: FirebaseFirestore.FieldValue;
  resolvedAt?: FirebaseFirestore.FieldValue;
}

export function initialDisputeRecord(input: {
  disputeId: string;
  aggregateId: string;
  bookingId: string;
  sessionId: string | null;
  reason: string;
  openedByUserId: string;
  openedByRole: string;
  evidenceMetadata?: Record<string, unknown>;
}): SessionDisputeRecord {
  return {
    disputeId: input.disputeId,
    aggregateId: input.aggregateId,
    bookingId: input.bookingId,
    sessionId: input.sessionId,
    status: "opened",
    reason: input.reason,
    openedByUserId: input.openedByUserId,
    openedByRole: input.openedByRole,
    evidenceMetadata: input.evidenceMetadata,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

export function disputeStatusForResolution(
  resolution:
    | "favor_student"
    | "favor_teacher"
    | "with_compensation"
    | "rejected"
    | "closed",
): DisputeStatus {
  switch (resolution) {
    case "favor_student":
      return "resolved_favor_student";
    case "favor_teacher":
      return "resolved_favor_teacher";
    case "with_compensation":
      return "resolved_with_compensation";
    case "rejected":
      return "rejected";
    case "closed":
      return "closed";
  }
}

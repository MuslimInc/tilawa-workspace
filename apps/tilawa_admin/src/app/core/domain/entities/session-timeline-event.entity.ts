export interface SessionTimelineEvent {
  readonly id: string;
  readonly aggregateId: string;
  readonly bookingId: string | null;
  readonly sessionId: string | null;
  readonly actorId: string;
  readonly actorRole: string;
  readonly action: string;
  readonly previousStatus: string | null;
  readonly newStatus: string;
  readonly reason: string | null;
  readonly source: string;
  readonly timestamp: Date;
}

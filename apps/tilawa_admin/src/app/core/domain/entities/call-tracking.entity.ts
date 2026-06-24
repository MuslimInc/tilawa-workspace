/**
 * Read-only admin projections of the backend-authoritative call-tracking data.
 *
 * The Cloud Function pre-aggregates per-session telemetry into a single
 * `callTracking/summary` document; admins read that one doc instead of scanning
 * the raw `call_events` log. Raw events are a separate, lazily-paginated read.
 */

/** Aggregated call metrics for one session (one Firestore doc). */
export interface CallTrackingSummary {
  readonly sessionId: string;
  readonly scheduledStartsAt: Date | null;
  readonly firstJoinRole: string | null;
  readonly firstJoinAt: Date | null;
  readonly secondJoinRole: string | null;
  readonly secondJoinAt: Date | null;
  readonly actualCallStartedAt: Date | null;
  readonly callEndedAt: Date | null;
  readonly teacherLate: boolean | null;
  readonly studentLate: boolean | null;
  readonly lateGraceMinutes: number;
  readonly teacherNoShow: boolean;
  readonly studentNoShow: boolean;
  readonly noShowWindowMinutes: number;
  readonly bothParticipantsConnectedSeconds: number;
  readonly reconnectCount: number;
  readonly interruptionCount: number;
  readonly updatedAt: Date | null;
}

/** A single raw call lifecycle event (join/leave/failure/reconnect/…). */
export interface CallEvent {
  readonly id: string;
  readonly eventType: string;
  readonly actorRole: string;
  readonly actorId: string;
  readonly reasonCode: string | null;
  readonly networkQuality: string | null;
  readonly remoteParticipantId: string | null;
  readonly recordedAt: Date | null;
  readonly clientTimestampMs: number | null;
}

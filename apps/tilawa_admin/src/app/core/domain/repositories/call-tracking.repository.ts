import { InjectionToken } from '@angular/core';

import { CallEvent, CallTrackingSummary } from '../entities/call-tracking.entity';
import { PageRequest, PageResult } from '../entities/pagination.types';

/**
 * Read-only access to call-tracking data. No writes — call metrics are
 * backend-authoritative (computed by the Cloud Function).
 */
export interface CallTrackingRepository {
  /** One aggregated doc read; null when no call has been tracked yet. */
  getSummary(sessionId: string): Promise<CallTrackingSummary | null>;

  /**
   * Parallel direct reads of `callTracking/summary` for the given session ids.
   * Skips empty ids; never lists raw events.
   */
  getSummariesBySessionIds(
    sessionIds: readonly string[],
  ): Promise<Map<string, CallTrackingSummary>>;

  /** Bounded, paginated read of raw events ordered by recordedAt desc. */
  listEvents(
    sessionId: string,
    page: PageRequest,
  ): Promise<PageResult<CallEvent>>;
}

export const CALL_TRACKING_REPOSITORY = new InjectionToken<CallTrackingRepository>(
  'CallTrackingRepository',
);

import { Injectable, inject } from '@angular/core';
import {
  Firestore,
  collection,
  doc,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  where,
} from '@angular/fire/firestore';

import { QuranSessionsPaths } from '../paths/quran-sessions.paths';
import { AdminSessionMapper, BookingFirestoreDto } from '../mappers/session-admin.mapper';
import {
  ADMIN_SESSION_DEFAULT_SORT,
  ADMIN_SESSION_SORT_FIELDS,
  AdminSessionFilters,
  AdminSessionSummary,
} from '../../domain/entities/admin-session-summary.entity';
import {
  ACTIVE_SESSION_DEFAULT_SORT,
  ACTIVE_SESSION_PAGE_SIZE,
  ACTIVE_SESSION_SERVER_LIFECYCLE_STATUSES,
  ACTIVE_SESSION_SORT_FIELDS,
  ActiveSessionFilters,
  resolveActiveSessionWindow,
} from '../../domain/entities/active-session.entity';
import { SessionLifecycleStatus } from '../../domain/entities/session-lifecycle-status.enum';
import { DEFAULT_PAGE_SIZE, PageRequest, PageResult } from '../../domain/entities/pagination.types';
import { SessionReadRepository } from '../../domain/repositories/session-read.repository';
import { fetchPaginatedList } from '../firestore/firestore-list-query.util';

@Injectable({ providedIn: 'root' })
export class FirebaseSessionReadRepository implements SessionReadRepository {
  private readonly firestore = inject(Firestore);

  async list(
    filters: AdminSessionFilters,
    page: PageRequest,
  ): Promise<PageResult<AdminSessionSummary>> {
    const pageSize = page.pageSize || DEFAULT_PAGE_SIZE;
    const serverFilters = buildSessionQueryConstraints(filters);

    const result = await fetchPaginatedList({
      firestore: this.firestore,
      collectionPath: QuranSessionsPaths.bookings,
      filters: serverFilters,
      page: { ...page, pageSize },
      defaultSort: ADMIN_SESSION_DEFAULT_SORT,
      allowedSortFields: ADMIN_SESSION_SORT_FIELDS,
      mapDoc: (id, data) => AdminSessionMapper.fromBookingDoc(id, data as BookingFirestoreDto),
    });

    const items = this.applyClientFilters(result.items, filters);
    return { ...result, items };
  }

  async getById(bookingId: string): Promise<AdminSessionSummary | null> {
    const snap = await getDoc(doc(this.firestore, QuranSessionsPaths.bookings, bookingId));
    if (!snap.exists()) {
      return null;
    }
    return AdminSessionMapper.fromBookingDoc(snap.id, snap.data() as BookingFirestoreDto);
  }

  /**
   * Dual-query active sessions: runs two bounded server-side queries in
   * parallel and merges the results.
   *
   * Query A — scheduled-time window: sessions whose `startsAt` falls within
   *   the operational window (now−4h … now+2h). Catches upcoming and
   *   recently-started sessions.
   *
   * Query B — `hasActiveCall == true`: sessions where call telemetry has
   *   denormalized an active-call signal onto the booking doc. Catches early
   *   joins before the scheduled time, regardless of `startsAt`.
   *
   * Both queries are bounded by `limit(pageSize + 1)`. Results are deduped by
   * booking ID and sorted by `startsAt` ascending. No full-collection scan.
   */
  async listActive(
    filters: ActiveSessionFilters,
    page: PageRequest,
  ): Promise<PageResult<AdminSessionSummary>> {
    const pageSize = page.pageSize || ACTIVE_SESSION_PAGE_SIZE;
    const window = resolveActiveSessionWindow(filters.now);
    const windowConstraints = buildActiveSessionQueryConstraints(window);
    const activeCallConstraints = buildActiveCallQueryConstraints();

    const [windowResult, activeCallResult] = await Promise.all([
      fetchPaginatedList({
        firestore: this.firestore,
        collectionPath: QuranSessionsPaths.bookings,
        filters: windowConstraints,
        page: { ...page, pageSize },
        defaultSort: ACTIVE_SESSION_DEFAULT_SORT,
        allowedSortFields: ACTIVE_SESSION_SORT_FIELDS,
        mapDoc: (id, data) => AdminSessionMapper.fromBookingDoc(id, data as BookingFirestoreDto),
      }),
      fetchPaginatedList({
        firestore: this.firestore,
        collectionPath: QuranSessionsPaths.bookings,
        filters: activeCallConstraints,
        page: { ...page, pageSize },
        defaultSort: ACTIVE_SESSION_DEFAULT_SORT,
        allowedSortFields: ACTIVE_SESSION_SORT_FIELDS,
        mapDoc: (id, data) => AdminSessionMapper.fromBookingDoc(id, data as BookingFirestoreDto),
      }),
    ]);

    const merged = mergeActiveSessions(windowResult.items, activeCallResult.items);
    const pageItems = merged.slice(0, pageSize);
    const hasMore = merged.length > pageSize || windowResult.hasMore || activeCallResult.hasMore;

    return {
      items: pageItems,
      nextCursor: hasMore && pageItems.length > 0 ? pageItems[pageItems.length - 1].id : null,
      hasMore,
    };
  }

  private applyClientFilters(
    items: readonly AdminSessionSummary[],
    filters: AdminSessionFilters,
  ): AdminSessionSummary[] {
    const search = filters.search?.trim().toLowerCase();
    if (!search) {
      return [...items];
    }

    return items.filter(
      (item) =>
        item.id.toLowerCase().includes(search) ||
        item.studentId.toLowerCase().includes(search) ||
        item.teacherId.toLowerCase().includes(search) ||
        (item.sessionId?.toLowerCase().includes(search) ?? false) ||
        item.slotId.toLowerCase().includes(search),
    );
  }
}

/**
 * Merge two bounded result sets, deduping by booking ID. Sessions from the
 * active-call query take precedence (their call tracking is live). The merged
 * list is sorted by `startsAt` ascending to match the default active-sessions
 * sort order.
 */
function mergeActiveSessions(
  windowItems: readonly AdminSessionSummary[],
  activeCallItems: readonly AdminSessionSummary[],
): AdminSessionSummary[] {
  const seen = new Set<string>();
  const merged: AdminSessionSummary[] = [];

  // Active-call sessions first (they are the most operationally relevant).
  for (const item of activeCallItems) {
    if (!seen.has(item.id)) {
      seen.add(item.id);
      merged.push(item);
    }
  }

  for (const item of windowItems) {
    if (!seen.has(item.id)) {
      seen.add(item.id);
      merged.push(item);
    }
  }

  merged.sort((a, b) => a.startsAt.getTime() - b.startsAt.getTime());
  return merged;
}

/**
 * Server-side query constraints for the admin sessions list. Exported for
 * query-contract tests so the filter→Firestore mapping can be verified without
 * a Firestore instance. Text `search` is intentionally NOT pushed here —
 * Firestore has no full-text search, so it is applied to the current page only.
 */
export function buildSessionQueryConstraints(
  filters: AdminSessionFilters,
): ReturnType<typeof where>[] {
  const constraints: ReturnType<typeof where>[] = [];

  if (filters.status && filters.status !== SessionLifecycleStatus.Unknown) {
    constraints.push(where('lifecycleStatus', '==', filters.status));
  }

  if (filters.countryCode?.trim()) {
    constraints.push(where('countryCode', '==', filters.countryCode.trim()));
  }

  if (filters.cityId?.trim()) {
    constraints.push(where('cityId', '==', filters.cityId.trim()));
  }

  if (filters.teacherId?.trim()) {
    constraints.push(where('teacherId', '==', filters.teacherId.trim()));
  }

  if (filters.studentId?.trim()) {
    constraints.push(where('studentId', '==', filters.studentId.trim()));
  }

  if (filters.startsFrom) {
    constraints.push(where('startsAt', '>=', filters.startsFrom));
  }

  if (filters.startsTo) {
    constraints.push(where('startsAt', '<=', filters.startsTo));
  }

  return constraints;
}

/** Exported for query-contract tests — server-side active window only. */
export function buildActiveSessionQueryConstraints(
  window: ReturnType<typeof resolveActiveSessionWindow>,
): ReturnType<typeof where>[] {
  return [
    where('lifecycleStatus', 'in', [...ACTIVE_SESSION_SERVER_LIFECYCLE_STATUSES]),
    where('startsAt', '>=', window.startsFrom),
    where('startsAt', '<=', window.startsTo),
  ];
}

/**
 * Server-side query constraints for sessions with an active call signal
 * denormalized by the call telemetry Cloud Function. Catches early joins and
 * live sessions regardless of the scheduled `startsAt` time. Exported for
 * query-contract tests.
 */
export function buildActiveCallQueryConstraints(): ReturnType<typeof where>[] {
  return [where('hasActiveCall', '==', true)];
}

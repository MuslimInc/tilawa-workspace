import { Injectable, inject } from '@angular/core';
import {
  Firestore,
  doc,
  getDoc,
  where,
} from '@angular/fire/firestore';

import { QuranSessionsPaths } from '../paths/quran-sessions.paths';
import {
  AdminSessionMapper,
  BookingFirestoreDto,
} from '../mappers/session-admin.mapper';
import {
  ADMIN_SESSION_DEFAULT_SORT,
  ADMIN_SESSION_SORT_FIELDS,
  AdminSessionFilters,
  AdminSessionSummary,
} from '../../domain/entities/admin-session-summary.entity';
import { SessionLifecycleStatus } from '../../domain/entities/session-lifecycle-status.enum';
import {
  DEFAULT_PAGE_SIZE,
  PageRequest,
  PageResult,
} from '../../domain/entities/pagination.types';
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
    const serverFilters = this.buildQueryConstraints(filters);

    const result = await fetchPaginatedList({
      firestore: this.firestore,
      collectionPath: QuranSessionsPaths.bookings,
      filters: serverFilters,
      page: { ...page, pageSize },
      defaultSort: ADMIN_SESSION_DEFAULT_SORT,
      allowedSortFields: ADMIN_SESSION_SORT_FIELDS,
      mapDoc: (id, data) =>
        AdminSessionMapper.fromBookingDoc(id, data as BookingFirestoreDto),
    });

    const items = this.applyClientFilters(result.items, filters);
    return { ...result, items };
  }

  async getById(bookingId: string): Promise<AdminSessionSummary | null> {
    const snap = await getDoc(
      doc(this.firestore, QuranSessionsPaths.bookings, bookingId),
    );
    if (!snap.exists()) {
      return null;
    }
    return AdminSessionMapper.fromBookingDoc(
      snap.id,
      snap.data() as BookingFirestoreDto,
    );
  }

  private buildQueryConstraints(filters: AdminSessionFilters) {
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

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
  startAfter,
  where,
} from '@angular/fire/firestore';

import { QuranSessionsPaths } from '../paths/quran-sessions.paths';
import {
  AdminSessionMapper,
  BookingFirestoreDto,
} from '../mappers/session-admin.mapper';
import {
  AdminSessionFilters,
  AdminSessionSummary,
} from '../../domain/entities/admin-session-summary.entity';
import { SessionLifecycleStatus } from '../../domain/entities/session-lifecycle-status.enum';
import { PageRequest, PageResult } from '../../domain/entities/pagination.types';
import { SessionReadRepository } from '../../domain/repositories/session-read.repository';

const DEFAULT_PAGE_SIZE = 25;

@Injectable({ providedIn: 'root' })
export class FirebaseSessionReadRepository implements SessionReadRepository {
  private readonly firestore = inject(Firestore);

  async list(
    filters: AdminSessionFilters,
    page: PageRequest,
  ): Promise<PageResult<AdminSessionSummary>> {
    const pageSize = page.pageSize || DEFAULT_PAGE_SIZE;
    const constraints = this.buildQueryConstraints(filters);

    let q = query(
      collection(this.firestore, QuranSessionsPaths.bookings),
      ...constraints,
      orderBy('startsAt', 'desc'),
      limit(pageSize + 1),
    );

    if (page.cursor) {
      const cursorDoc = await getDoc(
        doc(this.firestore, QuranSessionsPaths.bookings, page.cursor),
      );
      if (cursorDoc.exists()) {
        q = query(q, startAfter(cursorDoc));
      }
    }

    const snapshot = await getDocs(q);
    const docs = snapshot.docs;
    const hasMore = docs.length > pageSize;
    const pageDocs = hasMore ? docs.slice(0, pageSize) : docs;

    let items = pageDocs.map((snap) =>
      AdminSessionMapper.fromBookingDoc(
        snap.id,
        snap.data() as BookingFirestoreDto,
      ),
    );

    items = this.applyClientFilters(items, filters);

    const nextCursor =
      hasMore && pageDocs.length > 0 ? pageDocs[pageDocs.length - 1].id : null;

    return { items, nextCursor, hasMore };
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
    const constraints: Parameters<typeof query>[1][] = [];

    if (filters.status && filters.status !== SessionLifecycleStatus.Unknown) {
      constraints.push(where('lifecycleStatus', '==', filters.status));
    }

    if (filters.countryCode?.trim()) {
      constraints.push(where('countryCode', '==', filters.countryCode.trim()));
    }

    if (filters.cityId?.trim()) {
      constraints.push(where('cityId', '==', filters.cityId.trim()));
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
    items: AdminSessionSummary[],
    filters: AdminSessionFilters,
  ): AdminSessionSummary[] {
    let filtered = items;

    const teacherId = filters.teacherId?.trim();
    if (teacherId) {
      filtered = filtered.filter((item) => item.teacherId === teacherId);
    }

    const studentId = filters.studentId?.trim();
    if (studentId) {
      filtered = filtered.filter((item) => item.studentId === studentId);
    }

    const search = filters.search?.trim().toLowerCase();
    if (search) {
      filtered = filtered.filter(
        (item) =>
          item.id.toLowerCase().includes(search) ||
          item.studentId.toLowerCase().includes(search) ||
          item.teacherId.toLowerCase().includes(search) ||
          (item.sessionId?.toLowerCase().includes(search) ?? false) ||
          item.slotId.toLowerCase().includes(search),
      );
    }

    return filtered;
  }
}

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
  SessionReportFirestoreDto,
  SessionReportMapper,
} from '../mappers/session-report.mapper';
import {
  SessionReportFilters,
  SessionReportSummary,
} from '../../domain/entities/session-report-summary.entity';
import { PageRequest, PageResult } from '../../domain/entities/pagination.types';
import { SessionReportReadRepository } from '../../domain/repositories/session-report-read.repository';

const DEFAULT_PAGE_SIZE = 25;

@Injectable({ providedIn: 'root' })
export class FirebaseSessionReportReadRepository
  implements SessionReportReadRepository
{
  private readonly firestore = inject(Firestore);

  async list(
    filters: SessionReportFilters,
    page: PageRequest,
  ): Promise<PageResult<SessionReportSummary>> {
    const pageSize = page.pageSize || DEFAULT_PAGE_SIZE;
    const constraints = this.buildQueryConstraints(filters);

    let q = query(
      collection(this.firestore, QuranSessionsPaths.sessionReports),
      ...constraints,
      orderBy('createdAt', 'desc'),
      limit(pageSize + 1),
    );

    if (page.cursor) {
      const cursorDoc = await getDoc(
        doc(this.firestore, QuranSessionsPaths.sessionReports, page.cursor),
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
      SessionReportMapper.fromFirestore(
        snap.id,
        snap.data() as SessionReportFirestoreDto,
      ),
    );

    items = this.applyClientFilters(items, filters);

    const nextCursor =
      hasMore && pageDocs.length > 0 ? pageDocs[pageDocs.length - 1].id : null;

    return { items, nextCursor, hasMore };
  }

  async getById(reportId: string): Promise<SessionReportSummary | null> {
    const snap = await getDoc(
      doc(this.firestore, QuranSessionsPaths.sessionReports, reportId),
    );
    if (!snap.exists()) {
      return null;
    }
    return SessionReportMapper.fromFirestore(
      snap.id,
      snap.data() as SessionReportFirestoreDto,
    );
  }

  private buildQueryConstraints(filters: SessionReportFilters) {
    const constraints: Parameters<typeof query>[1][] = [];

    if (filters.status) {
      constraints.push(where('status', '==', filters.status));
    }

    if (filters.severity) {
      constraints.push(where('severity', '==', filters.severity));
    }

    if (filters.category?.trim()) {
      constraints.push(where('category', '==', filters.category.trim()));
    }

    return constraints;
  }

  private applyClientFilters(
    items: SessionReportSummary[],
    filters: SessionReportFilters,
  ): SessionReportSummary[] {
    const search = filters.search?.trim().toLowerCase();
    if (!search) {
      return items;
    }

    return items.filter(
      (item) =>
        item.id.toLowerCase().includes(search) ||
        item.description.toLowerCase().includes(search) ||
        item.reporterUserId.toLowerCase().includes(search) ||
        (item.reportedUserId?.toLowerCase().includes(search) ?? false) ||
        (item.bookingId?.toLowerCase().includes(search) ?? false),
    );
  }
}

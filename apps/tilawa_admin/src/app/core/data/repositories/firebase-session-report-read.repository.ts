import { Injectable, inject } from '@angular/core';
import { Firestore, doc, getDoc, where } from '@angular/fire/firestore';

import { QuranSessionsPaths } from '../paths/quran-sessions.paths';
import {
  SessionReportFirestoreDto,
  SessionReportMapper,
} from '../mappers/session-report.mapper';
import {
  SESSION_REPORT_DEFAULT_SORT,
  SESSION_REPORT_SORT_FIELDS,
  SessionReportFilters,
  SessionReportSummary,
} from '../../domain/entities/session-report-summary.entity';
import {
  DEFAULT_PAGE_SIZE,
  PageRequest,
  PageResult,
} from '../../domain/entities/pagination.types';
import { SessionReportReadRepository } from '../../domain/repositories/session-report-read.repository';
import { fetchPaginatedList } from '../firestore/firestore-list-query.util';

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
    const serverFilters = this.buildQueryConstraints(filters);

    const result = await fetchPaginatedList({
      firestore: this.firestore,
      collectionPath: QuranSessionsPaths.sessionReports,
      filters: serverFilters,
      page: { ...page, pageSize },
      defaultSort: SESSION_REPORT_DEFAULT_SORT,
      allowedSortFields: SESSION_REPORT_SORT_FIELDS,
      mapDoc: (id, data) =>
        SessionReportMapper.fromFirestore(
          id,
          data as SessionReportFirestoreDto,
        ),
    });

    const items = this.applyClientFilters(result.items, filters);
    return { ...result, items };
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
    const constraints: ReturnType<typeof where>[] = [];

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
    items: readonly SessionReportSummary[],
    filters: SessionReportFilters,
  ): SessionReportSummary[] {
    const search = filters.search?.trim().toLowerCase();
    if (!search) {
      return [...items];
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

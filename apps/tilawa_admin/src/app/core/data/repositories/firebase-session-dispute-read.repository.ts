import { Injectable, inject } from '@angular/core';
import { Firestore, doc, getDoc, where } from '@angular/fire/firestore';

import { QuranSessionsPaths } from '../paths/quran-sessions.paths';
import {
  SessionDisputeFirestoreDto,
  SessionDisputeMapper,
} from '../mappers/session-dispute.mapper';
import {
  SESSION_DISPUTE_DEFAULT_SORT,
  SESSION_DISPUTE_SORT_FIELDS,
  SessionDisputeFilters,
  SessionDisputeSummary,
} from '../../domain/entities/session-dispute-summary.entity';
import {
  DEFAULT_PAGE_SIZE,
  PageRequest,
  PageResult,
} from '../../domain/entities/pagination.types';
import { SessionDisputeReadRepository } from '../../domain/repositories/session-dispute-read.repository';
import { fetchPaginatedList } from '../firestore/firestore-list-query.util';

@Injectable({ providedIn: 'root' })
export class FirebaseSessionDisputeReadRepository
  implements SessionDisputeReadRepository
{
  private readonly firestore = inject(Firestore);

  async list(
    filters: SessionDisputeFilters,
    page: PageRequest,
  ): Promise<PageResult<SessionDisputeSummary>> {
    const pageSize = page.pageSize || DEFAULT_PAGE_SIZE;
    const serverFilters = this.buildQueryConstraints(filters);

    const result = await fetchPaginatedList({
      firestore: this.firestore,
      collectionPath: QuranSessionsPaths.sessionDisputes,
      filters: serverFilters,
      page: { ...page, pageSize },
      defaultSort: SESSION_DISPUTE_DEFAULT_SORT,
      allowedSortFields: SESSION_DISPUTE_SORT_FIELDS,
      mapDoc: (id, data) =>
        SessionDisputeMapper.fromFirestore(
          id,
          data as SessionDisputeFirestoreDto,
        ),
    });

    const items = this.applyClientFilters(result.items, filters);
    return { ...result, items };
  }

  async getById(disputeId: string): Promise<SessionDisputeSummary | null> {
    const snap = await getDoc(
      doc(this.firestore, QuranSessionsPaths.sessionDisputes, disputeId),
    );
    if (!snap.exists()) {
      return null;
    }
    return SessionDisputeMapper.fromFirestore(
      snap.id,
      snap.data() as SessionDisputeFirestoreDto,
    );
  }

  private buildQueryConstraints(filters: SessionDisputeFilters) {
    const constraints: ReturnType<typeof where>[] = [];

    if (filters.status) {
      constraints.push(where('status', '==', filters.status));
    }

    return constraints;
  }

  private applyClientFilters(
    items: readonly SessionDisputeSummary[],
    filters: SessionDisputeFilters,
  ): SessionDisputeSummary[] {
    const search = filters.search?.trim().toLowerCase();
    if (!search) {
      return [...items];
    }

    return items.filter(
      (item) =>
        item.id.toLowerCase().includes(search) ||
        item.reason.toLowerCase().includes(search) ||
        item.openedByUserId.toLowerCase().includes(search) ||
        item.bookingId.toLowerCase().includes(search) ||
        (item.sessionId?.toLowerCase().includes(search) ?? false),
    );
  }
}

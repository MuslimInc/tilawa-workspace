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
  SessionDisputeFirestoreDto,
  SessionDisputeMapper,
} from '../mappers/session-dispute.mapper';
import {
  SessionDisputeFilters,
  SessionDisputeSummary,
} from '../../domain/entities/session-dispute-summary.entity';
import { PageRequest, PageResult } from '../../domain/entities/pagination.types';
import { SessionDisputeReadRepository } from '../../domain/repositories/session-dispute-read.repository';

const DEFAULT_PAGE_SIZE = 25;

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
    const constraints = this.buildQueryConstraints(filters);

    let q = query(
      collection(this.firestore, QuranSessionsPaths.sessionDisputes),
      ...constraints,
      orderBy('createdAt', 'desc'),
      limit(pageSize + 1),
    );

    if (page.cursor) {
      const cursorDoc = await getDoc(
        doc(this.firestore, QuranSessionsPaths.sessionDisputes, page.cursor),
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
      SessionDisputeMapper.fromFirestore(
        snap.id,
        snap.data() as SessionDisputeFirestoreDto,
      ),
    );

    items = this.applyClientFilters(items, filters);

    const nextCursor =
      hasMore && pageDocs.length > 0 ? pageDocs[pageDocs.length - 1].id : null;

    return { items, nextCursor, hasMore };
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
    const constraints: Parameters<typeof query>[1][] = [];

    if (filters.status) {
      constraints.push(where('status', '==', filters.status));
    }

    return constraints;
  }

  private applyClientFilters(
    items: SessionDisputeSummary[],
    filters: SessionDisputeFilters,
  ): SessionDisputeSummary[] {
    const search = filters.search?.trim().toLowerCase();
    if (!search) {
      return items;
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

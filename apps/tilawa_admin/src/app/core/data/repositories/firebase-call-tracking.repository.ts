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
} from '@angular/fire/firestore';

import { QuranSessionsPaths } from '../paths/quran-sessions.paths';
import {
  CallEventFirestoreDto,
  CallTrackingMapper,
  CallTrackingSummaryFirestoreDto,
} from '../mappers/call-tracking.mapper';
import { CallEvent, CallTrackingSummary } from '../../domain/entities/call-tracking.entity';
import { PageRequest, PageResult } from '../../domain/entities/pagination.types';
import { CallTrackingRepository } from '../../domain/repositories/call-tracking.repository';

const CALL_TRACKING_SUBCOLLECTION = 'callTracking';
const CALL_TRACKING_SUMMARY_DOC = 'summary';
const CALL_EVENTS_SUBCOLLECTION = 'call_events';
const DEFAULT_EVENTS_PAGE_SIZE = 20;

@Injectable({ providedIn: 'root' })
export class FirebaseCallTrackingRepository implements CallTrackingRepository {
  private readonly firestore = inject(Firestore);

  async getSummary(sessionId: string): Promise<CallTrackingSummary | null> {
    // Single aggregated doc read — never scans the raw events collection.
    const ref = doc(
      this.firestore,
      QuranSessionsPaths.sessions,
      sessionId,
      CALL_TRACKING_SUBCOLLECTION,
      CALL_TRACKING_SUMMARY_DOC,
    );
    const snap = await getDoc(ref);
    if (!snap.exists()) {
      return null;
    }
    return CallTrackingMapper.summaryFromFirestore(
      sessionId,
      snap.data() as CallTrackingSummaryFirestoreDto,
    );
  }

  async getSummariesBySessionIds(
    sessionIds: readonly string[],
  ): Promise<Map<string, CallTrackingSummary>> {
    const uniqueIds = [...new Set(sessionIds.filter((id) => id.trim().length > 0))];
    const result = new Map<string, CallTrackingSummary>();

    await Promise.all(
      uniqueIds.map(async (sessionId) => {
        const summary = await this.getSummary(sessionId);
        if (summary) {
          result.set(sessionId, summary);
        }
      }),
    );

    return result;
  }

  async listEvents(sessionId: string, page: PageRequest): Promise<PageResult<CallEvent>> {
    const pageSize = page.pageSize || DEFAULT_EVENTS_PAGE_SIZE;
    const eventsCollection = collection(
      this.firestore,
      QuranSessionsPaths.sessions,
      sessionId,
      CALL_EVENTS_SUBCOLLECTION,
    );

    // Bounded query: newest-first, single-field order (auto-indexed),
    // limit(pageSize + 1) to detect hasMore without a count read.
    let q = query(eventsCollection, orderBy('recordedAt', 'desc'), limit(pageSize + 1));

    if (page.cursor) {
      const cursorDoc = await getDoc(
        doc(
          this.firestore,
          QuranSessionsPaths.sessions,
          sessionId,
          CALL_EVENTS_SUBCOLLECTION,
          page.cursor,
        ),
      );
      if (cursorDoc.exists()) {
        q = query(q, startAfter(cursorDoc));
      }
    }

    const snapshot = await getDocs(q);
    const docs = snapshot.docs;
    const hasMore = docs.length > pageSize;
    const pageDocs = hasMore ? docs.slice(0, pageSize) : docs;

    const items = pageDocs.map((snap) =>
      CallTrackingMapper.eventFromFirestore(snap.id, snap.data() as CallEventFirestoreDto),
    );

    const nextCursor = hasMore && pageDocs.length > 0 ? pageDocs[pageDocs.length - 1].id : null;

    return { items, nextCursor, hasMore };
  }
}

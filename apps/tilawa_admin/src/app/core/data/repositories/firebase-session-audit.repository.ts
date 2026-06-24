import { Injectable, inject } from '@angular/core';
import {
  Firestore,
  collection,
  getDocs,
  orderBy,
  query,
  where,
} from '@angular/fire/firestore';

import { QuranSessionsPaths } from '../paths/quran-sessions.paths';
import {
  CompensationFirestoreDto,
  SessionCompensationMapper,
  SessionEventFirestoreDto,
  SessionTimelineMapper,
} from '../mappers/session-admin.mapper';
import { SessionCompensationSummary } from '../../domain/entities/session-compensation-summary.entity';
import { SessionTimelineEvent } from '../../domain/entities/session-timeline-event.entity';
import { SessionAuditRepository } from '../../domain/repositories/session-audit.repository';

@Injectable({ providedIn: 'root' })
export class FirebaseSessionAuditRepository implements SessionAuditRepository {
  private readonly firestore = inject(Firestore);

  async listTimelineByAggregateId(
    aggregateId: string,
  ): Promise<readonly SessionTimelineEvent[]> {
    const snapshot = await getDocs(
      query(
        collection(this.firestore, QuranSessionsPaths.sessionEvents),
        where('aggregateId', '==', aggregateId),
        orderBy('timestamp', 'asc'),
      ),
    );

    return snapshot.docs.map((docSnap) =>
      SessionTimelineMapper.fromFirestore(
        docSnap.id,
        docSnap.data() as SessionEventFirestoreDto,
      ),
    );
  }

  async listCompensationsByBookingId(
    bookingId: string,
  ): Promise<readonly SessionCompensationSummary[]> {
    const snapshot = await getDocs(
      query(
        collection(this.firestore, QuranSessionsPaths.sessionCompensations),
        where('bookingId', '==', bookingId),
        orderBy('createdAt', 'desc'),
      ),
    );

    return snapshot.docs.map((docSnap) =>
      SessionCompensationMapper.fromFirestore(
        docSnap.id,
        docSnap.data() as CompensationFirestoreDto,
      ),
    );
  }
}

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
  QuranSessionsUserMapper,
  TilawaUserFirestoreDto,
} from '../mappers/quran-sessions.mapper';
import {
  QuranSessionsUser,
  QuranSessionsUserFilters,
} from '../../domain/entities/quran-sessions-user.entity';
import { PageRequest, PageResult } from '../../domain/entities/pagination.types';
import { QuranSessionsUserRepository } from '../../domain/repositories/quran-sessions-user.repository';

const DEFAULT_PAGE_SIZE = 25;
const SCAN_BATCH = 50;

@Injectable({ providedIn: 'root' })
export class FirebaseQuranSessionsUserRepository implements QuranSessionsUserRepository {
  private readonly firestore = inject(Firestore);

  async list(
    filters: QuranSessionsUserFilters,
    page: PageRequest,
  ): Promise<PageResult<QuranSessionsUser>> {
    const pageSize = page.pageSize || DEFAULT_PAGE_SIZE;

    let q = query(
      collection(this.firestore, QuranSessionsPaths.users),
      limit(SCAN_BATCH),
    );

    if (page.cursor) {
      const cursorDoc = await getDoc(
        doc(this.firestore, QuranSessionsPaths.users, page.cursor),
      );
      if (cursorDoc.exists()) {
        q = query(q, startAfter(cursorDoc));
      }
    }

    const snapshot = await getDocs(q);
    const mapped = snapshot.docs
      .map((snap) =>
        QuranSessionsUserMapper.fromUserDoc(
          snap.id,
          snap.data() as TilawaUserFirestoreDto,
        ),
      )
      .filter((user): user is QuranSessionsUser => user != null);

    let filtered = this.applyFilters(mapped, filters);
    const items = filtered.slice(0, pageSize);
    const hasMore = filtered.length > pageSize || snapshot.docs.length === SCAN_BATCH;
    const nextCursor =
      snapshot.docs.length > 0
        ? snapshot.docs[snapshot.docs.length - 1].id
        : null;

    return { items, nextCursor, hasMore };
  }

  async getById(userId: string): Promise<QuranSessionsUser | null> {
    const snap = await getDoc(doc(this.firestore, QuranSessionsPaths.users, userId));
    if (!snap.exists()) {
      return null;
    }
    return QuranSessionsUserMapper.fromUserDoc(
      snap.id,
      snap.data() as TilawaUserFirestoreDto,
    );
  }

  async getByIds(
    userIds: readonly string[],
  ): Promise<Map<string, QuranSessionsUser>> {
    const uniqueIds = [...new Set(userIds)];
    const result = new Map<string, QuranSessionsUser>();

    await Promise.all(
      uniqueIds.map(async (userId) => {
        const user = await this.getById(userId);
        if (user) {
          result.set(userId, user);
        }
      }),
    );

    return result;
  }

  private applyFilters(
    users: QuranSessionsUser[],
    filters: QuranSessionsUserFilters,
  ): QuranSessionsUser[] {
    return users.filter((user) => {
      if (filters.countryCode && user.countryCode !== filters.countryCode) {
        return false;
      }
      if (filters.cityId && user.cityId !== filters.cityId) {
        return false;
      }
      if (filters.gender && user.gender !== filters.gender) {
        return false;
      }
      if (
        filters.profileCompleted != null &&
        user.profileCompleted !== filters.profileCompleted
      ) {
        return false;
      }
      if (filters.accountStatus && user.accountStatus !== filters.accountStatus) {
        return false;
      }

      const search = filters.search?.trim().toLowerCase();
      if (search) {
        const haystack = [
          user.displayName,
          user.email,
          user.userId,
        ]
          .filter(Boolean)
          .join(' ')
          .toLowerCase();
        if (!haystack.includes(search)) {
          return false;
        }
      }

      return true;
    });
  }
}

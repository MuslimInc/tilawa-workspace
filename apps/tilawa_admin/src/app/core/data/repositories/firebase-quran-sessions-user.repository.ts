import { Injectable, inject } from '@angular/core';
import {
  Firestore,
  collection,
  doc,
  getDoc,
  getDocs,
  limit,
  query,
  where,
} from '@angular/fire/firestore';

import { QuranSessionsPaths } from '../paths/quran-sessions.paths';
import { QuranSessionsUserMapper, TilawaUserFirestoreDto } from '../mappers/quran-sessions.mapper';
import {
  QS_USER_DEFAULT_SORT,
  QS_USER_SORT_FIELDS,
  QuranSessionsUser,
  QuranSessionsUserFilters,
} from '../../domain/entities/quran-sessions-user.entity';
import { DEFAULT_PAGE_SIZE, PageRequest, PageResult } from '../../domain/entities/pagination.types';
import {
  QS_USER_ID_IN_QUERY_LIMIT,
  QuranSessionsUserRepository,
} from '../../domain/repositories/quran-sessions-user.repository';
import { fetchPaginatedList } from '../firestore/firestore-list-query.util';

const QS_PROFILE = QuranSessionsPaths.quranSessionsProfileField;
const QS_UPDATED_AT = `${QS_PROFILE}.updatedAt`;
const QS_CREATED_AT = `${QS_PROFILE}.createdAt`;

@Injectable({ providedIn: 'root' })
export class FirebaseQuranSessionsUserRepository implements QuranSessionsUserRepository {
  private readonly firestore = inject(Firestore);

  async list(
    filters: QuranSessionsUserFilters,
    page: PageRequest,
  ): Promise<PageResult<QuranSessionsUser>> {
    const pageSize = page.pageSize || DEFAULT_PAGE_SIZE;
    const serverFilters = buildQuranSessionsUserServerFilters(filters);

    const result = await fetchPaginatedList<QuranSessionsUser | null>({
      firestore: this.firestore,
      collectionPath: QuranSessionsPaths.users,
      filters: serverFilters,
      page: { ...page, pageSize },
      defaultSort: QS_USER_DEFAULT_SORT,
      allowedSortFields: QS_USER_SORT_FIELDS,
      mapDoc: (id, data) => QuranSessionsUserMapper.fromUserDoc(id, data as TilawaUserFirestoreDto),
    });

    const items = result.items
      .filter((user): user is QuranSessionsUser => user != null)
      .filter((user) => this.matchesSearch(user, filters));

    return { ...result, items };
  }

  async listMatchingUserIds(
    filters: Pick<QuranSessionsUserFilters, 'countryCode' | 'cityId'>,
    maxIds = QS_USER_ID_IN_QUERY_LIMIT,
  ): Promise<readonly string[]> {
    const serverFilters = buildQuranSessionsUserServerFilters({
      ...filters,
      accountStatus: null,
      gender: null,
      profileCompleted: null,
      search: null,
    });

    if (serverFilters.length === 0) {
      return [];
    }

    const snapshot = await getDocs(
      query(collection(this.firestore, QuranSessionsPaths.users), ...serverFilters, limit(maxIds)),
    );

    return snapshot.docs.map((snap) => snap.id);
  }

  async getById(userId: string): Promise<QuranSessionsUser | null> {
    const snap = await getDoc(doc(this.firestore, QuranSessionsPaths.users, userId));
    if (!snap.exists()) {
      return null;
    }
    return QuranSessionsUserMapper.fromUserDoc(snap.id, snap.data() as TilawaUserFirestoreDto);
  }

  async getByIds(userIds: readonly string[]): Promise<Map<string, QuranSessionsUser>> {
    const uniqueIds = [...new Set(userIds.filter((id) => id.trim().length > 0))];
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

  private matchesSearch(user: QuranSessionsUser, filters: QuranSessionsUserFilters): boolean {
    const search = filters.search?.trim().toLowerCase();
    if (!search) {
      return true;
    }

    const haystack = [user.displayName, user.email, user.userId]
      .filter(Boolean)
      .join(' ')
      .toLowerCase();
    return haystack.includes(search);
  }
}

/**
 * Server-side query constraints for the QS users slice (nested
 * `quranSessionsProfile.*` fields). Exported for query-contract tests so the
 * filter→Firestore mapping can be verified without a Firestore instance.
 * `search` is intentionally NOT pushed here (client-side, current page only).
 */
export function buildQuranSessionsUserServerFilters(
  filters: QuranSessionsUserFilters,
): ReturnType<typeof where>[] {
  const constraints: ReturnType<typeof where>[] = [];

  if (filters.accountStatus) {
    constraints.push(where(`${QS_PROFILE}.accountStatus`, '==', filters.accountStatus));
  }

  if (filters.gender) {
    constraints.push(where(`${QS_PROFILE}.gender`, '==', filters.gender));
  }

  if (filters.countryCode) {
    constraints.push(where(`${QS_PROFILE}.countryCode`, '==', filters.countryCode));
  }

  if (filters.cityId) {
    constraints.push(where(`${QS_PROFILE}.cityId`, '==', filters.cityId));
  }

  if (filters.profileCompleted != null) {
    constraints.push(where(`${QS_PROFILE}.profileCompleted`, '==', filters.profileCompleted));
  }

  return constraints;
}

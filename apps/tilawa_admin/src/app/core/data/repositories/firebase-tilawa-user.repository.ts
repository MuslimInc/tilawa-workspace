import { Injectable, inject } from '@angular/core';
import {
  Firestore,
  collection,
  collectionCount,
  query,
  getDocs,
  where,
  limit,
} from '@angular/fire/firestore';
import { firstValueFrom } from 'rxjs';

import { QuranSessionsPaths } from '../paths/quran-sessions.paths';
import { readTimestamp } from '../mappers/quran-sessions.mapper';
import {
  TILAWA_USER_DEFAULT_SORT,
  TILAWA_USER_SORT_FIELDS,
  TilawaUser,
  TilawaUserFilters,
} from '../../domain/entities/tilawa-user.entity';
import {
  DEFAULT_PAGE_SIZE,
  PageRequest,
  PageResult,
} from '../../domain/entities/pagination.types';
import { TilawaUserRepository } from '../../domain/repositories/tilawa-user.repository';
import { fetchPaginatedList } from '../firestore/firestore-list-query.util';

interface TilawaUserFirestoreDto {
  email?: string;
  displayName?: string;
  photoUrl?: string;
  name?: string;
  createdAt?: unknown;
}

@Injectable({ providedIn: 'root' })
export class FirebaseTilawaUserRepository implements TilawaUserRepository {
  private readonly firestore = inject(Firestore);

  async list(
    filters: TilawaUserFilters,
    page: PageRequest,
  ): Promise<PageResult<TilawaUser>> {
    const pageSize = page.pageSize || DEFAULT_PAGE_SIZE;
    const result = await fetchPaginatedList({
      firestore: this.firestore,
      collectionPath: QuranSessionsPaths.users,
      filters: [],
      page: { ...page, pageSize },
      defaultSort: TILAWA_USER_DEFAULT_SORT,
      allowedSortFields: TILAWA_USER_SORT_FIELDS,
      mapDoc: (id, data) => this.mapUser(id, data as TilawaUserFirestoreDto),
    });

    const items = this.applySearchFilter(result.items, filters);
    return { ...result, items };
  }

  async count(): Promise<number> {
    return firstValueFrom(
      collectionCount(collection(this.firestore, QuranSessionsPaths.users)),
    );
  }

  private mapUser(id: string, dto: TilawaUserFirestoreDto): TilawaUser {
    return {
      id,
      email: dto.email ?? null,
      displayName: dto.displayName ?? dto.name ?? null,
      photoUrl: dto.photoUrl ?? null,
      createdAt: readTimestamp(dto.createdAt),
    };
  }

  private applySearchFilter(
    items: readonly TilawaUser[],
    filters: TilawaUserFilters,
  ): TilawaUser[] {
    const search = filters.search?.trim().toLowerCase();
    if (!search) {
      return [...items];
    }

    return items.filter(
      (user) =>
        user.id.toLowerCase().includes(search) ||
        (user.displayName?.toLowerCase().includes(search) ?? false) ||
        (user.email?.toLowerCase().includes(search) ?? false),
    );
  }

  async searchByPrefix(searchTerm: string): Promise<TilawaUser[]> {
    const normalized = searchTerm.trim().toLowerCase();
    if (!normalized) {
      return [];
    }

    // Prefix search bounds
    const endBound = normalized + '\uf8ff';
    const usersCol = collection(this.firestore, QuranSessionsPaths.users);

    const emailQuery = getDocs(
      query(usersCol, where('email', '>=', normalized), where('email', '<=', endBound), limit(10))
    );

    // Wait, the standard users collection doesn't have a lowercase display name field natively indexed.
    // If displayName isn't consistently lowercase, the prefix search on it might miss capitalized names.
    // For an admin test tool, matching by email is extremely precise and safe.
    // However, I'll attempt both just in case, but rely heavily on email.
    const nameQuery = getDocs(
      query(usersCol, where('displayName', '>=', normalized), where('displayName', '<=', endBound), limit(10))
    );

    const [emailSnap, nameSnap] = await Promise.all([emailQuery, nameQuery]);

    const resultsMap = new Map<string, TilawaUser>();

    emailSnap.docs.forEach((doc) => {
      resultsMap.set(doc.id, this.mapUser(doc.id, doc.data() as TilawaUserFirestoreDto));
    });

    nameSnap.docs.forEach((doc) => {
      resultsMap.set(doc.id, this.mapUser(doc.id, doc.data() as TilawaUserFirestoreDto));
    });

    return Array.from(resultsMap.values());
  }
}

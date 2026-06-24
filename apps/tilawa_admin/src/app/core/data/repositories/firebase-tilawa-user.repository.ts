import { Injectable, inject } from '@angular/core';
import {
  Firestore,
  collection,
  collectionCount,
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
}

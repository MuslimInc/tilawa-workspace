import { InjectionToken } from '@angular/core';

import {
  QuranSessionsUser,
  QuranSessionsUserFilters,
} from '../entities/quran-sessions-user.entity';
import { PageRequest, PageResult } from '../entities/pagination.types';

/** Firestore `in` queries support at most 30 values. */
export const QS_USER_ID_IN_QUERY_LIMIT = 30;

export interface QuranSessionsUserRepository {
  list(
    filters: QuranSessionsUserFilters,
    page: PageRequest,
  ): Promise<PageResult<QuranSessionsUser>>;

  /**
   * Bounded lookup of user document ids matching geo filters (exact
   * `quranSessionsProfile.countryCode` / `cityId`). Used to scope
   * teacher-application queries server-side.
   */
  listMatchingUserIds(
    filters: Pick<QuranSessionsUserFilters, 'countryCode' | 'cityId'>,
    maxIds?: number,
  ): Promise<readonly string[]>;

  getById(userId: string): Promise<QuranSessionsUser | null>;

  getByIds(userIds: readonly string[]): Promise<Map<string, QuranSessionsUser>>;
}

export const QURAN_SESSIONS_USER_REPOSITORY = new InjectionToken<QuranSessionsUserRepository>(
  'QuranSessionsUserRepository',
);

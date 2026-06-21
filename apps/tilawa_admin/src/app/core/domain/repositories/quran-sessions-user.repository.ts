import { InjectionToken } from '@angular/core';

import {
  QuranSessionsUser,
  QuranSessionsUserFilters,
} from '../entities/quran-sessions-user.entity';
import { PageRequest, PageResult } from '../entities/pagination.types';

export interface QuranSessionsUserRepository {
  list(
    filters: QuranSessionsUserFilters,
    page: PageRequest,
  ): Promise<PageResult<QuranSessionsUser>>;

  getById(userId: string): Promise<QuranSessionsUser | null>;

  getByIds(userIds: readonly string[]): Promise<Map<string, QuranSessionsUser>>;
}

export const QURAN_SESSIONS_USER_REPOSITORY = new InjectionToken<QuranSessionsUserRepository>(
  'QuranSessionsUserRepository',
);

import { InjectionToken } from '@angular/core';

import {
  TilawaUser,
  TilawaUserFilters,
} from '../entities/tilawa-user.entity';
import { PageRequest, PageResult } from '../entities/pagination.types';

export interface TilawaUserRepository {
  list(
    filters: TilawaUserFilters,
    page: PageRequest,
  ): Promise<PageResult<TilawaUser>>;

  count(): Promise<number>;
}

export const TILAWA_USER_REPOSITORY = new InjectionToken<TilawaUserRepository>(
  'TilawaUserRepository',
);

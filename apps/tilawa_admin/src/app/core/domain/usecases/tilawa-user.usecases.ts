import { Inject, Injectable } from '@angular/core';

import {
  TilawaUser,
  TilawaUserFilters,
} from '../entities/tilawa-user.entity';
import { PageRequest, PageResult } from '../entities/pagination.types';
import {
  TILAWA_USER_REPOSITORY,
  TilawaUserRepository,
} from '../repositories/tilawa-user.repository';

@Injectable({ providedIn: 'root' })
export class ListTilawaUsersUseCase {
  constructor(
    @Inject(TILAWA_USER_REPOSITORY)
    private readonly repository: TilawaUserRepository,
  ) {}

  execute(
    filters: TilawaUserFilters,
    page: PageRequest,
  ): Promise<PageResult<TilawaUser>> {
    return this.repository.list(filters, page);
  }
}

@Injectable({ providedIn: 'root' })
export class GetTilawaUsersCountUseCase {
  constructor(
    @Inject(TILAWA_USER_REPOSITORY)
    private readonly repository: TilawaUserRepository,
  ) {}

  execute(): Promise<number> {
    return this.repository.count();
  }
}

import { Inject, Injectable } from '@angular/core';

import {
  QuranSessionsUser,
  QuranSessionsUserFilters,
} from '../entities/quran-sessions-user.entity';
import { PageRequest, PageResult } from '../entities/pagination.types';
import {
  QURAN_SESSIONS_USER_REPOSITORY,
  QuranSessionsUserRepository,
} from '../repositories/quran-sessions-user.repository';
import { UserModerationAction } from '../entities/moderation-action.enum';
import {
  MODERATION_GATEWAY,
  ModerationGateway,
} from '../repositories/moderation.gateway';

@Injectable({ providedIn: 'root' })
export class ListQuranSessionsUsersUseCase {
  constructor(
    @Inject(QURAN_SESSIONS_USER_REPOSITORY)
    private readonly repository: QuranSessionsUserRepository,
  ) {}

  execute(
    filters: QuranSessionsUserFilters,
    page: PageRequest,
  ): Promise<PageResult<QuranSessionsUser>> {
    return this.repository.list(filters, page);
  }
}

@Injectable({ providedIn: 'root' })
export class ModerateQuranSessionsUserUseCase {
  constructor(
    @Inject(MODERATION_GATEWAY) private readonly gateway: ModerationGateway,
  ) {}

  execute(
    userId: string,
    action: UserModerationAction,
    reason?: string,
  ): Promise<void> {
    return this.gateway.moderateQuranSessionsUser(userId, action, reason);
  }
}

@Injectable({ providedIn: 'root' })
export class SetUserTeacherApplicationAccessUseCase {
  constructor(
    @Inject(MODERATION_GATEWAY) private readonly gateway: ModerationGateway,
  ) {}

  execute(
    userId: string,
    canApplyAsTeacher: boolean | null,
  ): Promise<void> {
    return this.gateway.setUserTeacherApplicationAccess(
      userId,
      canApplyAsTeacher,
    );
  }
}

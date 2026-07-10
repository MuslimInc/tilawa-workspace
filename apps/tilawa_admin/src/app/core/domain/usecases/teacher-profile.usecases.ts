import { Inject, Injectable } from '@angular/core';

import { TeacherProfile, TeacherProfileFilters } from '../entities/teacher-profile.entity';
import { PageRequest, PageResult } from '../entities/pagination.types';
import {
  TEACHER_PROFILE_REPOSITORY,
  TeacherProfileRepository,
} from '../repositories/teacher-profile.repository';
import { TeacherProfileModerationAction } from '../entities/moderation-action.enum';
import { MODERATION_GATEWAY, ModerationGateway } from '../repositories/moderation.gateway';

@Injectable({ providedIn: 'root' })
export class ListTeachersUseCase {
  constructor(
    @Inject(TEACHER_PROFILE_REPOSITORY)
    private readonly repository: TeacherProfileRepository,
  ) {}

  execute(filters: TeacherProfileFilters, page: PageRequest): Promise<PageResult<TeacherProfile>> {
    return this.repository.list(filters, page);
  }
}

@Injectable({ providedIn: 'root' })
export class ModerateTeacherProfileUseCase {
  constructor(@Inject(MODERATION_GATEWAY) private readonly gateway: ModerationGateway) {}

  execute(
    teacherId: string,
    action: TeacherProfileModerationAction,
    reason?: string,
  ): Promise<void> {
    return this.gateway.moderateTeacherProfile(teacherId, action, reason);
  }
}

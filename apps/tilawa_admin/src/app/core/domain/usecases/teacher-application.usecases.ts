import { Inject, Injectable } from '@angular/core';

import {
  TeacherApplication,
  TeacherApplicationFilters,
} from '../entities/teacher-application.entity';
import { PageRequest, PageResult } from '../entities/pagination.types';
import {
  TEACHER_APPLICATION_REPOSITORY,
  TeacherApplicationRepository,
} from '../repositories/teacher-application.repository';

@Injectable({ providedIn: 'root' })
export class ListTeacherApplicationsUseCase {
  constructor(
    @Inject(TEACHER_APPLICATION_REPOSITORY)
    private readonly repository: TeacherApplicationRepository,
  ) {}

  execute(
    filters: TeacherApplicationFilters,
    page: PageRequest,
  ): Promise<PageResult<TeacherApplication>> {
    return this.repository.list(filters, page);
  }
}

@Injectable({ providedIn: 'root' })
export class GetTeacherApplicationUseCase {
  constructor(
    @Inject(TEACHER_APPLICATION_REPOSITORY)
    private readonly repository: TeacherApplicationRepository,
  ) {}

  execute(id: string): Promise<TeacherApplication | null> {
    return this.repository.getById(id);
  }
}

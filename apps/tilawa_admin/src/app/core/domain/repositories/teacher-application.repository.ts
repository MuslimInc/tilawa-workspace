import { InjectionToken } from '@angular/core';

import {
  TeacherApplication,
  TeacherApplicationFilters,
} from '../entities/teacher-application.entity';
import { PageRequest, PageResult } from '../entities/pagination.types';

export interface TeacherApplicationRepository {
  list(
    filters: TeacherApplicationFilters,
    page: PageRequest,
  ): Promise<PageResult<TeacherApplication>>;

  getById(id: string): Promise<TeacherApplication | null>;
}

export const TEACHER_APPLICATION_REPOSITORY = new InjectionToken<TeacherApplicationRepository>(
  'TeacherApplicationRepository',
);

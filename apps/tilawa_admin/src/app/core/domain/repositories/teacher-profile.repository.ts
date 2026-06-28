import { InjectionToken } from '@angular/core';

import {
  TeacherProfile,
  TeacherProfileFilters,
} from '../entities/teacher-profile.entity';
import { PageRequest, PageResult } from '../entities/pagination.types';

export interface TeacherProfileRepository {
  list(
    filters: TeacherProfileFilters,
    page: PageRequest,
  ): Promise<PageResult<TeacherProfile>>;

  getById(id: string): Promise<TeacherProfile | null>;

  getByIds(ids: readonly string[]): Promise<Map<string, TeacherProfile>>;

  searchActiveTeachers?(query: string): Promise<TeacherProfile[]>;
}

export const TEACHER_PROFILE_REPOSITORY = new InjectionToken<TeacherProfileRepository>(
  'TeacherProfileRepository',
);

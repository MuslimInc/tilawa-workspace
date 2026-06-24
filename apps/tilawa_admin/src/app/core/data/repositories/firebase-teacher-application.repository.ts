import { Injectable, inject, Inject } from '@angular/core';
import { Firestore, doc, getDoc, where } from '@angular/fire/firestore';

import { QuranSessionsPaths } from '../paths/quran-sessions.paths';
import {
  TeacherApplicationMapper,
  TeacherApplicationFirestoreDto,
} from '../mappers/quran-sessions.mapper';
import {
  TEACHER_APPLICATION_DEFAULT_SORT,
  TEACHER_APPLICATION_SORT_FIELDS,
  TeacherApplication,
  TeacherApplicationFilters,
} from '../../domain/entities/teacher-application.entity';
import { TeacherApplicationStatus } from '../../domain/entities/teacher-application-status.enum';
import {
  DEFAULT_PAGE_SIZE,
  PageRequest,
  PageResult,
} from '../../domain/entities/pagination.types';
import { TeacherApplicationRepository } from '../../domain/repositories/teacher-application.repository';
import { fetchPaginatedList } from '../firestore/firestore-list-query.util';
import {
  QURAN_SESSIONS_USER_REPOSITORY,
  QuranSessionsUserRepository,
} from '../../domain/repositories/quran-sessions-user.repository';

@Injectable({ providedIn: 'root' })
export class FirebaseTeacherApplicationRepository implements TeacherApplicationRepository {
  private readonly firestore = inject(Firestore);

  constructor(
    @Inject(QURAN_SESSIONS_USER_REPOSITORY)
    private readonly userRepository: QuranSessionsUserRepository,
  ) {}

  async list(
    filters: TeacherApplicationFilters,
    page: PageRequest,
  ): Promise<PageResult<TeacherApplication>> {
    const pageSize = page.pageSize || DEFAULT_PAGE_SIZE;
    const geoUserIds = await this.resolveGeoUserIds(filters);
    if (geoUserIds !== null && geoUserIds.length === 0) {
      return { items: [], nextCursor: null, hasMore: false };
    }

    const serverFilters = this.buildQueryConstraints(filters, geoUserIds);

    const result = await fetchPaginatedList({
      firestore: this.firestore,
      collectionPath: QuranSessionsPaths.teacherApplications,
      filters: serverFilters,
      page: { ...page, pageSize },
      defaultSort: TEACHER_APPLICATION_DEFAULT_SORT,
      allowedSortFields: TEACHER_APPLICATION_SORT_FIELDS,
      mapDoc: (id, data) =>
        TeacherApplicationMapper.fromFirestore(
          id,
          data as TeacherApplicationFirestoreDto,
        ),
    });

    const items = this.applyClientFilters(result.items, filters);
    return { ...result, items };
  }

  async getById(id: string): Promise<TeacherApplication | null> {
    const snap = await getDoc(
      doc(this.firestore, QuranSessionsPaths.teacherApplications, id),
    );
    if (!snap.exists()) {
      return null;
    }
    return TeacherApplicationMapper.fromFirestore(
      snap.id,
      snap.data() as TeacherApplicationFirestoreDto,
    );
  }

  private async resolveGeoUserIds(
    filters: TeacherApplicationFilters,
  ): Promise<readonly string[] | null> {
    const countryCode = filters.countryCode?.trim() || null;
    const cityId = filters.cityId?.trim() || null;
    if (!countryCode && !cityId) {
      return null;
    }

    return this.userRepository.listMatchingUserIds({ countryCode, cityId });
  }

  private buildQueryConstraints(
    filters: TeacherApplicationFilters,
    geoUserIds: readonly string[] | null,
  ) {
    const constraints: ReturnType<typeof where>[] = [];

    if (geoUserIds !== null) {
      constraints.push(where('userId', 'in', [...geoUserIds]));
    }

    if (filters.status && filters.status !== TeacherApplicationStatus.None) {
      constraints.push(where('status', '==', filters.status));
    }

    if (filters.submittedFrom) {
      constraints.push(where('submittedAt', '>=', filters.submittedFrom));
    }

    if (filters.submittedTo) {
      constraints.push(where('submittedAt', '<=', filters.submittedTo));
    }

    if (filters.specialization) {
      constraints.push(
        where('specializations', 'array-contains', filters.specialization),
      );
    }

    return constraints;
  }

  private applyClientFilters(
    items: readonly TeacherApplication[],
    filters: TeacherApplicationFilters,
  ): TeacherApplication[] {
    const search = filters.search?.trim().toLowerCase();
    if (!search) {
      return [...items];
    }

    return items.filter(
      (item) =>
        item.userId.toLowerCase().includes(search) ||
        (item.phoneNumber?.toLowerCase().includes(search) ?? false),
    );
  }
}

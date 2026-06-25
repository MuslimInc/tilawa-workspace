import { Injectable, inject } from '@angular/core';
import { Firestore, doc, getDoc, where, query, getDocs, limit, collection } from '@angular/fire/firestore';

import { QuranSessionsPaths } from '../paths/quran-sessions.paths';
import { TeacherProfileMapper, TeacherProfileFirestoreDto } from '../mappers/quran-sessions.mapper';
import {
  TEACHER_PROFILE_DEFAULT_SORT,
  TEACHER_PROFILE_SORT_FIELDS,
  TeacherProfile,
  TeacherProfileFilters,
} from '../../domain/entities/teacher-profile.entity';
import { DEFAULT_PAGE_SIZE, PageRequest, PageResult } from '../../domain/entities/pagination.types';
import { TeacherProfileRepository } from '../../domain/repositories/teacher-profile.repository';
import { fetchPaginatedList } from '../firestore/firestore-list-query.util';

@Injectable({ providedIn: 'root' })
export class FirebaseTeacherProfileRepository implements TeacherProfileRepository {
  private readonly firestore = inject(Firestore);

  async list(
    filters: TeacherProfileFilters,
    page: PageRequest,
  ): Promise<PageResult<TeacherProfile>> {
    const pageSize = page.pageSize || DEFAULT_PAGE_SIZE;
    const serverFilters = buildTeacherProfileQueryConstraints(filters);

    const result = await fetchPaginatedList({
      firestore: this.firestore,
      collectionPath: QuranSessionsPaths.teacherProfiles,
      filters: serverFilters,
      page: { ...page, pageSize },
      defaultSort: TEACHER_PROFILE_DEFAULT_SORT,
      allowedSortFields: TEACHER_PROFILE_SORT_FIELDS,
      mapDoc: (id, data) =>
        TeacherProfileMapper.fromFirestore(id, data as TeacherProfileFirestoreDto),
    });

    const items = this.applySearchFilter(result.items, filters);
    return { ...result, items };
  }

  async getById(id: string): Promise<TeacherProfile | null> {
    const snap = await getDoc(doc(this.firestore, QuranSessionsPaths.teacherProfiles, id));
    if (!snap.exists()) {
      return null;
    }
    return TeacherProfileMapper.fromFirestore(snap.id, snap.data() as TeacherProfileFirestoreDto);
  }

  async getByIds(ids: readonly string[]): Promise<Map<string, TeacherProfile>> {
    const uniqueIds = [...new Set(ids.filter((id) => id.trim().length > 0))];
    const result = new Map<string, TeacherProfile>();

    await Promise.all(
      uniqueIds.map(async (id) => {
        const profile = await this.getById(id);
        if (profile) {
          result.set(id, profile);
        }
      }),
    );

    return result;
  }

  private applySearchFilter(
    items: readonly TeacherProfile[],
    filters: TeacherProfileFilters,
  ): TeacherProfile[] {
    const search = filters.search?.trim().toLowerCase();
    if (!search) {
      return [...items];
    }

    return items.filter(
      (item) =>
        item.displayName.toLowerCase().includes(search) ||
        item.userId.toLowerCase().includes(search),
    );
  }

  async searchActiveTeachers(searchQuery: string): Promise<TeacherProfile[]> {
    const normalized = searchQuery.trim().toLowerCase();
    if (!normalized) {
      return [];
    }

    const endBound = normalized + '\uf8ff';
    const teachersCol = collection(this.firestore, QuranSessionsPaths.teacherProfiles);

    const q = query(
      teachersCol,
      where('isActive', '==', true),
      where('displayName', '>=', normalized),
      where('displayName', '<=', endBound),
      limit(10)
    );

    const snap = await getDocs(q);
    return snap.docs.map((docSnap) =>
      TeacherProfileMapper.fromFirestore(docSnap.id, docSnap.data() as TeacherProfileFirestoreDto)
    );
  }
}

/**
 * Server-side query constraints for teacher profiles. Exported for
 * query-contract tests. `search` stays client-side (current page only).
 */
export function buildTeacherProfileQueryConstraints(
  filters: TeacherProfileFilters,
): ReturnType<typeof where>[] {
  const constraints: ReturnType<typeof where>[] = [];

  if (filters.isActive != null) {
    constraints.push(where('isActive', '==', filters.isActive));
  }

  if (filters.verificationStatus) {
    constraints.push(where('verificationStatus', '==', filters.verificationStatus));
  }

  if (filters.language) {
    constraints.push(where('teachingLanguages', 'array-contains', filters.language));
  }

  if (filters.specialization) {
    constraints.push(where('specializations', 'array-contains', filters.specialization));
  }

  return constraints;
}

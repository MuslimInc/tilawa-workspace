import { Injectable, inject } from '@angular/core';
import {
  Firestore,
  collection,
  doc,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  startAfter,
  where,
} from '@angular/fire/firestore';

import { QuranSessionsPaths } from '../paths/quran-sessions.paths';
import {
  TeacherProfileMapper,
  TeacherProfileFirestoreDto,
} from '../mappers/quran-sessions.mapper';
import {
  TeacherProfile,
  TeacherProfileFilters,
} from '../../domain/entities/teacher-profile.entity';
import { PageRequest, PageResult } from '../../domain/entities/pagination.types';
import { TeacherProfileRepository } from '../../domain/repositories/teacher-profile.repository';

const DEFAULT_PAGE_SIZE = 25;

@Injectable({ providedIn: 'root' })
export class FirebaseTeacherProfileRepository implements TeacherProfileRepository {
  private readonly firestore = inject(Firestore);

  async list(
    filters: TeacherProfileFilters,
    page: PageRequest,
  ): Promise<PageResult<TeacherProfile>> {
    const pageSize = page.pageSize || DEFAULT_PAGE_SIZE;
    const constraints: Parameters<typeof query>[1][] = [];

    if (filters.isActive != null) {
      constraints.push(where('isActive', '==', filters.isActive));
    }

    if (filters.verificationStatus) {
      constraints.push(
        where('verificationStatus', '==', filters.verificationStatus),
      );
    }

    if (filters.language) {
      constraints.push(
        where('teachingLanguages', 'array-contains', filters.language),
      );
    }

    if (filters.specialization) {
      constraints.push(
        where('specializations', 'array-contains', filters.specialization),
      );
    }

    let q = query(
      collection(this.firestore, QuranSessionsPaths.teacherProfiles),
      ...constraints,
      orderBy('updatedAt', 'desc'),
      limit(pageSize + 1),
    );

    if (page.cursor) {
      const cursorDoc = await getDoc(
        doc(this.firestore, QuranSessionsPaths.teacherProfiles, page.cursor),
      );
      if (cursorDoc.exists()) {
        q = query(q, startAfter(cursorDoc));
      }
    }

    const snapshot = await getDocs(q);
    const docs = snapshot.docs;
    const hasMore = docs.length > pageSize;
    const pageDocs = hasMore ? docs.slice(0, pageSize) : docs;

    let items = pageDocs.map((snap) =>
      TeacherProfileMapper.fromFirestore(
        snap.id,
        snap.data() as TeacherProfileFirestoreDto,
      ),
    );

    const search = filters.search?.trim().toLowerCase();
    if (search) {
      items = items.filter(
        (item) =>
          item.displayName.toLowerCase().includes(search) ||
          item.userId.toLowerCase().includes(search),
      );
    }

    const nextCursor =
      hasMore && pageDocs.length > 0 ? pageDocs[pageDocs.length - 1].id : null;

    return { items, nextCursor, hasMore };
  }

  async getById(id: string): Promise<TeacherProfile | null> {
    const snap = await getDoc(
      doc(this.firestore, QuranSessionsPaths.teacherProfiles, id),
    );
    if (!snap.exists()) {
      return null;
    }
    return TeacherProfileMapper.fromFirestore(
      snap.id,
      snap.data() as TeacherProfileFirestoreDto,
    );
  }
}

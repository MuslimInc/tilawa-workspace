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
  QueryDocumentSnapshot,
  DocumentData,
} from '@angular/fire/firestore';

import { QuranSessionsPaths } from '../paths/quran-sessions.paths';
import {
  TeacherApplicationMapper,
  TeacherApplicationFirestoreDto,
} from '../mappers/quran-sessions.mapper';
import {
  TeacherApplication,
  TeacherApplicationFilters,
} from '../../domain/entities/teacher-application.entity';
import { TeacherApplicationStatus } from '../../domain/entities/teacher-application-status.enum';
import { PageRequest, PageResult } from '../../domain/entities/pagination.types';
import { TeacherApplicationRepository } from '../../domain/repositories/teacher-application.repository';

const DEFAULT_PAGE_SIZE = 25;

@Injectable({ providedIn: 'root' })
export class FirebaseTeacherApplicationRepository implements TeacherApplicationRepository {
  private readonly firestore = inject(Firestore);

  async list(
    filters: TeacherApplicationFilters,
    page: PageRequest,
  ): Promise<PageResult<TeacherApplication>> {
    const pageSize = page.pageSize || DEFAULT_PAGE_SIZE;
    const constraints = this.buildQueryConstraints(filters);

    let q = query(
      collection(this.firestore, QuranSessionsPaths.teacherApplications),
      ...constraints,
      orderBy('updatedAt', 'desc'),
      limit(pageSize + 1),
    );

    if (page.cursor) {
      const cursorDoc = await getDoc(
        doc(this.firestore, QuranSessionsPaths.teacherApplications, page.cursor),
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
      TeacherApplicationMapper.fromFirestore(
        snap.id,
        snap.data() as TeacherApplicationFirestoreDto,
      ),
    );

    items = this.applyClientFilters(items, filters);

    const nextCursor =
      hasMore && pageDocs.length > 0 ? pageDocs[pageDocs.length - 1].id : null;

    return { items, nextCursor, hasMore };
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

  private buildQueryConstraints(filters: TeacherApplicationFilters) {
    const constraints: Parameters<typeof query>[1][] = [];

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
    items: TeacherApplication[],
    filters: TeacherApplicationFilters,
  ): TeacherApplication[] {
    const search = filters.search?.trim().toLowerCase();
    if (!search) {
      return items;
    }

    return items.filter(
      (item) =>
        item.userId.toLowerCase().includes(search) ||
        (item.phoneNumber?.toLowerCase().includes(search) ?? false),
    );
  }
}


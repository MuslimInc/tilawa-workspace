import {
  DocumentData,
  Firestore,
  QueryConstraint,
  collection,
  doc,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  startAfter,
} from '@angular/fire/firestore';

import {
  PageRequest,
  PageResult,
  SortDirection,
  SortRequest,
  resolveSort,
} from '../../domain/entities/pagination.types';

export interface PaginatedListOptions<T> {
  readonly firestore: Firestore;
  readonly collectionPath: string;
  readonly filters: readonly QueryConstraint[];
  readonly page: PageRequest;
  readonly defaultSort: SortRequest;
  readonly allowedSortFields: readonly string[];
  readonly mapDoc: (id: string, data: DocumentData) => T;
}

export async function fetchPaginatedList<T>(
  options: PaginatedListOptions<T>,
): Promise<PageResult<T>> {
  const pageSize = options.page.pageSize;
  const sort = resolveSort(
    options.page.sort,
    options.defaultSort,
    options.allowedSortFields,
  );

  const constraints: QueryConstraint[] = [
    ...options.filters,
    orderBy(sort.field, sort.direction),
    limit(pageSize + 1),
  ];

  let q = query(
    collection(options.firestore, options.collectionPath),
    ...constraints,
  );

  if (options.page.cursor) {
    const cursorDoc = await getDoc(
      doc(options.firestore, options.collectionPath, options.page.cursor),
    );
    if (cursorDoc.exists()) {
      q = query(q, startAfter(cursorDoc));
    }
  }

  const snapshot = await getDocs(q);
  const docs = snapshot.docs;
  const hasMore = docs.length > pageSize;
  const pageDocs = hasMore ? docs.slice(0, pageSize) : docs;

  const items = pageDocs.map((snap) =>
    options.mapDoc(snap.id, snap.data()),
  );

  const nextCursor =
    hasMore && pageDocs.length > 0 ? pageDocs[pageDocs.length - 1].id : null;

  return { items, nextCursor, hasMore };
}

export function orderDirection(
  direction: SortDirection,
): 'asc' | 'desc' {
  return direction;
}

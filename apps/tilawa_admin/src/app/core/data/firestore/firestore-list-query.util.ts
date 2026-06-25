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

/**
 * Pure query plan: resolves the sort via the allow-list and appends the
 * server-side `orderBy` + `limit(pageSize + 1)` constraints used to detect
 * `hasMore` without a count read. Exported so query-contract tests can assert
 * that list pages sort on the server (never a JS array sort) and paginate with
 * `limit`/cursor — no Firestore instance required.
 */
export function buildPageQueryConstraints(options: {
  readonly filters: readonly QueryConstraint[];
  readonly page: PageRequest;
  readonly defaultSort: SortRequest;
  readonly allowedSortFields: readonly string[];
}): readonly QueryConstraint[] {
  const pageSize = options.page.pageSize;
  const sort = resolveSort(options.page.sort, options.defaultSort, options.allowedSortFields);

  return [...options.filters, orderBy(sort.field, sort.direction), limit(pageSize + 1)];
}

export async function fetchPaginatedList<T>(
  options: PaginatedListOptions<T>,
): Promise<PageResult<T>> {
  const pageSize = options.page.pageSize;
  const constraints = buildPageQueryConstraints({
    filters: options.filters,
    page: options.page,
    defaultSort: options.defaultSort,
    allowedSortFields: options.allowedSortFields,
  });

  let q = query(collection(options.firestore, options.collectionPath), ...constraints);

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

  const items = pageDocs.map((snap) => options.mapDoc(snap.id, snap.data()));

  const nextCursor = hasMore && pageDocs.length > 0 ? pageDocs[pageDocs.length - 1].id : null;

  return { items, nextCursor, hasMore };
}

export function orderDirection(direction: SortDirection): 'asc' | 'desc' {
  return direction;
}

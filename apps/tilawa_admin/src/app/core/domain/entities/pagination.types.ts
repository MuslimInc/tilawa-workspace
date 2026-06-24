export type SortDirection = 'asc' | 'desc';

export interface SortRequest {
  readonly field: string;
  readonly direction: SortDirection;
}

export interface PageRequest {
  readonly pageSize: number;
  readonly cursor?: string | null;
  readonly sort?: SortRequest | null;
}

export interface PageResult<T> {
  readonly items: readonly T[];
  readonly nextCursor: string | null;
  readonly hasMore: boolean;
}

export const DEFAULT_PAGE_SIZE = 25;
export const CALL_EVENTS_PAGE_SIZE = 20;

export function sortsEqual(
  a: SortRequest | null | undefined,
  b: SortRequest | null | undefined,
): boolean {
  if (a == null && b == null) {
    return true;
  }
  if (a == null || b == null) {
    return false;
  }
  return a.field === b.field && a.direction === b.direction;
}

export function resolveSort(
  sort: SortRequest | null | undefined,
  defaults: SortRequest,
  allowedFields: readonly string[],
): SortRequest {
  if (!sort || !allowedFields.includes(sort.field)) {
    return defaults;
  }
  return sort;
}

import { Injectable, inject, signal } from '@angular/core';

import {
  DEFAULT_PAGE_SIZE,
  SortRequest,
  sortsEqual,
} from '../../domain/entities/pagination.types';

type LoadState = 'idle' | 'loading' | 'success' | 'error';

export interface FacadeListLoadOptions {
  readonly cursor?: string | null;
  readonly append?: boolean;
  readonly sort?: SortRequest;
}

/**
 * Shared cursor-list state: sort change always resets to page 1.
 */
export function createPaginatedListState<TItem, TSort extends SortRequest>(
  defaultSort: TSort,
) {
  const listState = signal<LoadState>('idle');
  const listError = signal<string | null>(null);
  const listItems = signal<TItem[]>([]);
  const nextCursor = signal<string | null>(null);
  const hasMore = signal(false);
  const listSort = signal<TSort>(defaultSort);

  function resolveLoadParams(options?: FacadeListLoadOptions) {
    const sort = (options?.sort ?? listSort()) as TSort;
    const sortChanged = !sortsEqual(sort, listSort());
    const append = options?.append === true && !sortChanged;
    const cursor = append ? (options?.cursor ?? nextCursor()) : null;
    listSort.set(sort);
    return { sort, append, cursor };
  }

  return {
    listState,
    listError,
    listItems,
    nextCursor,
    hasMore,
    listSort,
    resolveLoadParams,
  };
}

export { DEFAULT_PAGE_SIZE };

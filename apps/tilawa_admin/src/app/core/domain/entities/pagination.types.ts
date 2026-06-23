export interface PageRequest {
  readonly pageSize: number;
  readonly cursor?: string | null;
}

export interface PageResult<T> {
  readonly items: readonly T[];
  readonly nextCursor: string | null;
  readonly hasMore: boolean;
}

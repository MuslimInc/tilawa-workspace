export interface TilawaUser {
  readonly id: string;
  readonly email: string | null;
  readonly displayName: string | null;
  readonly photoUrl: string | null;
  readonly createdAt: Date | null;
}

export interface TilawaUserFilters {
  readonly search?: string | null;
}

export const TILAWA_USER_DEFAULT_SORT = {
  field: 'createdAt',
  direction: 'desc',
} as const;

export const TILAWA_USER_SORT_FIELDS = [
  'createdAt',
  'displayName',
  'email',
] as const;

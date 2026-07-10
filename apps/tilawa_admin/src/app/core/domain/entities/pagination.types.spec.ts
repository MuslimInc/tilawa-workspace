import { describe, expect, it } from 'vitest';

import { resolveSort, sortsEqual } from '../../domain/entities/pagination.types';
import { TILAWA_USER_DEFAULT_SORT } from '../../domain/entities/tilawa-user.entity';
import { QS_USER_DEFAULT_SORT } from '../../domain/entities/quran-sessions-user.entity';

describe('pagination.types', () => {
  it('sortsEqual matches field and direction', () => {
    expect(
      sortsEqual(
        { field: 'createdAt', direction: 'desc' },
        { field: 'createdAt', direction: 'desc' },
      ),
    ).toBe(true);
    expect(
      sortsEqual(
        { field: 'createdAt', direction: 'desc' },
        { field: 'createdAt', direction: 'asc' },
      ),
    ).toBe(false);
    expect(sortsEqual(null, null)).toBe(true);
  });

  it('resolveSort falls back when field unsupported', () => {
    expect(
      resolveSort({ field: 'unknown', direction: 'asc' }, TILAWA_USER_DEFAULT_SORT, [
        'createdAt',
        'email',
      ]),
    ).toEqual(TILAWA_USER_DEFAULT_SORT);
  });

  it('resolveSort keeps valid QS nested sort field', () => {
    const sort = { field: 'quranSessionsProfile.createdAt', direction: 'asc' as const };
    expect(
      resolveSort(sort, QS_USER_DEFAULT_SORT, [
        'quranSessionsProfile.updatedAt',
        'quranSessionsProfile.createdAt',
      ]),
    ).toEqual(sort);
  });
});

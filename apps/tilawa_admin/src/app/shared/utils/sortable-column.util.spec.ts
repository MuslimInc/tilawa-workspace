import { describe, expect, it } from 'vitest';

import { nextSortForField } from './sortable-column.util';

describe('nextSortForField', () => {
  it('starts new field as desc', () => {
    expect(
      nextSortForField({ field: 'createdAt', direction: 'desc' }, 'updatedAt'),
    ).toEqual({ field: 'updatedAt', direction: 'desc' });
  });

  it('toggles direction on same field', () => {
    expect(
      nextSortForField({ field: 'createdAt', direction: 'desc' }, 'createdAt'),
    ).toEqual({ field: 'createdAt', direction: 'asc' });
    expect(
      nextSortForField({ field: 'createdAt', direction: 'asc' }, 'createdAt'),
    ).toEqual({ field: 'createdAt', direction: 'desc' });
  });
});

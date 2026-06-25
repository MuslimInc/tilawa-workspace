import { describe, expect, it } from 'vitest';
import { QueryConstraint, limit, orderBy, where } from '@angular/fire/firestore';

import { buildPageQueryConstraints } from './firestore-list-query.util';

interface Inspected {
  type: string;
  field?: string;
  op?: string;
  value?: unknown;
  direction?: 'asc' | 'desc';
  limit?: number;
}

function inspect(c: QueryConstraint): Inspected {
  const anyC = c as unknown as {
    type: string;
    _field?: { segments: readonly string[] };
    _op?: string;
    _value?: unknown;
    _direction?: 'asc' | 'desc';
    _limit?: number;
  };
  return {
    type: anyC.type,
    field: anyC._field?.segments.join('.'),
    op: anyC._op,
    value: anyC._value,
    direction: anyC._direction,
    limit: anyC._limit,
  };
}

describe('buildPageQueryConstraints', () => {
  const defaultSort = { field: 'createdAt', direction: 'desc' as const };
  const allowed = ['createdAt', 'updatedAt'];

  it('appends server orderBy + limit(pageSize + 1) for hasMore detection', () => {
    const constraints = buildPageQueryConstraints({
      filters: [],
      page: { pageSize: 25 },
      defaultSort,
      allowedSortFields: allowed,
    });
    const inspected = constraints.map(inspect);

    expect(inspected).toContainEqual({
      type: 'orderBy',
      field: 'createdAt',
      direction: 'desc',
    });
    expect(inspected).toContainEqual({ type: 'limit', limit: 26 });
  });

  it('sort uses server orderBy, never a JS array sort', () => {
    const constraints = buildPageQueryConstraints({
      filters: [],
      page: { pageSize: 25, sort: { field: 'updatedAt', direction: 'asc' } },
      defaultSort,
      allowedSortFields: allowed,
    });
    const order = constraints.map(inspect).find((c) => c.type === 'orderBy');

    expect(order).toEqual({ type: 'orderBy', field: 'updatedAt', direction: 'asc' });
  });

  it('falls back to default sort when requested field is not allow-listed', () => {
    const constraints = buildPageQueryConstraints({
      filters: [],
      page: { pageSize: 25, sort: { field: 'malicious', direction: 'asc' } },
      defaultSort,
      allowedSortFields: allowed,
    });
    const order = constraints.map(inspect).find((c) => c.type === 'orderBy');

    expect(order).toEqual({ type: 'orderBy', field: 'createdAt', direction: 'desc' });
  });

  it('passes server filters through in order before orderBy/limit', () => {
    const filters: QueryConstraint[] = [
      where('status', '==', 'open'),
      where('severity', '==', 'high'),
    ];
    const constraints = buildPageQueryConstraints({
      filters,
      page: { pageSize: 10 },
      defaultSort,
      allowedSortFields: allowed,
    });
    const inspected = constraints.map(inspect);

    expect(inspected[0]).toMatchObject({ type: 'where', field: 'status', op: '==' });
    expect(inspected[1]).toMatchObject({ type: 'where', field: 'severity', op: '==' });
    expect(inspected[2].type).toBe('orderBy');
    expect(inspected[3].type).toBe('limit');
    expect(inspected[3].limit).toBe(11);
  });

  it('limit grows with page size (cursor pagination, no count read)', () => {
    const a = buildPageQueryConstraints({
      filters: [],
      page: { pageSize: 25 },
      defaultSort,
      allowedSortFields: allowed,
    });
    const b = buildPageQueryConstraints({
      filters: [],
      page: { pageSize: 50 },
      defaultSort,
      allowedSortFields: allowed,
    });
    expect(inspect(a[a.length - 1]).limit).toBe(26);
    expect(inspect(b[b.length - 1]).limit).toBe(51);
  });
});

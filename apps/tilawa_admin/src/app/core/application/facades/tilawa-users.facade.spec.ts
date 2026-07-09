import { describe, expect, it, vi, beforeEach } from 'vitest';
import { TestBed } from '@angular/core/testing';

import { TilawaUsersFacade } from './tilawa-users.facade';
import { ListTilawaUsersUseCase } from '../../domain/usecases/tilawa-user.usecases';
import { TILAWA_USER_DEFAULT_SORT } from '../../domain/entities/tilawa-user.entity';
import { AUTH_ADMIN_GATEWAY } from '../../domain/repositories/auth-admin.gateway';
import { RequestUserDeletionUseCase } from '../../domain/usecases/user-deletion.usecases';
import { AuthFacade } from './auth.facade';
import { I18nService } from '../../i18n/i18n.service';

describe('TilawaUsersFacade', () => {
  let facade: TilawaUsersFacade;
  const listUseCase = {
    execute: vi.fn(),
  };
  const requestDeletionUseCase = { execute: vi.fn() };
  const authAdminGateway = {
    revokeTokens: vi.fn(),
    lookupUserAuthMetadata: vi.fn().mockResolvedValue({ adminUserIds: [], authBackedUserIds: [] }),
  };
  const authFacade = { session: vi.fn().mockReturnValue(null) };
  const i18n = { t: vi.fn() };

  beforeEach(() => {
    listUseCase.execute.mockReset();
    TestBed.configureTestingModule({
      providers: [
        TilawaUsersFacade,
        { provide: ListTilawaUsersUseCase, useValue: listUseCase },
        { provide: RequestUserDeletionUseCase, useValue: requestDeletionUseCase },
        { provide: AUTH_ADMIN_GATEWAY, useValue: authAdminGateway },
        { provide: AuthFacade, useValue: authFacade },
        { provide: I18nService, useValue: i18n },
      ],
    });
    facade = TestBed.inject(TilawaUsersFacade);
  });

  it('loads first page with default sort', async () => {
    listUseCase.execute.mockResolvedValue({
      items: [{ id: 'u1', email: 'a@b.com', displayName: 'A', photoUrl: null }],
      nextCursor: 'u1',
      hasMore: true,
    });

    await facade.loadList({});

    expect(listUseCase.execute).toHaveBeenCalledWith(
      {},
      expect.objectContaining({
        pageSize: 25,
        cursor: null,
        sort: TILAWA_USER_DEFAULT_SORT,
      }),
    );
    expect(facade.items().length).toBe(1);
    expect(facade.canLoadMore()).toBe(true);
  });

  it('resets cursor when sort changes', async () => {
    listUseCase.execute.mockResolvedValue({
      items: [],
      nextCursor: null,
      hasMore: false,
    });

    await facade.loadList({}, { sort: TILAWA_USER_DEFAULT_SORT });
    await facade.changeSort({}, { field: 'email', direction: 'asc' });

    expect(listUseCase.execute).toHaveBeenLastCalledWith(
      {},
      expect.objectContaining({
        cursor: null,
        sort: { field: 'email', direction: 'asc' },
      }),
    );
  });

  it('appends on loadMore with stable sort', async () => {
    listUseCase.execute
      .mockResolvedValueOnce({
        items: [{ id: 'u1', email: null, displayName: 'A', photoUrl: null }],
        nextCursor: 'u1',
        hasMore: true,
      })
      .mockResolvedValueOnce({
        items: [{ id: 'u2', email: null, displayName: 'B', photoUrl: null }],
        nextCursor: null,
        hasMore: false,
      });

    await facade.loadList({});
    await facade.loadMore({});

    expect(listUseCase.execute).toHaveBeenLastCalledWith(
      {},
      expect.objectContaining({ cursor: 'u1', sort: TILAWA_USER_DEFAULT_SORT }),
    );
    expect(facade.items().map((u) => u.id)).toEqual(['u1', 'u2']);
  });

  it('marks duplicate emails across loaded rows', async () => {
    listUseCase.execute.mockResolvedValue({
      items: [
        { id: 'u1', email: 'dup@example.com', displayName: 'A', photoUrl: null },
        { id: 'u2', email: 'dup@example.com', displayName: 'B', photoUrl: null },
        { id: 'u3', email: 'unique@example.com', displayName: 'C', photoUrl: null },
      ],
      nextCursor: null,
      hasMore: false,
    });

    await facade.loadList({});

    expect(facade.items().map((user) => user.hasDuplicateEmail)).toEqual([true, true, false]);
  });
});

import { describe, expect, it, vi, beforeEach } from 'vitest';
import { TestBed } from '@angular/core/testing';

import { QuranSessionsUsersFacade } from './quran-sessions-users.facade';
import {
  ListQuranSessionsUsersUseCase,
  ModerateQuranSessionsUserUseCase,
  SetUserTeacherApplicationAccessUseCase,
} from '../../domain/usecases/quran-sessions-user.usecases';
import {
  CancelUserDeletionUseCase,
  RequestUserDeletionUseCase,
  ListUserDeletionAuditUseCase,
} from '../../domain/usecases/user-deletion.usecases';
import { QS_USER_DEFAULT_SORT } from '../../domain/entities/quran-sessions-user.entity';
import { QuranSessionsAccountStatus } from '../../domain/entities/quran-sessions-user.entity';

describe('QuranSessionsUsersFacade', () => {
  let facade: QuranSessionsUsersFacade;
  const listUseCase = { execute: vi.fn() };
  const moderateUseCase = { execute: vi.fn() };
  const teacherApplyUseCase = { execute: vi.fn() };
  const requestDeletionUseCase = { execute: vi.fn() };
  const cancelDeletionUseCase = { execute: vi.fn() };
  const listDeletionAuditUseCase = { execute: vi.fn() };

  beforeEach(() => {
    listUseCase.execute.mockReset();
    TestBed.configureTestingModule({
      providers: [
        QuranSessionsUsersFacade,
        { provide: ListQuranSessionsUsersUseCase, useValue: listUseCase },
        { provide: ModerateQuranSessionsUserUseCase, useValue: moderateUseCase },
        {
          provide: SetUserTeacherApplicationAccessUseCase,
          useValue: teacherApplyUseCase,
        },
        { provide: RequestUserDeletionUseCase, useValue: requestDeletionUseCase },
        { provide: CancelUserDeletionUseCase, useValue: cancelDeletionUseCase },
        { provide: ListUserDeletionAuditUseCase, useValue: listDeletionAuditUseCase },
      ],
    });
    facade = TestBed.inject(QuranSessionsUsersFacade);
  });

  it('passes server filters and sort to use case', async () => {
    listUseCase.execute.mockResolvedValue({
      items: [],
      nextCursor: null,
      hasMore: false,
    });

    const filters = {
      accountStatus: QuranSessionsAccountStatus.Active,
      countryCode: 'EG',
    };

    await facade.loadList(filters);

    expect(listUseCase.execute).toHaveBeenCalledWith(
      filters,
      expect.objectContaining({
        pageSize: 25,
        sort: QS_USER_DEFAULT_SORT,
        cursor: null,
      }),
    );
  });

  it('resets list on sort change instead of appending', async () => {
    listUseCase.execute.mockResolvedValue({
      items: [
        {
          userId: 'u1',
          email: 'a@b.com',
          displayName: 'A',
          avatarUrl: null,
          gender: null,
          countryCode: null,
          countryName: null,
          cityId: null,
          cityName: null,
          profileCompleted: true,
          accountStatus: QuranSessionsAccountStatus.Active,
          createdAt: null,
          updatedAt: null,
        },
      ],
      nextCursor: 'u1',
      hasMore: true,
    });

    await facade.loadList({});
    await facade.changeSort(
      {},
      {
        field: 'quranSessionsProfile.createdAt',
        direction: 'asc',
      },
    );

    expect(listUseCase.execute).toHaveBeenLastCalledWith(
      {},
      expect.objectContaining({
        cursor: null,
        sort: { field: 'quranSessionsProfile.createdAt', direction: 'asc' },
      }),
    );
  });
});

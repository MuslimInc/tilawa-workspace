import { describe, expect, it, vi, beforeEach } from 'vitest';
import { TestBed } from '@angular/core/testing';

import { TeacherApplicationsFacade } from './teacher-applications.facade';
import {
  GetTeacherApplicationUseCase,
  ListTeacherApplicationsUseCase,
} from '../../domain/usecases/teacher-application.usecases';
import { ReviewTeacherApplicationUseCase } from '../../domain/usecases/review-teacher-application.usecase';
import { ApplicationModerationAction } from '../../domain/entities/moderation-action.enum';
import { TeacherApplicationStatus } from '../../domain/entities/teacher-application-status.enum';
import { QURAN_SESSIONS_USER_REPOSITORY } from '../../domain/repositories/quran-sessions-user.repository';

describe('TeacherApplicationsFacade', () => {
  let facade: TeacherApplicationsFacade;
  const listUseCase = { execute: vi.fn() };
  const getUseCase = { execute: vi.fn() };
  const reviewUseCase = { execute: vi.fn() };
  const userRepository = { getById: vi.fn(), getByIds: vi.fn() };

  beforeEach(() => {
    listUseCase.execute.mockReset();
    getUseCase.execute.mockReset();
    reviewUseCase.execute.mockReset();
    userRepository.getById.mockReset();
    userRepository.getByIds.mockReset();

    TestBed.configureTestingModule({
      providers: [
        TeacherApplicationsFacade,
        { provide: ListTeacherApplicationsUseCase, useValue: listUseCase },
        { provide: GetTeacherApplicationUseCase, useValue: getUseCase },
        { provide: ReviewTeacherApplicationUseCase, useValue: reviewUseCase },
        { provide: QURAN_SESSIONS_USER_REPOSITORY, useValue: userRepository },
      ],
    });
    facade = TestBed.inject(TeacherApplicationsFacade);
  });

  it('sets action loading while review is in flight', async () => {
    let resolveReview!: () => void;
    const reviewPromise = new Promise<void>((resolve) => {
      resolveReview = resolve;
    });

    reviewUseCase.execute.mockReturnValue(reviewPromise);
    getUseCase.execute.mockResolvedValue({
      id: 'app-1',
      userId: 'user-1',
      status: TeacherApplicationStatus.Approved,
      publicDisplayName: 'Teacher',
      teacherDisplayName: null,
      phoneNumber: null,
      phoneCountryCode: null,
      preferredContactMethod: null,
      teachingLanguages: [],
      specializations: [],
      bio: null,
      submittedAt: new Date(),
      reviewedAt: null,
      reviewedBy: null,
      rejectionReason: null,
      updatedAt: new Date(),
      createdAt: new Date(),
    });
    userRepository.getById.mockResolvedValue({
      userId: 'user-1',
      email: 'teacher@example.com',
      displayName: 'Account Name',
      avatarUrl: null,
      gender: null,
      countryCode: null,
      countryName: null,
      cityId: null,
      cityName: null,
      profileCompleted: true,
      accountStatus: 'active',
      createdAt: null,
      updatedAt: null,
    });

    const reviewCall = facade.review('app-1', ApplicationModerationAction.Approve);
    expect(facade.isActionLoading()).toBe(true);

    resolveReview();
    await reviewCall;

    expect(facade.isActionLoading()).toBe(false);
    expect(reviewUseCase.execute).toHaveBeenCalledWith(
      'app-1',
      ApplicationModerationAction.Approve,
      undefined,
    );
  });
});

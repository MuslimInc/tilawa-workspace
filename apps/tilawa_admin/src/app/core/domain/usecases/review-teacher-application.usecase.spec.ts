import { describe, it, expect } from 'vitest';

import { ReviewTeacherApplicationUseCase } from '../../domain/usecases/review-teacher-application.usecase';
import { ApplicationModerationAction } from '../../domain/entities/moderation-action.enum';

describe('ReviewTeacherApplicationUseCase', () => {
  it('requires a reason for reject actions', async () => {
    const gateway = {
      reviewTeacherApplication: async () => undefined,
      moderateTeacherProfile: async () => undefined,
      moderateQuranSessionsUser: async () => undefined,
      setUserTeacherApplicationAccess: async () => undefined,
    };

    const useCase = new ReviewTeacherApplicationUseCase(gateway);

    await expect(
      useCase.execute('app-1', ApplicationModerationAction.Reject),
    ).rejects.toThrow('A reason is required');
  });
});

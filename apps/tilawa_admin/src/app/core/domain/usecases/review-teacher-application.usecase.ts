import { Inject, Injectable } from '@angular/core';

import { ApplicationModerationAction } from '../entities/moderation-action.enum';
import {
  MODERATION_GATEWAY,
  ModerationGateway,
} from '../repositories/moderation.gateway';

@Injectable({ providedIn: 'root' })
export class ReviewTeacherApplicationUseCase {
  constructor(
    @Inject(MODERATION_GATEWAY) private readonly gateway: ModerationGateway,
  ) {}

  async execute(
    applicationId: string,
    action: ApplicationModerationAction,
    reason?: string,
  ): Promise<void> {
    if (!applicationId.trim()) {
      throw new Error('Application id is required.');
    }

    const needsReason =
      action === ApplicationModerationAction.Reject ||
      action === ApplicationModerationAction.Suspend ||
      action === ApplicationModerationAction.Revoke;

    if (needsReason && !reason?.trim()) {
      throw new Error('A reason is required for this action.');
    }

    await this.gateway.reviewTeacherApplication(applicationId, action, reason?.trim());
  }
}

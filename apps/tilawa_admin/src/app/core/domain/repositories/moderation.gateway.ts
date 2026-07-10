import { InjectionToken } from '@angular/core';

import {
  ApplicationModerationAction,
  TeacherProfileModerationAction,
  UserModerationAction,
} from '../entities/moderation-action.enum';

/** Privileged writes — always server-controlled (callable / REST). */
export interface ModerationGateway {
  reviewTeacherApplication(
    applicationId: string,
    action: ApplicationModerationAction,
    reason?: string,
  ): Promise<void>;

  moderateTeacherProfile(
    teacherId: string,
    action: TeacherProfileModerationAction,
    reason?: string,
  ): Promise<void>;

  moderateQuranSessionsUser(
    userId: string,
    action: UserModerationAction,
    reason?: string,
  ): Promise<void>;

  setUserTeacherApplicationAccess(userId: string, canApplyAsTeacher: boolean | null): Promise<void>;
}

export const MODERATION_GATEWAY = new InjectionToken<ModerationGateway>('ModerationGateway');

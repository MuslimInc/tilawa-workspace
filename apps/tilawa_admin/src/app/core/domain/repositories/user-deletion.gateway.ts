import { InjectionToken } from '@angular/core';

import {
  DuplicateAccountsDeletionResult,
  DuplicateAccountsLookupResult,
} from '../entities/duplicate-auth-account.entity';
import { UserDeletionAuditEvent } from '../entities/user-deletion-audit.entity';

/**
 * Admin-initiated user deletion — always server-controlled (callables).
 * Backend: functions/src/userDeletion/ (docs/plans/admin_user_deletion_plan.md).
 */
export interface UserDeletionGateway {
  /**
   * Soft-deletes the user: disables the Auth account, revokes tokens, and
   * schedules the hard purge after the grace period. `confirmEmail` must
   * match the target's Auth email, the target uid (when no email), or DELETE.
   */
  requestUserDeletion(targetUserId: string, reason: string, confirmEmail: string): Promise<void>;

  /** Cancels a pending deletion during the grace period. */
  cancelUserDeletion(targetUserId: string, reason: string): Promise<void>;

  /** Reads audit events for a target user, newest first. */
  listAuditEvents(targetUserId: string): Promise<readonly UserDeletionAuditEvent[]>;

  /** Lists every Auth account sharing an email address. */
  lookupDuplicateAccountsByEmail(email: string): Promise<DuplicateAccountsLookupResult>;

  /** Soft-deletes selected duplicate accounts via the existing deletion flow. */
  requestDuplicateAccountsDeletion(input: {
    email: string;
    reason: string;
    confirmEmail: string;
    keepUserId: string;
    deleteUserIds: readonly string[];
    forceDeleteGoogleAccount?: boolean;
  }): Promise<DuplicateAccountsDeletionResult>;
}

export const USER_DELETION_GATEWAY = new InjectionToken<UserDeletionGateway>('UserDeletionGateway');

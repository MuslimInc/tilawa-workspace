import { Inject, Injectable } from '@angular/core';

import {
  USER_DELETION_GATEWAY,
  UserDeletionGateway,
} from '../repositories/user-deletion.gateway';

@Injectable({ providedIn: 'root' })
export class RequestUserDeletionUseCase {
  constructor(
    @Inject(USER_DELETION_GATEWAY)
    private readonly gateway: UserDeletionGateway,
  ) {}

  execute(
    targetUserId: string,
    reason: string,
    confirmEmail: string,
  ): Promise<void> {
    return this.gateway.requestUserDeletion(targetUserId, reason, confirmEmail);
  }
}

@Injectable({ providedIn: 'root' })
export class CancelUserDeletionUseCase {
  constructor(
    @Inject(USER_DELETION_GATEWAY)
    private readonly gateway: UserDeletionGateway,
  ) {}

  execute(targetUserId: string, reason: string): Promise<void> {
    return this.gateway.cancelUserDeletion(targetUserId, reason);
  }
}

@Injectable({ providedIn: 'root' })
export class ListUserDeletionAuditUseCase {
  constructor(
    @Inject(USER_DELETION_GATEWAY)
    private readonly gateway: UserDeletionGateway,
  ) {}

  execute(targetUserId: string) {
    return this.gateway.listAuditEvents(targetUserId);
  }
}

@Injectable({ providedIn: 'root' })
export class LookupDuplicateAccountsByEmailUseCase {
  constructor(
    @Inject(USER_DELETION_GATEWAY)
    private readonly gateway: UserDeletionGateway,
  ) {}

  execute(email: string) {
    return this.gateway.lookupDuplicateAccountsByEmail(email);
  }
}

@Injectable({ providedIn: 'root' })
export class RequestDuplicateAccountsDeletionUseCase {
  constructor(
    @Inject(USER_DELETION_GATEWAY)
    private readonly gateway: UserDeletionGateway,
  ) {}

  execute(input: {
    email: string;
    reason: string;
    confirmEmail: string;
    keepUserId: string;
    deleteUserIds: readonly string[];
    forceDeleteGoogleAccount?: boolean;
  }) {
    return this.gateway.requestDuplicateAccountsDeletion(input);
  }
}


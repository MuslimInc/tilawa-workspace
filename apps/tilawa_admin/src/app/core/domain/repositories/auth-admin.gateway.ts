import { InjectionToken } from '@angular/core';

export interface AuthAdminGateway {
  lookupUserAuthMetadata(userIds: readonly string[]): Promise<{
    readonly adminUserIds: readonly string[];
    readonly authBackedUserIds: readonly string[];
  }>;
  lookupAdminUserIds(userIds: readonly string[]): Promise<readonly string[]>;
  lookupAuthBackedUserIds(userIds: readonly string[]): Promise<readonly string[]>;
}

export const AUTH_ADMIN_GATEWAY = new InjectionToken<AuthAdminGateway>('AuthAdminGateway');

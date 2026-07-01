import { Injectable, inject } from '@angular/core';
import { Functions, httpsCallable } from '@angular/fire/functions';

import { AuthAdminGateway } from '../../domain/repositories/auth-admin.gateway';

interface LookupUserAdminClaimsResult {
  adminUserIds?: string[];
  authBackedUserIds?: string[];
}

const MAX_USER_IDS_PER_REQUEST = 100;

@Injectable({ providedIn: 'root' })
export class FirebaseAuthAdminGateway implements AuthAdminGateway {
  private readonly functions = inject(Functions);

  async lookupUserAuthMetadata(
    userIds: readonly string[],
  ): Promise<{
    adminUserIds: string[];
    authBackedUserIds: string[];
  }> {
    return this.lookupUserClaims(userIds);
  }

  async lookupAdminUserIds(
    userIds: readonly string[],
  ): Promise<readonly string[]> {
    return (await this.lookupUserClaims(userIds)).adminUserIds;
  }

  async lookupAuthBackedUserIds(
    userIds: readonly string[],
  ): Promise<readonly string[]> {
    return (await this.lookupUserClaims(userIds)).authBackedUserIds;
  }

  private async lookupUserClaims(
    userIds: readonly string[],
  ): Promise<{ adminUserIds: string[]; authBackedUserIds: string[] }> {
    const uniqueIds = [...new Set(userIds.map((uid) => uid.trim()).filter(Boolean))];
    if (uniqueIds.length === 0) {
      return { adminUserIds: [], authBackedUserIds: [] };
    }

    const adminUserIds = new Set<string>();
    const authBackedUserIds = new Set<string>();
    for (let index = 0; index < uniqueIds.length; index += MAX_USER_IDS_PER_REQUEST) {
      const chunk = uniqueIds.slice(index, index + MAX_USER_IDS_PER_REQUEST);
      const chunkClaims = await this.lookupUserClaimsChunk(chunk);
      for (const uid of chunkClaims.adminUserIds) {
        adminUserIds.add(uid);
      }
      for (const uid of chunkClaims.authBackedUserIds) {
        authBackedUserIds.add(uid);
      }
    }

    return {
      adminUserIds: [...adminUserIds],
      authBackedUserIds: [...authBackedUserIds],
    };
  }

  private async lookupUserClaimsChunk(
    userIds: readonly string[],
  ): Promise<{ adminUserIds: string[]; authBackedUserIds: string[] }> {
    const callable = httpsCallable<
      { userIds: string[] },
      LookupUserAdminClaimsResult
    >(this.functions, 'lookupUserAdminClaims');

    try {
      const result = await callable({ userIds: [...userIds] });
      const authBackedUserIds =
        result.data.authBackedUserIds !== undefined
          ? (result.data.authBackedUserIds ?? []).map(String)
          : [...userIds];
      return {
        adminUserIds: (result.data.adminUserIds ?? []).map(String),
        authBackedUserIds,
      };
    } catch (error) {
      throw new Error(this.toErrorMessage(error));
    }
  }

  private toErrorMessage(error: unknown): string {
    if (
      typeof error === 'object' &&
      error !== null &&
      'message' in error &&
      typeof (error as { message: unknown }).message === 'string'
    ) {
      return (error as { message: string }).message;
    }

    return 'Failed to resolve admin users.';
  }
}


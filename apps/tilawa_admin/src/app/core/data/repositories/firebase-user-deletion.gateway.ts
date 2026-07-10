import { Injectable, inject } from '@angular/core';
import {
  Firestore,
  collection,
  getDocs,
  limit,
  orderBy,
  query,
  where,
} from '@angular/fire/firestore';
import { Functions, httpsCallable } from '@angular/fire/functions';

import {
  DuplicateAccountsDeletionResult,
  DuplicateAccountsLookupResult,
  DuplicateAuthAccount,
} from '../../domain/entities/duplicate-auth-account.entity';
import { UserDeletionAuditEvent } from '../../domain/entities/user-deletion-audit.entity';
import { UserDeletionGateway } from '../../domain/repositories/user-deletion.gateway';
import { readTimestamp } from '../mappers/quran-sessions.mapper';
import { mapCallableFunctionError } from './callable-function-error.util';

@Injectable({ providedIn: 'root' })
export class FirebaseUserDeletionGateway implements UserDeletionGateway {
  private readonly functions = inject(Functions);
  private readonly firestore = inject(Firestore);

  async requestUserDeletion(
    targetUserId: string,
    reason: string,
    confirmEmail: string,
  ): Promise<void> {
    await this.invokeCallable('requestUserDeletion', {
      targetUserId,
      reason,
      confirmEmail,
    });
  }

  async cancelUserDeletion(targetUserId: string, reason: string): Promise<void> {
    await this.invokeCallable('cancelUserDeletion', { targetUserId, reason });
  }

  async listAuditEvents(targetUserId: string): Promise<readonly UserDeletionAuditEvent[]> {
    const snapshot = await getDocs(
      query(
        collection(this.firestore, 'user_deletion_audit'),
        where('targetUserId', '==', targetUserId),
        orderBy('createdAt', 'desc'),
        limit(20),
      ),
    );

    return snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        targetUserId: String(data['targetUserId'] ?? targetUserId),
        action: String(data['action'] ?? ''),
        actorUid: String(data['actorUid'] ?? ''),
        reason: typeof data['reason'] === 'string' ? data['reason'] : null,
        createdAt: readTimestamp(data['createdAt']),
      };
    });
  }

  async lookupDuplicateAccountsByEmail(email: string): Promise<DuplicateAccountsLookupResult> {
    const result = await this.invokeCallableWithData<DuplicateAccountsLookupResult>(
      'lookupDuplicateAccountsByEmail',
      { email },
    );
    return {
      email: result.email,
      authScanTruncated: result.authScanTruncated === true,
      suggestedKeepGooglePlan: result.suggestedKeepGooglePlan ?? null,
      accounts: (result.accounts ?? []).map((account) => mapDuplicateAccount(account)),
    };
  }

  async requestDuplicateAccountsDeletion(input: {
    email: string;
    reason: string;
    confirmEmail: string;
    keepUserId: string;
    deleteUserIds: readonly string[];
    forceDeleteGoogleAccount?: boolean;
  }): Promise<DuplicateAccountsDeletionResult> {
    return this.invokeCallableWithData<DuplicateAccountsDeletionResult>(
      'requestDuplicateAccountsDeletion',
      input,
    );
  }

  private async invokeCallableWithData<T>(name: string, data: Record<string, unknown>): Promise<T> {
    const callable = httpsCallable<Record<string, unknown>, T>(this.functions, name);

    try {
      const result = await callable(data);
      return result.data;
    } catch (error) {
      throw new Error(this.toErrorMessage(error, name));
    }
  }

  private async invokeCallable(name: string, data: Record<string, unknown>): Promise<void> {
    const callable = httpsCallable(this.functions, name);

    try {
      await callable(data);
    } catch (error) {
      throw new Error(this.toErrorMessage(error, name));
    }
  }

  private toErrorMessage(error: unknown, functionName: string): string {
    return mapCallableFunctionError(error, functionName);
  }
}

function mapDuplicateAccount(raw: DuplicateAuthAccount): DuplicateAuthAccount {
  return {
    uid: String(raw.uid),
    email: raw.email ?? null,
    disabled: raw.disabled === true,
    providerIds: Array.isArray(raw.providerIds) ? raw.providerIds.map(String) : [],
    hasGoogleProvider: raw.hasGoogleProvider === true,
    creationTime: raw.creationTime ?? null,
    lastSignInTime: raw.lastSignInTime ?? null,
    firestoreAccountStatus: raw.firestoreAccountStatus ?? null,
    firestoreProfileStatus: raw.firestoreProfileStatus ?? null,
    firestoreHasUserDoc: raw.firestoreHasUserDoc === true,
    deletionStateStatus: raw.deletionStateStatus ?? null,
    isFirestoreOnly: raw.isFirestoreOnly === true,
  };
}

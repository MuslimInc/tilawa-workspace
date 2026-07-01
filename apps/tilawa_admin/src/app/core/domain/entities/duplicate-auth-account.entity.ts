export interface DuplicateAuthAccount {
  readonly uid: string;
  readonly email: string | null;
  readonly disabled: boolean;
  readonly providerIds: readonly string[];
  readonly hasGoogleProvider: boolean;
  readonly creationTime: string | null;
  readonly lastSignInTime: string | null;
  readonly firestoreAccountStatus: string | null;
  readonly firestoreProfileStatus: string | null;
  readonly firestoreHasUserDoc: boolean;
  readonly deletionStateStatus: string | null;
  readonly isFirestoreOnly: boolean;
}

export interface DuplicateAccountsLookupResult {
  readonly email: string;
  readonly accounts: readonly DuplicateAuthAccount[];
  readonly authScanTruncated: boolean;
  readonly suggestedKeepGooglePlan: {
    readonly keepUserId: string;
    readonly deleteUserIds: readonly string[];
  } | null;
}

export interface DuplicateAccountsDeletionResult {
  readonly email: string;
  readonly keepUserId: string;
  readonly results: readonly {
    readonly targetUserId: string;
    readonly status: 'pending_deletion' | 'already_pending' | 'failed' | 'purged';
    readonly purgeAfter?: string;
    readonly auditId?: string;
    readonly message?: string;
  }[];
}


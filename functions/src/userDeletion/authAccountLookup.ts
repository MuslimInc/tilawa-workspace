import { UserRecord, getAuth } from "firebase-admin/auth";
import { Firestore } from "firebase-admin/firestore";

import { USER_DELETION_STATE_COLLECTION } from "./deletionManifest";

/** Firebase Auth provider id for Google Sign-In. */
export const GOOGLE_PROVIDER_ID = "google.com";

/** Caps Auth listUsers scans for duplicate-email lookup (admin-only). */
export const LIST_USERS_PAGE_SIZE = 1000;
export const LIST_USERS_MAX_PAGES = 50;

export interface AuthAccountSummary {
  uid: string;
  email: string | null;
  disabled: boolean;
  customClaims: Record<string, unknown>;
  providerIds: readonly string[];
  hasGoogleProvider: boolean;
  creationTime: string | null;
  lastSignInTime: string | null;
  firestoreAccountStatus: string | null;
  firestoreProfileStatus: string | null;
  firestoreHasUserDoc: boolean;
  deletionStateStatus: string | null;
  /** Firestore user doc exists but Firebase Auth has no account for this uid. */
  isFirestoreOnly: boolean;
}

export interface AuthAccountLookupResult {
  email: string;
  accounts: AuthAccountSummary[];
  /** True when listUsers scan hit the page cap before finishing. */
  authScanTruncated: boolean;
}

export interface AuthAccountLookup {
  findUsersByEmail(
    email: string,
  ): Promise<{ users: UserRecord[]; truncated: boolean }>;
  getUserByEmail(email: string): Promise<UserRecord | null>;
  getUser(uid: string): Promise<UserRecord | null>;
}

function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

function emailVariants(email: string): string[] {
  const trimmed = email.trim();
  const lower = trimmed.toLowerCase();
  return trimmed === lower ? [lower] : [lower, trimmed];
}

function isUserNotFound(error: unknown): boolean {
  return (
    typeof error === "object" &&
    error !== null &&
    (error as { code?: string }).code === "auth/user-not-found"
  );
}

export function userRecordToSummary(
  record: UserRecord,
  firestore?: FirebaseFirestore.DocumentData | null,
  deletionStateStatus?: string | null,
): AuthAccountSummary {
  const providerIds = record.providerData.map((provider) => provider.providerId);
  const profile =
    (firestore?.quranSessionsProfile as Record<string, unknown> | undefined) ??
    null;
  return {
    uid: record.uid,
    email: record.email ?? null,
    disabled: record.disabled,
    customClaims: record.customClaims ?? {},
    providerIds,
    hasGoogleProvider: providerIds.includes(GOOGLE_PROVIDER_ID),
    creationTime: record.metadata.creationTime ?? null,
    lastSignInTime: record.metadata.lastSignInTime ?? null,
    firestoreAccountStatus:
      typeof firestore?.accountStatus === "string"
        ? (firestore.accountStatus as string)
        : null,
    firestoreProfileStatus:
      typeof profile?.accountStatus === "string"
        ? (profile.accountStatus as string)
        : null,
    firestoreHasUserDoc: firestore != null,
    deletionStateStatus: deletionStateStatus ?? null,
    isFirestoreOnly: false,
  };
}

export function firestoreOrphanToSummary(
  uid: string,
  firestore: FirebaseFirestore.DocumentData,
  deletionStateStatus?: string | null,
): AuthAccountSummary {
  const profile =
    (firestore.quranSessionsProfile as Record<string, unknown> | undefined) ??
    null;
  return {
    uid,
    email: typeof firestore.email === "string" ? firestore.email : null,
    disabled: false,
    customClaims: {},
    providerIds: [],
    hasGoogleProvider: false,
    creationTime: null,
    lastSignInTime: null,
    firestoreAccountStatus:
      typeof firestore.accountStatus === "string"
        ? (firestore.accountStatus as string)
        : null,
    firestoreProfileStatus:
      typeof profile?.accountStatus === "string"
        ? (profile.accountStatus as string)
        : null,
    firestoreHasUserDoc: true,
    deletionStateStatus: deletionStateStatus ?? null,
    isFirestoreOnly: true,
  };
}

export function adminAuthAccountLookup(): AuthAccountLookup {
  const auth = getAuth();
  return {
    async findUsersByEmail(email: string) {
      const normalized = normalizeEmail(email);
      const users: UserRecord[] = [];
      let pageToken: string | undefined;
      let pages = 0;
      let truncated = false;

      while (pages < LIST_USERS_MAX_PAGES) {
        const page = await auth.listUsers(LIST_USERS_PAGE_SIZE, pageToken);
        for (const user of page.users) {
          if (user.email?.trim().toLowerCase() === normalized) {
            users.push(user);
          }
        }
        pageToken = page.pageToken;
        pages += 1;
        if (!pageToken) {
          break;
        }
      }
      if (pageToken) {
        truncated = true;
      }

      return { users, truncated };
    },
    async getUserByEmail(email) {
      try {
        return await auth.getUserByEmail(normalizeEmail(email));
      } catch (error) {
        if (isUserNotFound(error)) return null;
        throw error;
      }
    },
    async getUser(uid) {
      try {
        return await auth.getUser(uid);
      } catch (error) {
        if (isUserNotFound(error)) return null;
        throw error;
      }
    },
  };
}

async function collectFirestoreUidsByEmail(
  db: Firestore,
  email: string,
): Promise<Set<string>> {
  const uids = new Set<string>();
  for (const variant of emailVariants(email)) {
    const snap = await db
      .collection("users")
      .where("email", "==", variant)
      .get();
    for (const doc of snap.docs) {
      uids.add(doc.id);
    }
  }
  return uids;
}

/**
 * Finds every Auth account (and Firestore-only orphans) sharing an email.
 * Auth scan is paginated; `authScanTruncated` is set when the cap is hit.
 */
export async function lookupAuthAccountsByEmail(input: {
  db: Firestore;
  lookup: AuthAccountLookup;
  email: string;
}): Promise<AuthAccountLookupResult> {
  const normalized = normalizeEmail(input.email);
  if (!normalized || !normalized.includes("@")) {
    throw new Error("invalid-email");
  }

  const [{ users, truncated }, firestoreUids] = await Promise.all([
    input.lookup.findUsersByEmail(normalized),
    collectFirestoreUidsByEmail(input.db, normalized),
  ]);

  const recordsByUid = new Map<string, UserRecord>();
  for (const user of users) {
    recordsByUid.set(user.uid, user);
  }

  for (const uid of firestoreUids) {
    if (recordsByUid.has(uid)) continue;
    const record = await input.lookup.getUser(uid);
    if (record && record.email?.trim().toLowerCase() === normalized) {
      recordsByUid.set(record.uid, record);
    }
  }

  const byEmail = await input.lookup.getUserByEmail(normalized);
  if (byEmail && byEmail.email?.trim().toLowerCase() === normalized) {
    recordsByUid.set(byEmail.uid, byEmail);
  }

  const orphanUids = [...firestoreUids].filter((uid) => !recordsByUid.has(uid));
  const uids = [...recordsByUid.keys(), ...orphanUids];
  const [userSnaps, stateSnaps] = await Promise.all([
    Promise.all(
      uids.map((uid) => input.db.collection("users").doc(uid).get()),
    ),
    Promise.all(
      uids.map((uid) =>
        input.db.collection(USER_DELETION_STATE_COLLECTION).doc(uid).get(),
      ),
    ),
  ]);

  const accounts = uids
    .map((uid, index) => {
      const firestore = userSnaps[index].exists
        ? userSnaps[index].data()!
        : null;
      const deletionStateStatus = stateSnaps[index].exists
        ? (stateSnaps[index].get("status") as string)
        : null;
      const record = recordsByUid.get(uid);
      if (record) {
        return userRecordToSummary(record, firestore, deletionStateStatus);
      }
      if (firestore) {
        return firestoreOrphanToSummary(uid, firestore, deletionStateStatus);
      }
      return null;
    })
    .filter((account): account is AuthAccountSummary => account != null)
    .sort((a, b) => {
      const aTime = a.creationTime ?? "";
      const bTime = b.creationTime ?? "";
      return aTime.localeCompare(bTime);
    });

  return {
    email: normalized,
    accounts,
    authScanTruncated: truncated,
  };
}


import { getAuth } from "firebase-admin/auth";

/**
 * Thin seam over firebase-admin Auth so deletion logic can run against the
 * Firestore-only emulator in integration tests (test:integration starts no
 * Auth emulator) with an in-memory fake.
 */
export interface AuthGatewayUser {
  uid: string;
  email: string | null;
  disabled: boolean;
  customClaims: Record<string, unknown>;
}

export interface AuthGateway {
  /** Returns null when the uid does not exist. */
  getUser(uid: string): Promise<AuthGatewayUser | null>;
  setDisabled(uid: string, disabled: boolean): Promise<void>;
  revokeRefreshTokens(uid: string): Promise<void>;
  /** Missing user counts as success (idempotent purge retries). */
  deleteUser(uid: string): Promise<void>;
}

function isUserNotFound(error: unknown): boolean {
  return (
    typeof error === "object" &&
    error !== null &&
    (error as { code?: string }).code === "auth/user-not-found"
  );
}

export function adminAuthGateway(): AuthGateway {
  const auth = getAuth();
  return {
    async getUser(uid) {
      try {
        const record = await auth.getUser(uid);
        return {
          uid: record.uid,
          email: record.email ?? null,
          disabled: record.disabled,
          customClaims: record.customClaims ?? {},
        };
      } catch (error) {
        if (isUserNotFound(error)) return null;
        throw error;
      }
    },
    async setDisabled(uid, disabled) {
      await auth.updateUser(uid, { disabled });
    },
    async revokeRefreshTokens(uid) {
      await auth.revokeRefreshTokens(uid);
    },
    async deleteUser(uid) {
      try {
        await auth.deleteUser(uid);
      } catch (error) {
        if (isUserNotFound(error)) return;
        throw error;
      }
    },
  };
}

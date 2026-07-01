import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getAuth } from "firebase-admin/auth";

const MAX_USER_IDS = 100;

export async function executeLookupUserAdminClaims(input: {
  userIds: readonly string[];
}): Promise<{ adminUserIds: string[]; authBackedUserIds: string[] }> {
  const userIds = [
    ...new Set(
      input.userIds
        .map((uid) => uid.trim())
        .filter((uid) => uid.length > 0),
    ),
  ];

  if (userIds.length === 0) {
    return { adminUserIds: [], authBackedUserIds: [] };
  }

  if (userIds.length > MAX_USER_IDS) {
    throw new Error("too-many-user-ids");
  }

  const auth = getAuth();
  const page = await auth.getUsers(userIds.map((uid) => ({ uid })));
  const adminUserIds = page.users
    .filter((user) => user.customClaims?.admin === true)
    .map((user) => user.uid);
  const authBackedUserIds = page.users.map((user) => user.uid);

  return { adminUserIds, authBackedUserIds };
}

/**
 * Admin-only: resolves which user IDs have Firebase Auth `{ admin: true }`.
 */
export const lookupUserAdminClaims = onCall(
  { enforceAppCheck: false },
  async (request) => {
    if (!request.auth?.token.admin) {
      throw new HttpsError("permission-denied", "Admin access required.");
    }

    const data = (request.data ?? {}) as { userIds?: unknown };
    const userIds = Array.isArray(data.userIds)
      ? data.userIds.filter((uid): uid is string => typeof uid === "string")
      : [];

    try {
      return await executeLookupUserAdminClaims({ userIds });
    } catch (error) {
      if (error instanceof Error && error.message === "too-many-user-ids") {
        throw new HttpsError(
          "invalid-argument",
          `At most ${MAX_USER_IDS} user IDs are allowed per request.`,
        );
      }
      throw error;
    }
  },
);


import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

type UserModerationAction = "suspend" | "reactivate";

interface ModerateQuranSessionsUserRequest {
  userId: string;
  action: UserModerationAction;
  reason?: string;
}

const profileField = "quranSessionsProfile";

/**
 * Admin-only moderation for Quran Sessions user account status.
 * Requires custom claim `{ admin: true }`.
 */
export const moderateQuranSessionsUser = onCall(
  { enforceAppCheck: false },
  async (request) => {
    if (!request.auth?.token.admin) {
      throw new HttpsError("permission-denied", "Admin access required.");
    }

    const data = request.data as ModerateQuranSessionsUserRequest;
    const userId = data.userId?.trim();
    const action = data.action;

    if (!userId || !action) {
      throw new HttpsError("invalid-argument", "userId and action required.");
    }

    const db = getFirestore();
    const userRef = db.collection("users").doc(userId);
    const userSnap = await userRef.get();

    if (!userSnap.exists) {
      throw new HttpsError("not-found", "User not found.");
    }

    const userData = userSnap.data() ?? {};
    const profile = (userData[profileField] as Record<string, unknown> | undefined) ?? {};

    if (!userData[profileField]) {
      throw new HttpsError("failed-precondition", "User has no Quran Sessions profile.");
    }

    const accountStatus = action === "suspend" ? "suspended" : "active";
    const now = FieldValue.serverTimestamp();

    await userRef.set(
      {
        [profileField]: {
          ...profile,
          accountStatus,
          updatedAt: now,
          ...(data.reason ? { restrictionReason: "adminDecision" } : {}),
        },
      },
      { merge: true },
    );

    return { userId, accountStatus };
  },
);

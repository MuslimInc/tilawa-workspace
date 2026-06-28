import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import {
  buildModerateQuranSessionsUserPatch,
  validateModerateQuranSessionsUserRequest,
} from "./moderateQuranSessionsUserLogic";

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

    let validated;
    try {
      validated = validateModerateQuranSessionsUserRequest(
        request.data as Parameters<typeof validateModerateQuranSessionsUserRequest>[0],
      );
    } catch (error) {
      const message =
        error instanceof Error ? error.message : "Invalid request.";
      throw new HttpsError("invalid-argument", message);
    }

    const { userId, action, reason } = validated;
    const db = getFirestore();
    const userRef = db.collection("users").doc(userId);
    const userSnap = await userRef.get();

    if (!userSnap.exists) {
      throw new HttpsError("not-found", "User not found.");
    }

    const userData = userSnap.data() ?? {};
    const profile =
      (userData[profileField] as Record<string, unknown> | undefined) ?? {};

    if (!userData[profileField]) {
      throw new HttpsError(
        "failed-precondition",
        "User has no Quran Sessions profile.",
      );
    }

    const patch = buildModerateQuranSessionsUserPatch({
      existingProfile: profile,
      action,
      reason,
    });
    const now = FieldValue.serverTimestamp();
    const profilePrefix = `${profileField}.`;

    const updatePayload: Record<string, unknown> = {
      [`${profilePrefix}accountStatus`]: patch.accountStatus,
      [`${profilePrefix}updatedAt`]: now,
    };

    if (patch.restrictionReason === null) {
      updatePayload[`${profilePrefix}restrictionReason`] = FieldValue.delete();
    } else if (patch.restrictionReason !== undefined) {
      updatePayload[`${profilePrefix}restrictionReason`] = patch.restrictionReason;
    }

    await userRef.update(updatePayload);

    console.info("moderateQuranSessionsUser", {
      adminUid: request.auth.uid,
      userId,
      action,
      accountStatus: patch.accountStatus,
    });

    return { userId, accountStatus: patch.accountStatus };
  },
);

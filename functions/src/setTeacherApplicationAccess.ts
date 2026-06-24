import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

type TeacherApplicationAccessMode = "all" | "none" | "allowlist" | "rules";

interface SetTeacherApplicationAccessRequest {
  userId?: string;
  canApplyAsTeacher?: boolean | null;
  policy?: {
    mode?: TeacherApplicationAccessMode;
    allowlistUserIds?: string[];
    rules?: {
      countryCodes?: string[];
      roles?: string[];
      emails?: string[];
      phones?: string[];
    };
  };
}

const profileField = "quranSessionsProfile";
const policyCollection = "quran_session_platform_config";
const globalDocId = "global";
const policyField = "teacherApplicationAccess";

/**
 * Admin-only control for teacher-application entry visibility.
 * Requires custom claim `{ admin: true }`.
 */
export const setTeacherApplicationAccess = onCall(
  { enforceAppCheck: false },
  async (request) => {
    if (!request.auth?.token.admin) {
      throw new HttpsError("permission-denied", "Admin access required.");
    }

    const data = request.data as SetTeacherApplicationAccessRequest;
    const db = getFirestore();
    const now = FieldValue.serverTimestamp();

    if (data.userId?.trim()) {
      const userId = data.userId.trim();
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

      const patch: Record<string, unknown> = {
        ...profile,
        updatedAt: now,
      };

      if (data.canApplyAsTeacher === null) {
        delete patch.canApplyAsTeacher;
      } else if (typeof data.canApplyAsTeacher === "boolean") {
        patch.canApplyAsTeacher = data.canApplyAsTeacher;
      } else {
        throw new HttpsError(
          "invalid-argument",
          "canApplyAsTeacher must be boolean or null.",
        );
      }

      await userRef.set({ [profileField]: patch }, { merge: true });
      return { userId, canApplyAsTeacher: data.canApplyAsTeacher ?? null };
    }

    if (data.policy) {
      const mode = data.policy.mode ?? "none";
      if (!["all", "none", "allowlist", "rules"].includes(mode)) {
        throw new HttpsError("invalid-argument", "Invalid policy mode.");
      }

      await db.collection(policyCollection).doc(globalDocId).set(
        {
          [policyField]: {
            mode,
            allowlistUserIds: data.policy.allowlistUserIds ?? [],
            rules: {
              countryCodes: data.policy.rules?.countryCodes ?? [],
              roles: data.policy.rules?.roles ?? [],
              emails: data.policy.rules?.emails ?? [],
              phones: data.policy.rules?.phones ?? [],
            },
            updatedAt: now,
          },
          updatedAt: now,
        },
        { merge: true },
      );

      return { policyMode: mode };
    }

    throw new HttpsError(
      "invalid-argument",
      "Provide userId + canApplyAsTeacher or policy.",
    );
  },
);

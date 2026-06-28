export type UserModerationAction = "suspend" | "reactivate";

export interface ModerateQuranSessionsUserRequest {
  userId?: string;
  action?: UserModerationAction | string;
  reason?: string;
}

export interface ModerateQuranSessionsUserPatch {
  accountStatus: "active" | "suspended";
  /** `null` means delete the field on reactivate. */
  restrictionReason?: string | null;
  [key: string]: unknown;
}

export function validateModerateQuranSessionsUserRequest(
  data: ModerateQuranSessionsUserRequest,
): { userId: string; action: UserModerationAction; reason?: string } {
  const userId = data.userId?.trim();
  const action = data.action;

  if (!userId) {
    throw new Error("userId required.");
  }
  if (!action) {
    throw new Error("action required.");
  }
  if (action !== "suspend" && action !== "reactivate") {
    throw new Error("Invalid action.");
  }

  return { userId, action, reason: data.reason?.trim() || undefined };
}

export function buildModerateQuranSessionsUserPatch(input: {
  existingProfile: Record<string, unknown>;
  action: UserModerationAction;
  reason?: string;
}): ModerateQuranSessionsUserPatch {
  const accountStatus = input.action === "suspend" ? "suspended" : "active";
  const patch: ModerateQuranSessionsUserPatch = {
    ...input.existingProfile,
    accountStatus,
  };

  if (input.action === "suspend" && input.reason) {
    patch.restrictionReason = "adminDecision";
  } else if (input.action === "reactivate") {
    patch.restrictionReason = null;
  }

  return patch;
}

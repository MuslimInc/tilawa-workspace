export type FcmMigrationAction = "skip" | "set";

export interface FcmMigrationDecision {
  action: FcmMigrationAction;
  reason: string;
  selectedToken: string | null;
  platform: string | null;
  legacyDocCount: number;
}

export interface LegacyFcmTokenDoc {
  id: string;
  token?: string;
  platform?: string;
  createdAtMillis: number;
}

export function decideFcmTokenMigration(input: {
  existingActiveToken?: unknown;
  legacyDocs: LegacyFcmTokenDoc[];
}): FcmMigrationDecision {
  const existing = input.existingActiveToken;
  if (typeof existing === "string" && existing.length > 0) {
    return {
      action: "skip",
      reason: "embedded_token_already_set",
      selectedToken: existing,
      platform: null,
      legacyDocCount: 0,
    };
  }

  if (input.legacyDocs.length === 0) {
    return {
      action: "skip",
      reason: "no_legacy_tokens",
      selectedToken: null,
      platform: null,
      legacyDocCount: 0,
    };
  }

  const newest = [...input.legacyDocs].sort(
    (a, b) => b.createdAtMillis - a.createdAtMillis,
  )[0];
  const token = String(newest.token ?? newest.id);
  const platform = String(newest.platform ?? "android");

  return {
    action: "set",
    reason: "newest_legacy_token",
    selectedToken: token,
    platform,
    legacyDocCount: input.legacyDocs.length,
  };
}

/**
 * Deterministic winner when two devices register in the same starting epoch.
 * Mirrors [planDeviceRegistration] serial transaction semantics.
 */
export function resolveRaceWinnerDevice(
  registrations: Array<{ deviceId: string; order: number }>,
): string {
  const sorted = [...registrations].sort((a, b) => a.order - b.order);
  return sorted.at(-1)?.deviceId ?? "";
}

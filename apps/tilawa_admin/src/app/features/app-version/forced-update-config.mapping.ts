export interface ForcedUpdateConfig {
  androidMinBuildNumber: number;
  iosMinBuildNumber: number;
}

/** Pure Firestore field → domain mapping (shared with unit tests). */
export function mapForcedUpdateConfig(
  raw: Record<string, unknown> | undefined,
): ForcedUpdateConfig {
  return {
    androidMinBuildNumber: readForcedUpdateInt(raw?.['android_min_build_number']) ?? 0,
    iosMinBuildNumber: readForcedUpdateInt(raw?.['ios_min_build_number']) ?? 0,
  };
}

export function readForcedUpdateInt(value: unknown): number | null {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return Math.trunc(value);
  }
  if (typeof value === 'string') {
    const parsed = Number.parseInt(value.trim(), 10);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

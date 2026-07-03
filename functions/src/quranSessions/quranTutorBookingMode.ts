export type QuranTutorBookingMode = "autoConfirm" | "requiresTutorApproval";

const VALID_MODES: ReadonlySet<string> = new Set([
  "autoConfirm",
  "requiresTutorApproval",
]);

export function distributionDefaultBookingMode(): QuranTutorBookingMode {
  return "requiresTutorApproval";
}

export function resolveQuranTutorBookingMode(
  platformConfig: Record<string, unknown> | undefined,
): QuranTutorBookingMode {
  const raw = platformConfig?.quranTutorBookingMode;
  if (typeof raw === "string" && VALID_MODES.has(raw)) {
    return raw as QuranTutorBookingMode;
  }
  const fallback = distributionDefaultBookingMode();
  if (raw != null && raw !== "") {
    console.warn(
      JSON.stringify({
        event: "booking_mode_fallback",
        invalidValue: raw,
        resolvedMode: fallback,
      }),
    );
  } else if (platformConfig != null && !("quranTutorBookingMode" in platformConfig)) {
    console.warn(
      JSON.stringify({
        event: "booking_mode_fallback",
        reason: "missing_field",
        resolvedMode: fallback,
      }),
    );
  }
  return fallback;
}

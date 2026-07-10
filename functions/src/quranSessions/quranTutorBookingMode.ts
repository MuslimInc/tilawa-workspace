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
  // `bookingMode` is canonical. The other names are read-only migration
  // aliases for existing seeded docs and older admin clients.
  const raw =
    platformConfig?.bookingMode ??
    platformConfig?.quranTutorBookingMode ??
    platformConfig?.defaultBookingMode;
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
  } else if (
    platformConfig != null &&
    !("bookingMode" in platformConfig) &&
    !("quranTutorBookingMode" in platformConfig) &&
    !("defaultBookingMode" in platformConfig)
  ) {
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

import { Firestore, Timestamp, DocumentSnapshot } from "firebase-admin/firestore";

import { lifecycleError } from "./lifecycleErrors";
import {
  DEFAULT_MAX_CONCURRENT_UPCOMING_PER_STUDENT,
  DEFAULT_MIN_BOOKING_NOTICE_MS,
  DEFAULT_TUTOR_APPROVAL_SLA_MS,
  JOIN_WINDOW_LEAD_MS,
} from "./platformSchedulingPolicy";
import {
  type QuranTutorBookingMode,
  resolveQuranTutorBookingMode,
} from "./quranTutorBookingMode";
import { isPaymentProviderEnabled } from "./payment/envGate";

export type SessionModePolicy = "videoOnly" | "freeBeta";

export interface ResolvedMarketPolicy {
  countryCode: string;
  cityId: string;
  marketEnabled: boolean;
  cityEnabled: boolean;
  sessionFeeAmount: number;
  currencyCode: string;
  bookingMode: QuranTutorBookingMode;
  genderMatchingEnabled: boolean;
  teacherWhitelist: readonly string[] | null;
  tutorApprovalSlaMs: number;
  minBookingNoticeMs: number;
  maxConcurrentUpcomingPerStudent: number;
  joinWindowLeadMs: number;
  sessionMode: SessionModePolicy;
  policyVersion: string | null;
  effectiveFrom: Date | null;
  paymentProviderEnabled: boolean;
  manualPaymentEnabled: boolean;
}

function parseTimestamp(raw: unknown): Date | null {
  if (raw instanceof Timestamp) return raw.toDate();
  if (raw && typeof (raw as { toDate?: unknown }).toDate === "function") {
    return (raw as { toDate(): Date }).toDate();
  }
  return null;
}

function positiveNumber(raw: unknown, fallback: number): number {
  if (typeof raw !== "number" || !Number.isFinite(raw) || raw <= 0) {
    return fallback;
  }
  return raw;
}

function resolveSessionMode(raw: unknown): SessionModePolicy {
  return raw === "freeBeta" ? "freeBeta" : "videoOnly";
}

function resolveCityFee(
  policyData: Record<string, unknown>,
  cityData: Record<string, unknown> | null,
  cityId: string,
): number {
  const citiesArray = policyData.cities as Record<string, unknown>[] | undefined;
  const arrayCity = citiesArray?.find((c) => c?.cityId === cityId);
  const arrayMin = arrayCity?.minSessionPrice;
  if (typeof arrayMin === "number" && arrayMin > 0) {
    return arrayMin;
  }

  const cityMin = cityData?.minSessionPrice;
  if (typeof cityMin === "number" && cityMin > 0) {
    return cityMin;
  }

  const marketMin = policyData.minSessionPrice;
  if (typeof marketMin === "number" && marketMin > 0) {
    return marketMin;
  }
  return 0;
}

function isCityEnabled(
  policyData: Record<string, unknown>,
  cityData: Record<string, unknown> | null,
  cityId: string,
): boolean {
  const citiesArray = policyData.cities as Record<string, unknown>[] | undefined;
  const arrayCity = citiesArray?.find((c) => c?.cityId === cityId);
  if (arrayCity != null && typeof arrayCity.isEnabled === "boolean") {
    return arrayCity.isEnabled;
  }

  if (cityData != null && typeof cityData.isEnabled === "boolean") {
    return cityData.isEnabled;
  }
  return true;
}

function parseTeacherWhitelist(
  raw: unknown,
): readonly string[] | null {
  if (raw == null) return null;
  if (!Array.isArray(raw)) return null;
  const ids = raw.filter((v): v is string => typeof v === "string" && v.trim() !== "");
  return ids.length > 0 ? ids : null;
}

export async function loadEffectiveMarketPolicy(
  db: Firestore,
  countryCode: string,
  cityId: string,
  platformConfig: Record<string, unknown>,
  now: Date = new Date(),
  // Optional pre-fetched market/city snapshots. Callers that already read these
  // docs (e.g. loadSharedBookingContext, for policy-config validation) pass them
  // in so this resolver does not read the same two docs a second time.
  prefetched?: {
    marketSnap: DocumentSnapshot;
    citySnap: DocumentSnapshot;
  },
): Promise<ResolvedMarketPolicy> {
  const marketRef = db.collection("quran_session_market_configs").doc(countryCode);
  const [marketSnap, citySnap] = prefetched
    ? [prefetched.marketSnap, prefetched.citySnap]
    : await Promise.all([
        marketRef.get(),
        marketRef.collection("cities").doc(cityId).get(),
      ]);
  const marketData = marketSnap.data() ?? {};
  const cityData = citySnap.exists ? (citySnap.data() ?? null) : null;

  let policyData = marketData;
  let policyVersion: string | null =
    (marketData.activePolicyVersion as string | undefined) ?? null;
  let effectiveFrom = parseTimestamp(marketData.policyEffectiveFrom);

  if (policyVersion != null) {
    const versionSnap = await db
      .collection("quran_session_market_configs")
      .doc(countryCode)
      .collection("policy_versions")
      .doc(policyVersion)
      .get();
    if (versionSnap.exists) {
      const versionData = versionSnap.data() ?? {};
      const versionEffective = parseTimestamp(versionData.effectiveFrom);
      if (versionEffective == null || versionEffective.getTime() <= now.getTime()) {
        policyData = { ...marketData, ...versionData };
        effectiveFrom = versionEffective ?? effectiveFrom;
      }
    }
  }

  const marketEnabled = !marketSnap.exists || marketData.isEnabled !== false;
  const cityEnabled = isCityEnabled(policyData, cityData, cityId);
  const sessionFeeAmount = resolveCityFee(policyData, cityData, cityId);
  const currencyCode =
    (policyData.currencyCode as string | undefined) ?? "USD";

  const platformBookingMode = resolveQuranTutorBookingMode(platformConfig);
  const marketBookingModeRaw = policyData.quranTutorBookingMode;
  const bookingMode =
    typeof marketBookingModeRaw === "string" &&
    (marketBookingModeRaw === "autoConfirm" ||
      marketBookingModeRaw === "requiresTutorApproval")
      ? (marketBookingModeRaw as QuranTutorBookingMode)
      : platformBookingMode;

  const slaHours = positiveNumber(
    policyData.tutorApprovalSlaHours,
    DEFAULT_TUTOR_APPROVAL_SLA_MS / (60 * 60 * 1000),
  );

  return {
    countryCode,
    cityId,
    marketEnabled: marketEnabled && cityEnabled,
    cityEnabled,
    sessionFeeAmount,
    currencyCode,
    bookingMode,
    genderMatchingEnabled: policyData.genderMatchingEnabled !== false,
    teacherWhitelist: parseTeacherWhitelist(policyData.teacherWhitelist),
    tutorApprovalSlaMs: slaHours * 60 * 60 * 1000,
    minBookingNoticeMs: positiveNumber(
      policyData.minBookingNoticeMinutes,
      DEFAULT_MIN_BOOKING_NOTICE_MS / (60 * 1000),
    ) * 60 * 1000,
    maxConcurrentUpcomingPerStudent: Math.floor(
      positiveNumber(
        policyData.maxConcurrentUpcomingPerStudent,
        DEFAULT_MAX_CONCURRENT_UPCOMING_PER_STUDENT,
      ),
    ),
    joinWindowLeadMs: positiveNumber(
      policyData.joinWindowLeadMinutes,
      JOIN_WINDOW_LEAD_MS / (60 * 1000),
    ) * 60 * 1000,
    sessionMode: resolveSessionMode(
      policyData.sessionMode ?? platformConfig.sessionMode,
    ),
    policyVersion,
    effectiveFrom,
    paymentProviderEnabled: typeof policyData.paymentProviderEnabled === "boolean" 
      ? policyData.paymentProviderEnabled 
      : isPaymentProviderEnabled(),
    manualPaymentEnabled: policyData.manualPaymentEnabled === true,
  };
}

export interface PolicyConfigValidation {
  valid: boolean;
  missingFields: string[];
  invalidFields: string[];
}

const PLATFORM_REQUIRED_FIELDS = [
  "quranSessionsEnabled",
  "bookingEnabled",
  "sessionMode",
  "childAgeThreshold",
] as const;

const MARKET_REQUIRED_FIELDS = [
  "isEnabled",
  "minSessionPrice",
  "currencyCode",
] as const;

function isNonEmptyString(raw: unknown): raw is string {
  return typeof raw === "string" && raw.trim().length > 0;
}

function isValidBookingMode(raw: unknown): boolean {
  return raw === "autoConfirm" || raw === "requiresTutorApproval";
}

function isValidSessionMode(raw: unknown): boolean {
  return raw === "videoOnly" || raw === "freeBeta";
}

/** Validates platform doc before booking is enabled (fail closed). */
export function validatePlatformConfig(
  data: Record<string, unknown> | undefined,
): PolicyConfigValidation {
  const missingFields: string[] = [];
  const invalidFields: string[] = [];
  const config = data ?? {};

  if (
    config.quranSessionsEnabled === false ||
    config.bookingEnabled === false
  ) {
    return { valid: true, missingFields, invalidFields };
  }

  for (const field of PLATFORM_REQUIRED_FIELDS) {
    if (config[field] == null) {
      missingFields.push(field);
    }
  }
  if (
    config.bookingMode == null &&
    config.quranTutorBookingMode == null &&
    config.defaultBookingMode == null
  ) {
    missingFields.push("bookingMode");
  }

  if (
    config.bookingMode != null &&
    !isValidBookingMode(config.bookingMode)
  ) {
    invalidFields.push("bookingMode");
  }
  if (
    config.quranTutorBookingMode != null &&
    !isValidBookingMode(config.quranTutorBookingMode)
  ) {
    invalidFields.push("quranTutorBookingMode");
  }
  if (
    config.defaultBookingMode != null &&
    !isValidBookingMode(config.defaultBookingMode)
  ) {
    invalidFields.push("defaultBookingMode");
  }
  if (config.sessionMode != null && !isValidSessionMode(config.sessionMode)) {
    invalidFields.push("sessionMode");
  }
  if (
    config.childAgeThreshold != null &&
    (typeof config.childAgeThreshold !== "number" ||
      !Number.isFinite(config.childAgeThreshold) ||
      config.childAgeThreshold <= 0)
  ) {
    invalidFields.push("childAgeThreshold");
  }

  return {
    valid: missingFields.length === 0 && invalidFields.length === 0,
    missingFields,
    invalidFields,
  };
}

/** Validates market doc fields required for authoritative booking policy. */
export function validateMarketConfigForBooking(
  marketData: Record<string, unknown> | undefined,
  cityData: Record<string, unknown> | null,
  cityId: string,
): PolicyConfigValidation {
  const missingFields: string[] = [];
  const invalidFields: string[] = [];
  const config = marketData ?? {};

  for (const field of MARKET_REQUIRED_FIELDS) {
    if (config[field] == null) {
      missingFields.push(field);
    }
  }

  if (typeof config.minSessionPrice !== "number" || config.minSessionPrice < 0) {
    invalidFields.push("minSessionPrice");
  }
  if (config.currencyCode != null && !isNonEmptyString(config.currencyCode)) {
    invalidFields.push("currencyCode");
  }
  if (config.quranTutorBookingMode != null && !isValidBookingMode(config.quranTutorBookingMode)) {
    invalidFields.push("quranTutorBookingMode");
  }

  if (!isCityEnabled(config, cityData, cityId)) {
    invalidFields.push(`cities.${cityId}.isEnabled`);
  }

  return {
    valid: missingFields.length === 0 && invalidFields.length === 0,
    missingFields,
    invalidFields,
  };
}

export function assertBookingPolicyConfigured(input: {
  platformConfig: Record<string, unknown>;
  marketData?: Record<string, unknown>;
  cityData?: Record<string, unknown> | null;
  countryCode: string;
  cityId: string;
  marketDocExists: boolean;
}): void {
  if (
    input.platformConfig.quranSessionsEnabled === false ||
    input.platformConfig.bookingEnabled === false
  ) {
    return;
  }

  const platform = validatePlatformConfig(input.platformConfig);
  if (!platform.valid) {
    throw lifecycleError(
      "policy_not_configured",
      "Platform session policy is not configured.",
      {
        scope: "platform",
        missingFields: platform.missingFields,
        invalidFields: platform.invalidFields,
      },
    );
  }

  if (!input.marketDocExists) {
    throw lifecycleError(
      "policy_not_configured",
      "Market session policy is not configured.",
      {
        scope: "market",
        countryCode: input.countryCode,
        missingFields: [...MARKET_REQUIRED_FIELDS],
      },
    );
  }

  const market = validateMarketConfigForBooking(input.marketData, input.cityData ?? null, input.cityId);
  if (!market.valid) {
    throw lifecycleError(
      "policy_not_configured",
      "Market session policy is incomplete.",
      {
        scope: "market",
        countryCode: input.countryCode,
        cityId: input.cityId,
        missingFields: market.missingFields,
        invalidFields: market.invalidFields,
      },
    );
  }
}

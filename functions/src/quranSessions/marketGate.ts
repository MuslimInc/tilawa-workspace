/**
 * Config-driven market availability gate.
 *
 * Replaces the former hardcoded Egypt-only condition. Availability is resolved
 * from the platform config doc (`quran_session_platform_config/global`) so new
 * markets are opened by configuration alone — never a code change.
 *
 * Resolution rule (identical to the mobile `MarketGatePolicy`):
 *   isMarketEnabled(cc) =
 *     enableForAllMarkets || enabledMarketCodes.includes(cc.toUpperCase())
 */
export interface MarketGatePolicy {
  /** When true, every market is available regardless of `enabledMarketCodes`. */
  enableForAllMarkets: boolean;
  /** Upper-cased ISO 3166-1 alpha-2 codes explicitly enabled, e.g. ["EG"]. */
  enabledMarketCodes: string[];
}

/** Normalizes a raw list into trimmed, upper-cased, non-empty market codes. */
export function normalizeMarketCodes(raw: unknown): string[] {
  if (!Array.isArray(raw)) return [];
  const seen = new Set<string>();
  for (const value of raw) {
    if (typeof value !== "string") continue;
    const code = value.trim().toUpperCase();
    if (code.length > 0) seen.add(code);
  }
  return [...seen];
}

/**
 * Parses the market gate off the platform config doc. Defaults are closed:
 * no `enableForAllMarkets` and an empty allow-list block every market.
 */
export function parseMarketGatePolicy(
  raw: Record<string, unknown> | undefined | null,
): MarketGatePolicy {
  const config = raw ?? {};
  return {
    enableForAllMarkets: config.enableForAllMarkets === true,
    enabledMarketCodes: normalizeMarketCodes(config.enabledMarketCodes),
  };
}

/** The single availability rule shared by every backend enforcement point. */
export function isMarketEnabled(
  gate: MarketGatePolicy,
  countryCode: string | null | undefined,
): boolean {
  if (gate.enableForAllMarkets) return true;
  if (countryCode == null) return false;
  return gate.enabledMarketCodes.includes(countryCode.trim().toUpperCase());
}

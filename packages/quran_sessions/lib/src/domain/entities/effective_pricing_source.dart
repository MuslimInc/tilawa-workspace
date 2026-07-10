/// Provenance of the effective booking price, matching the server-side
/// `feeSnapshot.pricingSource`. Flutter never guesses this — it mirrors the
/// backend quote.
enum EffectivePricingSource {
  teacherOverride,
  marketConfig,
  platformFallback,
  unknown,
  ;

  static EffectivePricingSource fromString(String? raw) {
    return switch (raw) {
      'teacherOverride' => teacherOverride,
      'marketConfig' => marketConfig,
      'platformFallback' => platformFallback,
      _ => unknown,
    };
  }
}

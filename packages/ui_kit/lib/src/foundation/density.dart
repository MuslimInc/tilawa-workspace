/// Density modes for the Tilawa UI Kit.
///
/// Controls the overall spacing, padding, and component sizing
/// throughout the UI. Used as a theme-level configuration.
enum TilawaDensity {
  /// Spacious layout with generous padding.
  /// This is the default and matches all pre-density UI Kit values.
  comfortable,

  /// Condensed layout with reduced spacing (opt-in only).
  /// In Phase 0, this produces the same token values as comfortable.
  /// Future phases will implement explicit compact values per component family.
  compact;

  bool get isCompact => this == TilawaDensity.compact;
}

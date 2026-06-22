/// Resolves trusted, app-owned content that AI-authored nodes reference by id.
///
/// This is the seam that enforces "religious content comes from trusted sources,
/// not the model". A node says `{surah: 2, ayah: 255}`; the resolver turns that
/// into a display label (and, later, ayah text) from local/backend data. The
/// model's own text never reaches an authoritative slot.
abstract interface class TrustedContentResolver {
  /// Human-readable surah name for [surah] (1–114), or null if out of range.
  String? surahName(int surah);

  /// A trusted reference label like "Al-Baqarah · Ayah 255". Never returns
  /// model-authored text.
  String ayahReferenceLabel(int surah, {int? ayah});
}

/// Default resolver backed by an injected surah-name map (sourced from trusted
/// app data, e.g. `tilawa_core` surah names). Falls back to a neutral
/// "Surah N" label so a missing entry still renders something safe.
class DefaultTrustedContentResolver implements TrustedContentResolver {
  const DefaultTrustedContentResolver({
    this._surahNames = const <int, String>{},
  });

  final Map<int, String> _surahNames;

  @override
  String? surahName(int surah) {
    if (surah < 1 || surah > 114) return null;
    return _surahNames[surah];
  }

  @override
  String ayahReferenceLabel(int surah, {int? ayah}) {
    final String name = surahName(surah) ?? 'Surah $surah';
    return ayah == null ? name : '$name · $ayah';
  }
}

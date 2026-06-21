/// Resolves a non-empty public teacher [displayName] from known sources.
///
/// Never uses [applicationBio] as display name — bio maps to [publicBio].
/// Marketplace listings must not rely on placeholder fallbacks; use
/// [ValidateTeacherPublicName] and [TeacherProfileCompleteness] instead.
abstract final class TeacherProfileDisplayNameResolver {
  static const String arabicFallback = 'محفظ قرآن';
  static const String englishFallback = 'Quran Teacher';

  static String localizedFallback({required String languageCode}) =>
      languageCode.startsWith('ar') ? arabicFallback : englishFallback;

  /// Returns true when [name] is a generic placeholder, not a real public name.
  static bool isPlaceholder(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return true;
    if (trimmed.toLowerCase() == 'qt') return true;
    if (trimmed.toLowerCase() == englishFallback.toLowerCase()) return true;
    if (trimmed == arabicFallback) return true;
    return false;
  }

  /// Whether [displayName] may appear in student-facing marketplace UI.
  static bool isMarketplaceVisible(String displayName) {
    final trimmed = displayName.trim();
    return trimmed.isNotEmpty && !isPlaceholder(trimmed);
  }

  static String resolve({
    String? userDisplayName,
    String? applicationDisplayName,
    String languageCode = 'en',
  }) {
    for (final candidate in [applicationDisplayName, userDisplayName]) {
      final trimmed = candidate?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return '';
  }

  /// Returns persisted [displayName] trimmed, without placeholder backfill.
  static String resolveStored({
    required String displayName,
  }) => displayName.trim();

  /// Legacy read path: backfills empty stored names for non-marketplace UI.
  @Deprecated('Use resolveStored; incomplete profiles stay off marketplace')
  static String resolveStoredWithLegacyFallback({
    required String displayName,
    String? userDisplayName,
    String? applicationDisplayName,
    String languageCode = 'en',
  }) {
    final trimmed = displayName.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    for (final candidate in [userDisplayName, applicationDisplayName]) {
      final value = candidate?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return localizedFallback(languageCode: languageCode);
  }
}

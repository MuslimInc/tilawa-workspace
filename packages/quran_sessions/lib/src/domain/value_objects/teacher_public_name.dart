import '../failures/quran_sessions_failure.dart';

/// Validates a teacher's public marketplace display name.
abstract final class ValidateTeacherPublicName {
  static const String field = 'publicDisplayName';

  static const Set<String> _englishPlaceholders = {
    'quran teacher',
    'teacher',
    'test',
    'anonymous',
  };

  static const Set<String> _arabicPlaceholders = {
    'محفظ قرآن',
  };

  /// Returns trimmed name when valid; otherwise `null`.
  static String? normalize(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    if (_isPlaceholder(trimmed)) return null;
    if (trimmed.length >= 3) return trimmed;
    final words = trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.length >= 2) return trimmed;
    return null;
  }

  static bool isValid(String? raw) => normalize(raw) != null;

  static ValidationFailure? failureFor(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return const ValidationFailure(field: field, code: 'required');
    }
    if (_isPlaceholder(trimmed)) {
      return const ValidationFailure(field: field, code: 'placeholder');
    }
    if (trimmed.length >= 3) return null;
    final words = trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.length >= 2) return null;
    return const ValidationFailure(field: field, code: 'too_short');
  }

  static bool _isPlaceholder(String trimmed) {
    final lower = trimmed.toLowerCase();
    if (_englishPlaceholders.contains(lower)) return true;
    return _arabicPlaceholders.contains(trimmed);
  }
}

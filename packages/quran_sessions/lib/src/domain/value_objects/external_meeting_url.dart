import '../failures/quran_sessions_failure.dart';

/// Validates a teacher's external meeting URL (Zoom, Google Meet, Teams, etc.).
abstract final class ValidateExternalMeetingUrl {
  static const String field = 'externalMeetingUrl';

  static ValidationFailure? failureFor(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        uri.scheme.toLowerCase() != 'https' ||
        uri.host.isEmpty ||
        uri.hasFragment) {
      return const ValidationFailure(field: field, code: 'invalid_url');
    }
    return null;
  }

  /// Returns trimmed URL when valid; `null` when empty; throws via [failureFor].
  static String? normalize(String? raw) {
    final failure = failureFor(raw);
    if (failure != null) return null;
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}

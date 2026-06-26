import 'package:characters/characters.dart';

/// Derives one- or two-grapheme initials from a display name.
abstract final class AvatarInitialsFromName {
  /// Honorifics and titles commonly skipped when picking initials.
  static const defaultSkipWords = {'الشيخ', 'أ.', 'د.', 'أ', 'د'};

  /// Returns up to [maxGraphemes] initials from [displayName].
  ///
  /// Skips [skipWords] when multiple words are present. Grapheme-safe for
  /// Arabic and Latin script. Does not insert display separators — apply
  /// [AvatarInitialsDisplay.formatForTextStyle] before rendering.
  static String extract(
    String displayName, {
    Set<String> skipWords = defaultSkipWords,
    int maxGraphemes = 2,
  }) {
    if (maxGraphemes < 1) return '';

    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return '';

    final words = trimmed
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';

    String firstGrapheme(String word) {
      final chars = word.characters;
      return chars.isEmpty ? '' : chars.first;
    }

    if (words.length == 1) {
      return firstGrapheme(words[0]);
    }

    final meaningful = words.where((w) => !skipWords.contains(w)).toList();
    if (meaningful.isEmpty) {
      return firstGrapheme(words.first);
    }
    if (meaningful.length == 1 || maxGraphemes == 1) {
      return firstGrapheme(meaningful[0]);
    }

    return '${firstGrapheme(meaningful[0])}${firstGrapheme(meaningful[1])}';
  }
}

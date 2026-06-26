import 'package:characters/characters.dart';

import 'avatar_initials_separators.dart';

/// Pure script detection and separator insertion for avatar initials.
abstract final class AvatarInitialsScript {
  /// Whether [char] belongs to a common Arabic Unicode block.
  static bool isArabicScriptCharacter(String char) {
    if (char.isEmpty) return false;
    final code = char.runes.first;
    return (code >= 0x0600 && code <= 0x06FF) ||
        (code >= 0x0750 && code <= 0x077F) ||
        (code >= 0x08A0 && code <= 0x08FF) ||
        (code >= 0xFB50 && code <= 0xFDFF) ||
        (code >= 0xFE70 && code <= 0xFEFF);
  }

  /// Whether [rawInitials] is a two-grapheme Arabic pair.
  static bool isArabicInitialPair(String rawInitials) {
    final chars = rawInitials.characters.toList();
    if (chars.length < 2) return false;
    return isArabicScriptCharacter(chars[0]) &&
        isArabicScriptCharacter(chars[1]);
  }

  /// Inserts [separator] between the first two graphemes when both are Arabic.
  ///
  /// Returns [rawInitials] unchanged for Latin pairs, single graphemes, or
  /// empty input. Never inserts a normal space.
  static String insertSeparator(
    String rawInitials, {
    String separator = AvatarInitialsSeparators.hairSpace,
  }) {
    final chars = rawInitials.characters.toList();
    if (chars.length < 2) return rawInitials;

    final first = chars[0];
    final second = chars[1];
    if (!isArabicScriptCharacter(first) || !isArabicScriptCharacter(second)) {
      return rawInitials;
    }

    return '$first$separator$second';
  }
}

/// Unicode space characters for separating Arabic avatar initials.
abstract final class AvatarInitialsSeparators {
  /// Hair space — preferred; smaller than thin space.
  static const hairSpace = '\u200A';

  /// Thin space — fallback when [hairSpace] is not widened by the font.
  static const thinSpace = '\u2009';
}

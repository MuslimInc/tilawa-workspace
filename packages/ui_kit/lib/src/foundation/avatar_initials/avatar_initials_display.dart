import 'package:flutter/painting.dart';

import 'avatar_initials_script.dart';
import 'avatar_initials_separators.dart';

/// Font-aware formatting of avatar initials for on-screen display.
abstract final class AvatarInitialsDisplay {
  /// Formats [rawInitials] for [style], separating Arabic pairs with hair
  /// space or thin space when the font ignores hair space.
  static String formatForTextStyle(String rawInitials, TextStyle style) {
    if (!AvatarInitialsScript.isArabicInitialPair(rawInitials)) {
      return rawInitials;
    }

    return AvatarInitialsScript.insertSeparator(
      rawInitials,
      separator: resolveArabicSeparator(style),
    );
  }

  /// Prefers [AvatarInitialsSeparators.hairSpace]; falls back to
  /// [AvatarInitialsSeparators.thinSpace] when hair space does not widen the
  /// probe ligature for [style].
  static String resolveArabicSeparator(TextStyle style) {
    const probeFirst = 'م';
    const probeSecond = 'ا';
    final hair = AvatarInitialsSeparators.hairSpace;
    final thin = AvatarInitialsSeparators.thinSpace;

    final withHair = TextPainter(
      text: TextSpan(text: '$probeFirst$hair$probeSecond', style: style),
      textDirection: TextDirection.rtl,
      maxLines: 1,
    )..layout();
    final ligated = TextPainter(
      text: TextSpan(text: '$probeFirst$probeSecond', style: style),
      textDirection: TextDirection.rtl,
      maxLines: 1,
    )..layout();

    if (withHair.width > ligated.width) {
      return hair;
    }
    return thin;
  }
}

import 'dart:math' as math;

import 'package:tilawa/l10n/generated/app_localizations.dart';

const String _ltrIsolateStart = '\u2066';
const String _ltrIsolateEnd = '\u2069';

/// Formats a Khatma page range with LTR-isolated numerals for RTL layouts.
///
/// Keeps ranges readable as `1–41` instead of reversing to `41–1` in Arabic.
String formatKhatmaPageRange(
  AppLocalizations l10n,
  int startPage,
  int endPage,
) {
  final int start = math.min(startPage, endPage);
  final int end = math.max(startPage, endPage);
  final String isolatedRange = '$_ltrIsolateStart$start–$end$_ltrIsolateEnd';
  return l10n.khatmaRangePagesFormatted(isolatedRange);
}

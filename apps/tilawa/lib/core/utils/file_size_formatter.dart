import 'dart:math';

import 'package:flutter/widgets.dart';

import '../extensions.dart';

class FileSizeFormatter {
  static String formatBytes(
    BuildContext context,
    int bytes, {
    int decimals = 1,
  }) {
    if (bytes <= 0) {
      return '0 ${context.l10n.fileSizeUnitB}';
    }
    final List<String> suffixes = [
      context.l10n.fileSizeUnitB,
      context.l10n.fileSizeUnitKB,
      context.l10n.fileSizeUnitMB,
      context.l10n.fileSizeUnitGB,
      context.l10n.fileSizeUnitTB,
    ];
    final int i = (log(bytes) / log(1024)).floor();
    if (i == 0) {
      return '$bytes ${suffixes[0]}';
    }
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}

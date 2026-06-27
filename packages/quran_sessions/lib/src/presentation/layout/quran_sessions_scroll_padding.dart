import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Resolves bottom inset for scrollable Quran Sessions lists.
typedef QuranSessionsScrollBottomPaddingBuilder =
    double Function(
      BuildContext context,
    );

/// Default list bottom padding when the host app does not inject chrome offsets.
double quranSessionsDefaultScrollBottomPadding(BuildContext context) {
  final shell = context.shellHostedScrollBottomPadding;
  if (shell > 0) {
    return shell;
  }

  return TilawaComfortableReachPadding.resolve(
        context,
        kind: TilawaComfortableReachKind.floating,
      ) +
      Theme.of(context).tokens.spaceLarge;
}

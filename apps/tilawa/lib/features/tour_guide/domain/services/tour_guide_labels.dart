import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

/// Resolves localized strings for tour chrome (keeps widgets free of l10n).
@lazySingleton
class TourGuideLabels {
  String next(BuildContext context) => context.l10n.tourActionNext;

  String finish(BuildContext context) => context.l10n.tourActionFinish;

  String skip(BuildContext context) => context.l10n.tourActionSkip;

  String stepSemantics(
    BuildContext context, {
    required int current,
    required int total,
  }) {
    return context.l10n.tourStepSemantics(current, total);
  }
}

extension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

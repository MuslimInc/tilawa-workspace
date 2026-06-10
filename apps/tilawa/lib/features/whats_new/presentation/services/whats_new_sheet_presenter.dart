import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/router/app_router.dart';

import '../../domain/entities/changelog_release.dart';
import '../widgets/whats_new_sheet.dart';
import 'whats_new_presenter.dart';

@LazySingleton(as: WhatsNewPresenter)
class WhatsNewSheetPresenter implements WhatsNewPresenter {
  @override
  Future<void> show({
    required ChangelogRelease release,
    required Future<void> Function() onDismissed,
  }) async {
    final BuildContext? context = AppRouter.navigatorKey.currentContext;
    if (context == null) {
      return;
    }

    final String languageCode = Localizations.localeOf(context).languageCode;

    await showWhatsNewSheet(
      context: context,
      release: release,
      highlights: release.highlightsFor(languageCode),
    );

    await onDismissed();
  }
}

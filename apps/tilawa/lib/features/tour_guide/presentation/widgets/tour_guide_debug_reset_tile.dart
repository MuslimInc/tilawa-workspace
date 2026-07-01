import 'package:flutter/material.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/usecases/reset_all_tours.dart';

/// Developer-only control to clear persisted tour completion state.
class TourGuideDebugResetTile extends StatelessWidget {
  const TourGuideDebugResetTile({super.key, this.isLast = false});

  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return TilawaSettingsTile(
      title: l10n.tourDebugResetTitle,
      showDivider: !isLast,
      onTap: () async {
        await getIt<ResetAllTours>()();
        if (!context.mounted) {
          return;
        }
        TilawaFeedback.showToast(
          context,
          message: l10n.tourDebugResetDone,
          variant: TilawaFeedbackVariant.success,
        );
      },
    );
  }
}

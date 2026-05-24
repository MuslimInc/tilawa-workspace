import 'package:flutter/material.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/usecases/reset_all_tours.dart';

/// Developer-only control to clear persisted tour completion state.
class TourGuideDebugResetTile extends StatelessWidget {
  const TourGuideDebugResetTile({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return TilawaCatalogSettingsLinkRow(
      title: l10n.tourDebugResetTitle,
      subtitle: l10n.tourDebugResetSubtitle,
      onTap: () async {
        await getIt<ResetAllTours>()();
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.tourDebugResetDone)),
        );
      },
    );
  }
}

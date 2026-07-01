import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Developer settings entry for the notification debug lab.
class NotificationDebugLabTile extends StatelessWidget {
  const NotificationDebugLabTile({super.key, this.isLast = false});

  final bool isLast;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    final AppLocalizations l10n = AppLocalizations.of(context);
    return TilawaSettingsTile(
      title: l10n.notificationDebugLabTitle,
      showDivider: !isLast,
      onTap: () => const NotificationDebugLabRoute().push(context),
    );
  }
}

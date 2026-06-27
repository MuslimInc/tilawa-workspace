import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../widgets/quran_sessions_scaffold.dart';

/// Light guardian hub — approval entry; full child session list deferred.
class GuardianDashboardScreen extends StatelessWidget {
  const GuardianDashboardScreen({
    super.key,
    required this.onApproveBookings,
  });

  final VoidCallback onApproveBookings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;

    return QuranSessionsScaffold(
      title: l10n.guardianDashboardTitle,
      body: ListView(
        padding: EdgeInsets.all(tokens.spaceLarge),
        children: [
          TilawaCard(
            child: Padding(
              padding: EdgeInsets.all(tokens.spaceMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.guardianDashboardIntroTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: tokens.spaceSmall),
                  Text(
                    l10n.guardianDashboardIntroBody,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: tokens.spaceLarge),
          TilawaButton(
            text: l10n.guardianDashboardApproveAction,
            onPressed: onApproveBookings,
          ),
          SizedBox(height: tokens.spaceMedium),
          TilawaCard(
            child: Padding(
              padding: EdgeInsets.all(tokens.spaceMedium),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    TilawaIcons.info,
                    size: tokens.iconSizeMedium,
                    color: scheme.onSurfaceVariant,
                  ),
                  SizedBox(width: tokens.spaceSmall),
                  Expanded(
                    child: Text(
                      l10n.guardianDashboardDeferredNote,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/domain/home_daily_inspiration_catalog.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_dashboard_card.dart';

/// Passive daily dua card placed below the Athkar compact card.
class HomeDailyDuaCard extends StatelessWidget {
  const HomeDailyDuaCard({super.key});

  @override
  Widget build(BuildContext context) {
    final int catalogIndex = homeDailyInspirationCatalogIndex(DateTime.now());
    final _DailyDuaCopy copy = _resolveCopy(context.l10n, catalogIndex);

    return HomeDashboardCard(
      surface: TilawaCardSurface.raised,
      padding: EdgeInsets.all(context.tokens.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.homeDailyDuaLabel,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: context.tokens.spaceExtraSmall),
          Text(
            copy.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: context.tokens.spaceExtraSmall),
          Text(
            copy.reference,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

_DailyDuaCopy _resolveCopy(AppLocalizations l10n, int index) {
  return switch (index) {
    1 => _DailyDuaCopy(
      body: l10n.homeDailyDuaBody1,
      reference: l10n.homeDailyDuaReference1,
    ),
    2 => _DailyDuaCopy(
      body: l10n.homeDailyDuaBody2,
      reference: l10n.homeDailyDuaReference2,
    ),
    _ => _DailyDuaCopy(
      body: l10n.homeDailyDuaBody,
      reference: l10n.homeDailyDuaReference,
    ),
  };
}

final class _DailyDuaCopy {
  const _DailyDuaCopy({required this.body, required this.reference});

  final String body;
  final String reference;
}

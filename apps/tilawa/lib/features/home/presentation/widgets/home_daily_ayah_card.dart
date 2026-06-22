import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/domain/home_daily_inspiration_catalog.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_daily_ayah_sheet.dart';
import 'home_dashboard_card.dart';

/// Compact daily ayah card for the TODAY layer.
class HomeDailyAyahCard extends StatelessWidget {
  const HomeDailyAyahCard({super.key});

  @override
  Widget build(BuildContext context) {
    final int catalogIndex = homeDailyInspirationCatalogIndex(DateTime.now());
    final _DailyAyahCopy copy = _resolveCopy(context.l10n, catalogIndex);

    return HomeDashboardCard(
      surface: TilawaCardSurface.raised,
      onTap: () => showHomeDailyAyahSheet(
        context,
        catalogIndex: catalogIndex,
      ),
      padding: EdgeInsets.all(context.tokens.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.homeDailyAyahLabel,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: context.tokens.spaceExtraSmall),
          Text(
            copy.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: context.isArabic
                  ? context.tokens.textHeightLoose
                  : Theme.of(context).textTheme.bodyMedium?.height,
              fontWeight: context.isArabic ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
          SizedBox(height: context.tokens.spaceExtraSmall),
          Text(
            copy.reference,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

_DailyAyahCopy _resolveCopy(AppLocalizations l10n, int index) {
  return switch (index) {
    1 => _DailyAyahCopy(
      body: l10n.homeDailyAyahBody1,
      reference: l10n.homeDailyAyahReference1,
    ),
    2 => _DailyAyahCopy(
      body: l10n.homeDailyAyahBody2,
      reference: l10n.homeDailyAyahReference2,
    ),
    _ => _DailyAyahCopy(
      body: l10n.homeDailyAyahBody,
      reference: l10n.homeDailyAyahReference,
    ),
  };
}

final class _DailyAyahCopy {
  const _DailyAyahCopy({required this.body, required this.reference});

  final String body;
  final String reference;
}

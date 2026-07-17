import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/domain/home_daily_inspiration_catalog.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_daily_ayah_sheet.dart';
import 'home_dashboard_card.dart';

/// Compact daily ayah card for the TODAY layer.
class HomeDailyAyahCard extends StatelessWidget {
  const HomeDailyAyahCard({super.key});

  @override
  Widget build(BuildContext context) {
    final int catalogIndex = homeDailyInspirationCatalogIndex(DateTime.now());
    final HomeDailyInspirationEntry entry =
        homeDailyInspirationEntries[catalogIndex];
    final bool arabic = context.isArabic;
    final String body = entry.ayahBody(arabic: arabic);
    final String reference = entry.ayahReference(arabic: arabic);

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
            body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: arabic
                  ? context.tokens.textHeightLoose
                  : Theme.of(context).textTheme.bodyMedium?.height,
              fontWeight: arabic ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
          SizedBox(height: context.tokens.spaceExtraSmall),
          Text(
            reference,
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

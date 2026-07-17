import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/domain/home_daily_inspiration_catalog.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_card.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_section.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Daily ayah and dua in one grouped card with a hairline separator.
class HomeDailyInspirationSection extends StatelessWidget {
  const HomeDailyInspirationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final int catalogIndex = homeDailyInspirationCatalogIndex(DateTime.now());
    final _DailyInspirationCopy copy = _resolveCopy(context.l10n, catalogIndex);

    return HomeDashboardSection(
      title: context.l10n.homeInspirationTitle,
      child: HomeDashboardCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DailyInspirationRow(
              label: context.l10n.homeDailyAyahLabel,
              body: copy.ayahBody,
              reference: copy.ayahReference,
              useArabicTypography: context.isArabic,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceMedium),
              child: TilawaDivider(
                height: tokens.borderWidthThin,
                color: colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
            _DailyInspirationRow(
              label: context.l10n.homeDailyDuaLabel,
              body: copy.duaBody,
              reference: copy.duaReference,
              useArabicTypography: context.isArabic,
            ),
          ],
        ),
      ),
    );
  }
}

_DailyInspirationCopy _resolveCopy(AppLocalizations l10n, int index) {
  return switch (index) {
    1 => _DailyInspirationCopy(
      ayahBody: l10n.homeDailyAyahBody1,
      ayahReference: l10n.homeDailyAyahReference1,
      duaBody: l10n.homeDailyDuaBody1,
      duaReference: l10n.homeDailyDuaReference1,
    ),
    2 => _DailyInspirationCopy(
      ayahBody: l10n.homeDailyAyahBody2,
      ayahReference: l10n.homeDailyAyahReference2,
      duaBody: l10n.homeDailyDuaBody2,
      duaReference: l10n.homeDailyDuaReference2,
    ),
    _ => _DailyInspirationCopy(
      ayahBody: l10n.homeDailyAyahBody,
      ayahReference: l10n.homeDailyAyahReference,
      duaBody: l10n.homeDailyDuaBody,
      duaReference: l10n.homeDailyDuaReference,
    ),
  };
}

final class _DailyInspirationCopy {
  const _DailyInspirationCopy({
    required this.ayahBody,
    required this.ayahReference,
    required this.duaBody,
    required this.duaReference,
  });

  final String ayahBody;
  final String ayahReference;
  final String duaBody;
  final String duaReference;
}

class _DailyInspirationRow extends StatelessWidget {
  const _DailyInspirationRow({
    required this.label,
    required this.body,
    required this.reference,
    required this.useArabicTypography,
  });

  final String label;
  final String body;
  final String reference;
  final bool useArabicTypography;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final TextStyle bodyStyle =
        (useArabicTypography
                ? theme.textTheme.titleLarge
                : theme.textTheme.titleMedium)!
            .copyWith(
              color: colorScheme.onSurface,
              height: useArabicTypography ? 1.55 : 1.4,
              fontWeight: FontWeight.w500,
            );

    return Padding(
      padding: EdgeInsets.all(tokens.spaceMedium),
      child: Column(
        spacing: tokens.spaceSmall,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            body,
            maxLines: useArabicTypography ? 5 : 4,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            style: bodyStyle,
          ),
          Text(
            reference,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

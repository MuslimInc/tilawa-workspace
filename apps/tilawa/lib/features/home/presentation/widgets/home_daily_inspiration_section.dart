import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/domain/home_daily_inspiration_catalog.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_card.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_section.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Daily ayah and dua in one grouped card with a hairline separator.
class HomeDailyInspirationSection extends StatelessWidget {
  const HomeDailyInspirationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final Color dividerColor = colorScheme.outlineVariant;
    final int catalogIndex = homeDailyInspirationCatalogIndex(DateTime.now());
    final _DailyInspirationCopy copy = _resolveCopy(context.l10n, catalogIndex);

    return _EntranceAnimator(
      child: HomeDashboardSection(
        title: context.l10n.homeInspirationTitle,
        subtitle: context.l10n.homeInspirationSubtitle,
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
                  color: dividerColor,
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
      ),
    );
  }
}

/// Entrance animation for the peak moment when scrolled into view.
class _EntranceAnimator extends StatefulWidget {
  const _EntranceAnimator({required this.child});

  final Widget child;

  @override
  State<_EntranceAnimator> createState() => _EntranceAnimatorState();
}

class _EntranceAnimatorState extends State<_EntranceAnimator> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isVisible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: _isVisible ? Offset.zero : const Offset(0, 0.08),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        child: widget.child,
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

    // Reading heights stay in the calm 1.45–1.65 band (not mushaf-loose 2.0).
    final double bodyHeight = useArabicTypography ? 1.55 : 1.45;
    final TextStyle bodyStyle = theme.textTheme.titleLarge!.copyWith(
      color: colorScheme.onSurface,
      height: bodyHeight,
      fontWeight: useArabicTypography ? FontWeight.w500 : FontWeight.w400,
    );

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: tokens.spaceMedium,
        end: tokens.spaceMedium,
        top: tokens.spaceMedium,
        bottom: tokens.spaceMedium,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: tokens.minInteractiveDimension * 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.spaceMedium,
          children: [
            Container(
              width: tokens.spaceExtraSmall,
              height: tokens.spaceExtraLarge + tokens.spaceMedium,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    colorScheme.tertiary.withValues(
                      alpha: tokens.opacitySubtle * 4,
                    ),
                    colorScheme.tertiary.withValues(
                      alpha: tokens.opacitySubtle * 1.5,
                    ),
                  ],
                ),
                borderRadius: BorderRadius.circular(
                  tokens.resolveRadius(family: TilawaRadiusFamily.decorative),
                ),
              ),
            ),
            Expanded(
              child: Column(
                spacing: tokens.spaceSmall,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    spacing: tokens.spaceSmall,
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          reference,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    body,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    style: bodyStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

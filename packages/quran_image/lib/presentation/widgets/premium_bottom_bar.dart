import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/perf_logger.dart';
import '../../domain/domain.dart';

class PremiumBottomBar extends StatelessWidget {
  final PageState state;

  const PremiumBottomBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final sw = PerfLogger.startTimer();
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final l10n = AppLocalizations.of(context);
    final pageLabel =
        l10n?.page(state.displayPage.toString()) ?? 'Page ${state.displayPage}';
    final hizbLabel =
        l10n?.hizb(state.hizbNumber) ?? 'Hizb ${state.hizbNumber}';

    final bottomBar = Semantics(
      container: true,
      label: '$pageLabel, $hizbLabel',
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.spaceExtraLarge,
          tokens.spaceTiny,
          tokens.spaceExtraLarge,
          tokens.spaceTiny,
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            spacing: tokens.spaceMedium,
            children: [
              const Expanded(child: _MushafFooterRule(dotNearMedallion: true)),
              _PageNumberMedallion(pageNumber: state.displayPage),
              const Expanded(child: _MushafFooterRule(dotNearMedallion: false)),
            ],
          ),
        ),
      ),
    );

    PerfLogger.logElapsed(
      sw,
      widgetName: 'PremiumBottomBar',
      message: 'build displayPage=${state.displayPage}',
    );
    return bottomBar;
  }
}

class _MushafFooterRule extends StatelessWidget {
  const _MushafFooterRule({required this.dotNearMedallion});

  final bool dotNearMedallion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final color = theme.colorScheme.primary.withValues(
      alpha: tokens.opacityMedium,
    );

    final divider = Expanded(
      child: Divider(
        height: tokens.spaceSmall,
        thickness: tokens.borderWidthThin,
        color: color,
      ),
    );
    final dot = Container(
      width: tokens.spaceExtraSmall,
      height: tokens.spaceExtraSmall,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    final gap = SizedBox(width: tokens.spaceSmall);

    return Row(
      children: dotNearMedallion ? [divider, gap, dot] : [dot, gap, divider],
    );
  }
}

class _PageNumberMedallion extends StatelessWidget {
  const _PageNumberMedallion({required this.pageNumber});

  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final medallionSize = tokens.iconSizeLarge;

    return SizedBox.square(
      dimension: medallionSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: tokens.opacityGlass),
          shape: BoxShape.circle,
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: tokens.opacityMedium),
            width: tokens.borderWidthThin,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: tokens.opacitySubtle),
              blurRadius: tokens.blurGlass,
              offset: tokens.shadowOffsetSmall,
            ),
          ],
        ),
        child: Center(
          child: Text(
            _toEasternArabicDigits(pageNumber),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

String _toEasternArabicDigits(int value) {
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return value
      .toString()
      .split('')
      .map((character) => digits[int.parse(character)])
      .join();
}

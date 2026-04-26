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
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    final bottomBar = Container(
      margin: EdgeInsets.all(tokens.spaceLarge),
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceTiny,
        vertical: tokens.spaceTiny,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: tokens.opacityMedium),
        ),
      ),
      child: Row(
        children: [
          // Page Number
          _PageNumber(pageNumber: state.displayPage),
          const Spacer(),
          // Juz & Hizb
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n?.hizb(state.hizbNumber) ?? 'Hizb ${state.hizbNumber}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
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

class _PageNumber extends StatelessWidget {
  const _PageNumber({required this.pageNumber});

  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.all(tokens.spaceExtraSmall),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: tokens.opacitySubtle),
        shape: BoxShape.circle,
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: tokens.opacityMedium),
          strokeAlign: BorderSide.strokeAlignOutside,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Text(
          pageNumber.toString(),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

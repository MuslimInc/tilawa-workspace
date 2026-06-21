import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../l10n/quran_image_localizations.dart';
import '../../core/perf_logger.dart';
import '../../domain/domain.dart';

/// Bottom bar matching the Ayah app layout:
/// - Hizb label at the bottom-start (left in LTR / right in RTL)
/// - Page number cartouche at the bottom-end (right in LTR / left in RTL)
/// - No horizontal rules — clean, minimal
class PremiumBottomBar extends StatelessWidget {
  final PageState state;

  const PremiumBottomBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    PerfLogger.markBuild('PremiumBottomBar');
    final sw = PerfLogger.startTimer();
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final l10n = QuranImageLocalizations.of(context);
    final pageLabel =
        l10n.page(state.displayPage.toString()) ?? 'Page ${state.displayPage}';
    final hizbLabel = l10n.hizb(state.hizbNumber) ?? 'Hizb ${state.hizbNumber}';
    final primaryColor = theme.colorScheme.primary;

    final bottomBar = Semantics(
      container: true,
      label: '$pageLabel, $hizbLabel',
      child: Padding(
        padding: EdgeInsets.only(
          left: tokens.spaceSmall,
          right: tokens.spaceSmall,
          bottom: tokens.spaceExtraSmall,
          top: tokens.spaceTiny,
        ),
        // Force LTR so hizb is always on the left and page number on the right,
        // matching the Ayah app layout regardless of locale direction.
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Hizb label — bottom left
              Text(
                hizbLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Page number cartouche — bottom right
              _PageNumberCartouche(
                pageNumber: state.displayPage,
                color: primaryColor,
              ),
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

/// Oval cartouche frame around the page number, matching Ayah app style.
class _PageNumberCartouche extends StatelessWidget {
  const _PageNumberCartouche({
    required this.pageNumber,
    required this.color,
  });

  final int pageNumber;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.06),
      ),
      child: Text(
        _toEasternArabicDigits(pageNumber),
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          height: 1.2,
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

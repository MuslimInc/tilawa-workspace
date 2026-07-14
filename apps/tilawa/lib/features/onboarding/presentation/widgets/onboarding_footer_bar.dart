import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Thumb-reach chrome: primary + reserved secondary (Back).
///
/// Page dots live in the content band so the primary CTA Y matches Welcome
/// and PrayerAlerts. Footer for [OnboardingScreen] inside [TilawaThumbReachLayout].
class OnboardingFooterBar extends StatelessWidget {
  const OnboardingFooterBar({
    super.key,
    required this.pageCount,
    required this.currentPage,
    required this.onBack,
    required this.onNext,
    required this.onComplete,
    required this.nextLabel,
    required this.completeLabel,
    required this.backLabel,
  });

  final int pageCount;
  final int currentPage;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onComplete;
  final String nextLabel;
  final String completeLabel;
  final String backLabel;

  bool get _isLastPage => currentPage == pageCount - 1;
  bool get _canGoBack => currentPage > 0;

  String get _primaryLabel => _isLastPage ? completeLabel : nextLabel;

  VoidCallback get _onPrimary => _isLastPage ? onComplete : onNext;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return TilawaThumbReachActions(
      showSecondary: _canGoBack,
      primary: TilawaButton(
        text: _primaryLabel,
        variant: TilawaButtonVariant.primary,
        semanticLabel: _primaryLabel,
        foregroundColor: colorScheme.onPrimary,
        onPressed: _onPrimary,
        isFullWidth: true,
      ),
      secondary: TilawaButton(
        text: backLabel,
        variant: TilawaButtonVariant.ghost,
        semanticLabel: backLabel,
        onPressed: onBack,
        isFullWidth: true,
      ),
    );
  }
}

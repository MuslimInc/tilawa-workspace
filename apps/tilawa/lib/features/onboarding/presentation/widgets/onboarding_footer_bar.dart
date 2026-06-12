import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'onboarding_page_indicator.dart';

/// Thumb-reach chrome: page indicator and navigation actions.
///
/// Footer chrome for [OnboardingScreen] inside [TilawaThumbReachLayout].
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
    final TilawaDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: tokens.spaceLarge,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          label: '${currentPage + 1} / $pageCount',
          child: OnboardingPageIndicator(
            count: pageCount,
            currentIndex: currentPage,
          ),
        ),
        TilawaButton(
          text: _primaryLabel,
          variant: TilawaButtonVariant.primary,
          semanticLabel: _primaryLabel,
          foregroundColor: colorScheme.onPrimary,
          onPressed: _onPrimary,
          isFullWidth: true,
        ),
        if (_canGoBack)
          TilawaButton(
            text: backLabel,
            variant: TilawaButtonVariant.ghost,
            semanticLabel: backLabel,
            onPressed: onBack,
            isFullWidth: true,
          ),
      ],
    );
  }
}

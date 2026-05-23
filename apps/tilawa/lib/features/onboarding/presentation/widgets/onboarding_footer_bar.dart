import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'onboarding_page_indicator.dart';

/// Bottom chrome: page indicator and navigation actions.
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

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLarge,
        0,
        tokens.spaceLarge,
        context.floatingBottomPadding,
      ),
      child: TilawaContentBounds(
        kind: TilawaContentKind.form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: tokens.spaceLarge,
          children: [
            Semantics(
              label: '${currentPage + 1} / $pageCount',
              child: OnboardingPageIndicator(
                count: pageCount,
                currentIndex: currentPage,
              ),
            ),
            if (_canGoBack)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TilawaButton(
                    text: backLabel,
                    variant: TilawaButtonVariant.ghost,
                    size: TilawaButtonSize.large,
                    semanticLabel: backLabel,
                    onPressed: onBack,
                  ),
                  const Spacer(),
                  TilawaButton(
                    text: _primaryLabel,
                    variant: TilawaButtonVariant.primary,
                    size: TilawaButtonSize.large,
                    foregroundColor: colorScheme.onPrimary,
                    onPressed: _onPrimary,
                  ),
                ],
              )
            else
              TilawaButton(
                text: _primaryLabel,
                variant: TilawaButtonVariant.primary,
                size: TilawaButtonSize.large,
                isFullWidth: true,
                foregroundColor: colorScheme.onPrimary,
                onPressed: _onPrimary,
              ),
          ],
        ),
      ),
    );
  }
}

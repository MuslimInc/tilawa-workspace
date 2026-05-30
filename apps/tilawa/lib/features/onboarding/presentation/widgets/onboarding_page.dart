import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'onboarding_content.dart';
import 'onboarding_hero_visual.dart';
import 'onboarding_title_block.dart';

/// Single onboarding slide — spacing aligned with [TilawaIllustratedState].
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.content,
    required this.semanticsLabel,
  });

  final OnboardingContent content;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final TilawaEmptyStateTokens stateTokens = theme.componentTokens.emptyState;

    return Semantics(
      label: semanticsLabel,
      child: TilawaContentBounds(
        kind: TilawaContentKind.form,
        alignment: Alignment.center,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              padding: stateTokens.padding,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OnboardingHeroVisual(
                      assetPath: content.imagePath,
                      style: content.heroStyle,
                    ),
                    if (content.visualHint != null) ...[
                      SizedBox(height: tokens.spaceSmall),
                      Text(
                        content.visualHint!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: tokens.textHeightLoose,
                        ),
                      ),
                    ],
                    SizedBox(height: stateTokens.titleSpacing),
                    OnboardingTitleBlock(
                      title: content.title,
                      lineSpacing: tokens.spaceSmall,
                    ),
                    SizedBox(height: stateTokens.subtitleSpacing),
                    Text(
                      content.description,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: tokens.textHeightLoose,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

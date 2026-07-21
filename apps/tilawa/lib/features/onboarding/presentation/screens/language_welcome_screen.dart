import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/services/app_system_chrome_style.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../router/app_router_config.dart';
import '../../../localization/presentation/widgets/app_language_switcher.dart';

/// First-run language picker shown before onboarding so slides are localized.
class LanguageWelcomeScreen extends StatelessWidget {
  const LanguageWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final SystemUiOverlayStyle overlayStyle =
        AppSystemChromeStyle.buildDefaultAppStyle(
          theme,
          statusBarBackgroundColor: theme.scaffoldBackgroundColor,
          navigationBarColor: theme.scaffoldBackgroundColor,
        );
    // Brand badge owns first glance; welcome sits one step below.
    final TextStyle? baseWelcomeStyle = theme.textTheme.headlineSmall;
    final TextStyle welcomeStyle = (baseWelcomeStyle ?? const TextStyle())
        .copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          height: baseWelcomeStyle?.height ?? 1.25,
        );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        body: TilawaThumbReachLayout(
          useSafeArea: true,
          content: Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spaceLarge),
            child: TilawaContentBounds(
              kind: TilawaContentKind.form,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Center(child: TilawaAppBrandBadge()),
                  SizedBox(height: tokens.spaceMedium),
                  TilawaReservedTextLines(
                    text: context.l10n.welcomeToApp,
                    style: welcomeStyle,
                    maxLines: 2,
                  ),
                  SizedBox(height: tokens.spaceSmall),
                  Text(
                    context.l10n.firstRunFunnelStepProgress(1, 4),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: tokens.spaceExtraSmall),
                  Text(
                    context.l10n.languageWelcomeProgressSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: tokens.spaceExtraLarge),
                  const Center(child: AppLanguageSwitcher()),
                ],
              ),
            ),
          ),
          actions: TilawaThumbReachActions(
            primary: TilawaButton(
              text: context.l10n.next,
              variant: TilawaButtonVariant.primary,
              semanticLabel: context.l10n.next,
              foregroundColor: colorScheme.onPrimary,
              isFullWidth: true,
              onPressed: () => const OnboardingRoute().go(context),
            ),
          ),
        ),
      ),
    );
  }
}

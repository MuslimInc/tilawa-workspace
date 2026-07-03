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
                  SizedBox(height: tokens.spaceExtraLarge),
                  Text(
                    context.l10n.welcomeToApp,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: tokens.spaceMedium),
                  Text(
                    context.l10n.chooseLanguage,
                    style: theme.textTheme.bodyLarge?.copyWith(
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
          actions: TilawaButton(
            text: context.l10n.next,
            variant: TilawaButtonVariant.primary,
            semanticLabel: context.l10n.next,
            foregroundColor: colorScheme.onPrimary,
            isFullWidth: true,
            onPressed: () => const OnboardingRoute().go(context),
          ),
        ),
      ),
    );
  }
}

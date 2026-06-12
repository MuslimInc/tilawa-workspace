import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shown when Google sign-in UI cannot be drawn (OEM overlay / CM failure).
class LoginSignInFallbackPanel extends StatelessWidget {
  const LoginSignInFallbackPanel({
    required this.onRetry,
    super.key,
  });

  final VoidCallback onRetry;

  static final Uri _playServicesUri = Uri.parse(
    'market://details?id=com.google.android.gms',
  );

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;

    return TilawaCard(
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: tokens.spaceSmall,
          children: <Widget>[
            Text(
              context.l10n.googleSignInFallbackTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              context.l10n.googleSignInFallbackBody,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            TilawaButton(
              text: context.l10n.tryAgain,
              semanticLabel: context.l10n.tryAgain,
              isFullWidth: true,
              onPressed: onRetry,
            ),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () => _openPlayServices(context),
                child: Text(
                  context.l10n.googleSignInUpdatePlayServices,
                  style: theme.textTheme.labelLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPlayServices(BuildContext context) async {
    final bool launched = await launchUrl(
      _playServicesUri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      await launchUrl(
        Uri.parse(
          'https://play.google.com/store/apps/details?id=com.google.android.gms',
        ),
        mode: LaunchMode.externalApplication,
      );
    }
  }
}

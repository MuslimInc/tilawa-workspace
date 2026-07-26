import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/sadaqah_jariyah_config.dart';

class SadaqahJariyahIntro extends StatelessWidget {
  const SadaqahJariyahIntro({required this.config, super.key});

  final SadaqahJariyahConfig config;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;
    final l10n = context.l10n;
    final String languageCode = Localizations.localeOf(context).languageCode;
    final String subtitle = config.subtitleForLanguageCode(languageCode);
    final TextStyle body = theme.textTheme.bodyMedium!.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      height: tokens.textHeightLoose,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (subtitle.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: tokens.spaceSmall),
            child: Text(
              subtitle,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Text(l10n.sadaqahJariyahIntroP1, style: body),
        SizedBox(height: tokens.spaceSmall),
        Text(l10n.sadaqahJariyahIntroP2, style: body),
        SizedBox(height: tokens.spaceSmall),
        Text(l10n.sadaqahJariyahIntroP3, style: body),
      ],
    );
  }
}

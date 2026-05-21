import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Lists what voluntary support helps sustain.
class SupportImpactSection extends StatelessWidget {
  const SupportImpactSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    final List<String> items = <String>[
      l10n.supportImpactQuranHosting,
      l10n.supportImpactReciterAudio,
      l10n.supportImpactPrayerTools,
      l10n.supportImpactDevelopment,
      l10n.supportImpactAdFree,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.spaceSmall,
      children: [
        Text(
          l10n.supportImpactTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        ...items.map(
          (String text) => _ImpactRow(text: text),
        ),
      ],
    );
  }
}

class _ImpactRow extends StatelessWidget {
  const _ImpactRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          FluentIcons.checkmark_circle_24_regular,
          size: tokens.iconSizeMedium,
          color: colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: tokens.spaceSmall),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: tokens.textHeightLoose,
            ),
          ),
        ),
      ],
    );
  }
}

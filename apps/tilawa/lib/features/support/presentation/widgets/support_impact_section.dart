import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'support_footer_lined_row.dart';

/// Collapsible transparency list — default collapsed, RTL-safe alignment.
class SupportImpactSection extends StatefulWidget {
  const SupportImpactSection({super.key});

  @override
  State<SupportImpactSection> createState() => _SupportImpactSectionState();
}

class _SupportImpactSectionState extends State<SupportImpactSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    final List<String> items = <String>[
      l10n.supportImpactQuranHosting,
      l10n.supportImpactPrayerTools,
      l10n.supportImpactDevelopment,
    ];

    final TextStyle titleStyle = theme.textTheme.titleSmall!.copyWith(
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurfaceVariant,
    );

    final TextStyle bulletStyle = theme.textTheme.bodyMedium!.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.spaceSmall,
      children: [
        SupportFooterLinedRow(
          crossAxisAlignment: CrossAxisAlignment.center,
          content: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(tokens.radiusSmall),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.spaceExtraSmall),
              child: Row(
                mainAxisSize: .min,
                mainAxisAlignment: .spaceBetween,
                children: [
                  Text(l10n.supportImpactWhyTitle, style: titleStyle),
                  SizedBox(width: tokens.spaceExtraSmall),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: tokens.durationFast,
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      FluentIcons.chevron_down_24_regular,
                      size: tokens.iconSizeSmall,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: tokens.durationFast,
          curve: Curves.easeOutCubic,
          alignment: AlignmentDirectional.topCenter,
          child: _expanded
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: tokens.spaceSmall,
                  children: items
                      .map(
                        (String text) => SupportFooterLinedRow(
                          leading: Icon(
                            FluentIcons.checkmark_circle_24_regular,
                            size: tokens.iconSizeSmall,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          content: Text(text, style: bulletStyle),
                        ),
                      )
                      .toList(growable: false),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

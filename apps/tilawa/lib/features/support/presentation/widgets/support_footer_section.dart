import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'support_footer_lined_row.dart';
import 'support_impact_section.dart';
import 'support_trust_line_text.dart';

/// Trust copy and collapsible impact — shared icon column and text inset.
class SupportFooterSection extends StatelessWidget {
  const SupportFooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    final TextStyle trustStyle = theme.textTheme.labelSmall!.copyWith(
      color: colorScheme.onSurfaceVariant,
      height: tokens.textHeightLoose,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: tokens.spaceMedium,
        children: [
          SupportFooterLinedRow(
            crossAxisAlignment: CrossAxisAlignment.start,
            content: SupportTrustLineText(baseStyle: trustStyle),
          ),
          Divider(
            height: tokens.borderWidthThin,
            thickness: tokens.borderWidthThin,
            color: colorScheme.outlineVariant,
          ),
          const SupportImpactSection(),
        ],
      ),
    );
  }
}

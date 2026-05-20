import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';

/// Settings-style row with a title and one or two trailing icon toggles.
///
/// Spacing is driven by [TilawaPrayerAlertRowTokens]. Callers supply
/// feature-agnostic controls (typically [TilawaIconToggle] widgets).
class TilawaPrayerAlertRow extends StatelessWidget {
  const TilawaPrayerAlertRow({
    super.key,
    required this.title,
    required this.primaryControl,
    this.secondaryControl,
    this.titleStyle,
    this.primarySemanticsIdentifier,
  });

  final String title;
  final Widget primaryControl;
  final Widget? secondaryControl;
  final TextStyle? titleStyle;

  /// Optional Maestro / integration-test identifier for [primaryControl].
  final String? primarySemanticsIdentifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.componentTokens.prayerAlertRow;

    Widget primary = primaryControl;
    if (primarySemanticsIdentifier != null) {
      primary = Semantics(
        identifier: primarySemanticsIdentifier,
        child: primaryControl,
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.verticalPadding),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style:
                  titleStyle ??
                  theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          primary,
          if (secondaryControl != null) ...[
            SizedBox(width: tokens.toggleSpacing),
            secondaryControl!,
          ],
        ],
      ),
    );
  }
}

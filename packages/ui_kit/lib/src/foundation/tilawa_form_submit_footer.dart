import 'package:flutter/material.dart';

import '../atoms/tilawa_button.dart';
import 'design_tokens.dart';
import 'tilawa_form_validation.dart';

/// Sticky long-form footer: optional validation summary + always-enabled CTA.
class TilawaFormSubmitFooter extends StatelessWidget {
  /// Creates a submit footer for long forms.
  const TilawaFormSubmitFooter({
    super.key,
    required this.buttonText,
    required this.onPressed,
    this.invalidFieldCount,
    this.isLoading = false,
    this.buttonSize = TilawaButtonSize.large,
  });

  /// Primary action label.
  final String buttonText;

  /// Called when the user taps submit (validation runs in the host layer).
  final VoidCallback onPressed;

  /// When non-null and > 0, shows the validation summary above the button.
  final int? invalidFieldCount;

  /// Shows a loading state on the primary button.
  final bool isLoading;

  /// Primary button size.
  final TilawaButtonSize buttonSize;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final int count = invalidFieldCount ?? 0;
    final String? summary = count > 0
        ? TilawaFormValidationMessages.validationSummary(count)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.spaceSmall,
      children: <Widget>[
        if (summary != null)
          Text(
            summary,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
        TilawaButton(
          text: buttonText,
          onPressed: isLoading ? null : onPressed,
          isFullWidth: true,
          size: buttonSize,
          isLoading: isLoading,
        ),
      ],
    );
  }
}

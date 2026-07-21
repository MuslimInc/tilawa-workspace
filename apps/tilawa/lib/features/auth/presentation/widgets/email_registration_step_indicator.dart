import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Linear step progress for the email registration wizard.
///
/// Goal gradient: progress is never cold-zero while a step is active —
/// step 1 of N already fills 1/N of the bar.
class EmailRegistrationStepIndicator extends StatelessWidget {
  const EmailRegistrationStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabel,
  });

  final int currentStep;
  final int totalSteps;
  final String stepLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final int safeTotal = totalSteps <= 0 ? 1 : totalSteps;
    final int safeCurrent = currentStep.clamp(1, safeTotal);
    final double progress = (safeCurrent / safeTotal).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          stepLabel,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: tokens.spaceSmall),
        ClipRRect(
          borderRadius: BorderRadius.circular(tokens.radiusSmall),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: tokens.progressHeight,
          ),
        ),
      ],
    );
  }
}

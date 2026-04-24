import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';

class TilawaFeedbackStrip extends StatelessWidget {
  const TilawaFeedbackStrip({
    super.key,
    required this.icon,
    required this.message,
    required this.backgroundColor,
    required this.foregroundColor,
    this.showSpinner = false,
    this.borderColor,
    this.padding,
    this.borderRadius,
  });

  final IconData icon;
  final String message;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool showSpinner;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final componentTokens = theme.componentTokens.feedbackStrip;

    return Container(
      padding: padding ?? componentTokens.padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(
          borderRadius ?? componentTokens.borderRadius,
        ),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Row(
        spacing: componentTokens.contentGap,
        children: [
          if (showSpinner)
            SizedBox(
              width: componentTokens.spinnerSize,
              height: componentTokens.spinnerSize,
              child: CircularProgressIndicator(
                strokeWidth: componentTokens.spinnerStrokeWidth,
                valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
              ),
            )
          else
            Icon(icon, color: foregroundColor),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

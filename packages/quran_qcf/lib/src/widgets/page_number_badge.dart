import 'package:flutter/material.dart';

class PageNumberBadge extends StatelessWidget {
  const PageNumberBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  static const double _horizontalPadding = 7;
  static const double _verticalPadding = 0.5;
  static const double _cornerRadius = 999;
  static const double _fontSize = 10.5;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(_cornerRadius),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _horizontalPadding,
          vertical: _verticalPadding,
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: _fontSize,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

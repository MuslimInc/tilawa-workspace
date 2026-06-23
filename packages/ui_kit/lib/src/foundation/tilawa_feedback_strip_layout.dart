import 'package:flutter/material.dart';

import '../molecules/tilawa_feedback_strip.dart';
import 'component_tokens.dart';
import 'design_tokens.dart';

/// Resolves the scaled [TextStyle] used for [TilawaFeedbackStrip] messages.
TextStyle feedbackStripMessageStyle(
  BuildContext context, {
  required Color foregroundColor,
}) {
  final ThemeData theme = Theme.of(context);
  return theme.textTheme.bodyMedium!.copyWith(
    color: foregroundColor,
    fontWeight: FontWeight.w600,
  );
}

/// Height of a [lineCount]-line message block after text scaling.
double feedbackStripMessageBlockHeight(
  BuildContext context, {
  required TextStyle messageStyle,
  required int lineCount,
}) {
  final TextScaler scaler = MediaQuery.textScalerOf(context);
  final double fontSize = scaler.scale(messageStyle.fontSize!);
  final double lineHeight = messageStyle.height ?? 1.4;
  return fontSize * lineHeight * lineCount;
}

/// Minimum cross-axis height for a toast content row.
double feedbackStripToastContentMinHeight(
  BuildContext context, {
  required TilawaFeedbackStripTokens tokens,
  required int messageLineCount,
  required bool hasTrailing,
  required TextStyle messageStyle,
}) {
  final TilawaDesignTokens designTokens = Theme.of(context).tokens;
  final double messageHeight = feedbackStripMessageBlockHeight(
    context,
    messageStyle: messageStyle,
    lineCount: messageLineCount,
  );
  final double trailingHeight = hasTrailing
      ? designTokens.minInteractiveDimension
      : 0;
  return [
    tokens.leadingSlotSize,
    messageHeight,
    trailingHeight,
  ].reduce((double a, double b) => a > b ? a : b);
}

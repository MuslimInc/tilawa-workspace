import 'package:flutter/material.dart';

import '../molecules/tilawa_feedback_strip.dart';
import 'component_tokens.dart';
import 'design_tokens.dart';
import 'tilawa_feedback_action.dart';
import 'tilawa_feedback_style.dart';

/// Transient bottom feedback surfaced by [TilawaFeedbackHost].
///
/// Callers use [TilawaFeedback.showToast] or [TilawaFeedback.showActionable];
/// do not insert this widget directly.
class TilawaToast extends StatelessWidget {
  /// Creates a toast for the given [variant] and localized [message].
  const TilawaToast({
    super.key,
    required this.variant,
    required this.message,
    this.actions = const <TilawaFeedbackAction>[],
    this.onActionPressed,
  });

  /// Semantic intent.
  final TilawaFeedbackVariant variant;

  /// Caller-localized copy.
  final String message;

  /// Optional trailing actions (undo, retry, dismiss).
  final List<TilawaFeedbackAction> actions;

  /// Host callback invoked before dismiss when an action is tapped.
  final ValueChanged<TilawaFeedbackAction>? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final int toastMessageMaxLines =
        theme.componentTokens.feedbackStrip.toastMessageMaxLines;
    final TilawaFeedbackStyle style = TilawaFeedbackStyle.forVariant(
      context,
      variant,
    );
    final double radius = tokens.resolveRadius(
      family: TilawaRadiusFamily.chrome,
    );

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(
                alpha: tokens.opacityShadowStrong,
              ),
              blurRadius: tokens.shadowOffsetMedium.dy * 4,
              offset: tokens.shadowOffsetMedium,
            ),
          ],
        ),
        child: TilawaFeedbackStrip(
          icon: style.icon,
          message: message,
          backgroundColor: style.backgroundColor,
          foregroundColor: style.foregroundColor,
          variant: variant,
          messageMaxLines: toastMessageMaxLines,
          reserveMessageLines: true,
          trailing: actions.isEmpty
              ? null
              : _TilawaToastActions(
                  actions: actions,
                  foregroundColor: style.foregroundColor,
                  onActionPressed: onActionPressed,
                ),
        ),
      ),
    );
  }
}

class _TilawaToastActions extends StatelessWidget {
  const _TilawaToastActions({
    required this.actions,
    required this.foregroundColor,
    required this.onActionPressed,
  });

  final List<TilawaFeedbackAction> actions;
  final Color foregroundColor;
  final ValueChanged<TilawaFeedbackAction>? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double actionSpacing =
        theme.componentTokens.permissionBanner.actionSpacing;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var i = 0; i < actions.length; i++) ...<Widget>[
          if (i > 0) SizedBox(width: actionSpacing),
          _TilawaToastActionButton(
            action: actions[i],
            foregroundColor: foregroundColor,
            onPressed: onActionPressed,
          ),
        ],
      ],
    );
  }
}

class _TilawaToastActionButton extends StatelessWidget {
  const _TilawaToastActionButton({
    required this.action,
    required this.foregroundColor,
    required this.onPressed,
  });

  final TilawaFeedbackAction action;
  final Color foregroundColor;
  final ValueChanged<TilawaFeedbackAction>? onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final double horizontal =
        theme.componentTokens.permissionBanner.actionSpacing;

    return TextButton(
      onPressed: onPressed == null ? null : () => onPressed!(action),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: horizontal),
        minimumSize: Size(
          tokens.minInteractiveDimension,
          tokens.minInteractiveDimension,
        ),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      child: Text(
        action.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

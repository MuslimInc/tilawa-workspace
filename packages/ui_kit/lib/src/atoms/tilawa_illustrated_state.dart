import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';
import 'tilawa_button.dart';
import 'tilawa_state_visual.dart';

/// A reusable, feature-agnostic state layout with an illustration slot.
///
/// Use this for premium empty, permission, onboarding-adjacent, or lightweight
/// error states where a small visual improves clarity. The caller owns the
/// feature-specific copy, action behavior, and any asset selection.
class TilawaIllustratedState extends StatelessWidget {
  /// Creates an illustrated state.
  const TilawaIllustratedState({
    super.key,
    required this.title,
    this.subtitle,
    this.visual,
    this.icon,
    this.iconColor,
    this.primaryAction,
    this.secondaryAction,
    this.maxWidth,
    this.semanticLabel,
  });

  /// Primary message shown below the visual.
  final String title;

  /// Optional supporting copy.
  final String? subtitle;

  /// Optional illustration or composed visual.
  ///
  /// Prefer reusable UI Kit assets or feature-scoped assets that follow the
  /// Tilawa visual asset guidelines. Decorative visuals should exclude their
  /// own semantics unless they communicate information not present in text.
  final Widget? visual;

  /// Fallback icon when no custom [visual] is provided.
  final IconData? icon;

  /// Optional icon color. Defaults to the active theme primary color.
  final Color? iconColor;

  /// Primary action, usually a `TilawaButton`.
  final Widget? primaryAction;

  /// Optional lower-emphasis action.
  final Widget? secondaryAction;

  /// Maximum content width. Defaults to `TilawaDesignTokens.contentMaxWidthForm`.
  final double? maxWidth;

  /// Optional semantic label for the overall state.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stateTokens = theme.componentTokens.emptyState;
    final designTokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    final Widget stateVisual;
    if (visual != null) {
      stateVisual = visual!;
    } else if (icon != null) {
      stateVisual = TilawaStateVisual(
        icon: icon!,
        accentColor: iconColor ?? colorScheme.primary,
        size: stateTokens.iconSize + designTokens.spaceExtraLarge * 2,
      );
    } else {
      stateVisual = const SizedBox.shrink();
    }
    final double actionMaxWidth = maxWidth ?? designTokens.contentMaxWidthForm;
    Widget layoutAction(Widget action) {
      final Widget slotAction = action is TilawaButton
          ? _fullWidthIllustratedAction(action)
          : action;

      return SizedBox(
        width: double.infinity,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: actionMaxWidth),
          child: slotAction,
        ),
      );
    }

    final String? resolvedSemanticLabel =
        semanticLabel ??
        _composeSemanticLabel(
          title: title,
          subtitle: subtitle,
        );

    final Widget content = Padding(
      padding: stateTokens.padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? designTokens.contentMaxWidthForm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            stateVisual,
            SizedBox(height: stateTokens.titleSpacing),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: stateTokens.subtitleSpacing),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (primaryAction != null || secondaryAction != null) ...[
              SizedBox(height: stateTokens.actionSpacing),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: designTokens.spaceSmall,
                runSpacing: designTokens.spaceSmall,
                children: [
                  // Primary CTA leads in reading order (hierarchy / one obvious
                  // next step). When actions wrap on narrow widths, primary
                  // stacks above secondary.
                  if (primaryAction != null) layoutAction(primaryAction!),
                  if (secondaryAction != null) layoutAction(secondaryAction!),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    return Center(
      child: Semantics(
        container: true,
        label: resolvedSemanticLabel,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (!constraints.hasBoundedHeight) {
              return content;
            }

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(child: content),
              ),
            );
          },
        ),
      ),
    );
  }
}

String? _composeSemanticLabel({
  required String title,
  String? subtitle,
}) {
  final String trimmedSubtitle = subtitle?.trim() ?? '';
  if (trimmedSubtitle.isEmpty) {
    return title;
  }
  return '$title. $trimmedSubtitle';
}

TilawaButton _fullWidthIllustratedAction(TilawaButton button) {
  if (button.isFullWidth) {
    return button;
  }

  return TilawaButton(
    key: button.key,
    text: button.text,
    onPressed: button.onPressed,
    variant: button.variant,
    size: button.size,
    leadingIcon: button.leadingIcon,
    trailingIcon: button.trailingIcon,
    isLoading: button.isLoading,
    isFullWidth: true,
    semanticLabel: button.semanticLabel,
    backgroundColor: button.backgroundColor,
    foregroundColor: button.foregroundColor,
    borderColor: button.borderColor,
    borderRadius: button.borderRadius,
    padding: button.padding,
    textStyle: button.textStyle,
    shrinkWrapTapTarget: button.shrinkWrapTapTarget,
  );
}

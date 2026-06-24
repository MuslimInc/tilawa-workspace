import 'package:flutter/material.dart';

import 'component_tokens.dart';
import 'design_tokens.dart';
import 'tilawa_bottom_action_area.dart';
import 'tilawa_comfortable_reach_padding.dart';
import 'tilawa_form_validation.dart';

/// Full-screen form layout with a scrollable body and sticky bottom CTA.
///
/// Use for multi-field flows where the primary action must stay in the thumb
/// zone while the form scrolls (profile completion, long applications).
/// For short wizard steps, prefer [TilawaThumbReachLayout] instead.
///
/// When [validationController] is set, the scroll view uses its
/// [TilawaFormValidationController.scrollController] and exposes a
/// [TilawaFormValidationScope] for [TilawaFormFieldAnchor] widgets.
class TilawaFormScreenScaffold extends StatelessWidget {
  /// Creates a form screen with a pinned [footer].
  const TilawaFormScreenScaffold({
    super.key,
    required this.body,
    required this.footer,
    this.bodyPadding,
    this.footerExtraBottom = 0,
    this.footerTop = 0,
    this.validationController,
  });

  /// Scrollable form content (fields, copy, selectors).
  final Widget body;

  /// Sticky primary action(s) rendered in [TilawaBottomActionArea].
  final Widget footer;

  /// Insets for the scroll viewport; defaults to [spaceLarge] on all sides.
  final EdgeInsetsGeometry? bodyPadding;

  /// Extra bottom clearance passed to the footer (shell nav, mini-player).
  final double footerExtraBottom;

  /// Space above [footer] inside the action band.
  final double footerTop;

  /// Optional scroll-to-error coordinator for long forms.
  final TilawaFormValidationController? validationController;

  /// Bottom scroll inset so the last field can clear the sticky [footer].
  static double stickyFooterScrollClearance(
    BuildContext context, {
    double footerTop = 0,
    double extraBottom = 0,
  }) {
    final TilawaDesignTokens tokens = Theme.of(context).tokens;
    final double comfortableBottom =
        TilawaComfortableReachPadding.resolve(
          context,
          kind: TilawaComfortableReachKind.screen,
          keyboardAware: false,
        ) +
        extraBottom;
    final TextDirection direction = Directionality.of(context);
    final EdgeInsets footerPadding = Theme.of(
      context,
    ).componentTokens.bottomSheetScaffold.footerPadding.resolve(direction);

    return footerTop +
        footerPadding.top +
        tokens.minInteractiveDimension +
        comfortableBottom +
        tokens.spaceMedium;
  }

  @override
  Widget build(BuildContext context) {
    final TilawaDesignTokens tokens = Theme.of(context).tokens;
    final ScrollController? scrollController =
        validationController?.scrollController;
    final TextDirection direction = Directionality.of(context);
    final EdgeInsets resolvedBodyPadding =
        bodyPadding?.resolve(direction) ?? EdgeInsets.all(tokens.spaceLarge);
    final double footerClearance = stickyFooterScrollClearance(
      context,
      footerTop: footerTop,
      extraBottom: footerExtraBottom,
    );
    final EdgeInsets scrollPadding = resolvedBodyPadding.copyWith(
      bottom: resolvedBodyPadding.bottom + footerClearance,
    );

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: scrollPadding,
            child: body,
          ),
        ),
        TilawaBottomActionArea(
          top: footerTop,
          extraBottom: footerExtraBottom,
          keyboardAware: false,
          child: footer,
        ),
      ],
    );

    if (validationController != null) {
      content = TilawaFormValidationScope(
        controller: validationController!,
        child: content,
      );
    }

    return content;
  }
}

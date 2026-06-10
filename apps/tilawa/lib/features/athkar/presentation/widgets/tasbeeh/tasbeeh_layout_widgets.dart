import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../cubit/tasbeeh_state.dart';

class TasbeehContentBounds extends StatelessWidget {
  const TasbeehContentBounds({
    super.key,
    required this.child,
    this.alignTop = false,
  });

  final Widget child;

  /// When true, content hugs the top instead of vertically centering in the
  /// available body (hub, create, quick-count screens).
  final bool alignTop;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    final Widget bounded = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: tokens.contentMaxWidthSettings),
      child: child,
    );

    if (alignTop) {
      return Align(alignment: Alignment.topCenter, child: bounded);
    }

    return Center(child: bounded);
  }
}

class TasbeehBottomActionArea extends StatelessWidget {
  const TasbeehBottomActionArea({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLarge,
        tokens.spaceSmall,
        tokens.spaceLarge,
        tokens.spaceLarge,
      ),
      child: child,
    );
  }
}

class TasbeehShakeOnTrigger extends StatelessWidget {
  const TasbeehShakeOnTrigger({
    super.key,
    required this.trigger,
    required this.child,
  });

  final int trigger;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(trigger),
      tween: Tween<double>(begin: 0, end: trigger == 0 ? 0 : 1),
      duration: const Duration(milliseconds: 420),
      builder: (context, value, animatedChild) {
        final offsetX = math.sin(value * math.pi * 6) * 10 * (1 - value);
        return Transform.translate(
          offset: Offset(offsetX, 0),
          child: animatedChild,
        );
      },
      child: child,
    );
  }
}

class TasbeehClearAllConfirmationDialog extends StatelessWidget {
  const TasbeehClearAllConfirmationDialog({super.key, required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.tasbeehClearAllTitle),
      content: Text(context.l10n.tasbeehClearAllMessage(itemCount)),
      actions: [
        TilawaButton(
          text: context.l10n.cancel,
          variant: TilawaButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        TilawaButton(
          text: context.l10n.deleteAll,
          variant: TilawaButtonVariant.danger,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

class TasbeehDeleteConfirmationDialog extends StatelessWidget {
  const TasbeehDeleteConfirmationDialog({super.key, required this.tasbeehText});

  final String tasbeehText;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.delete),
      content: Text(context.l10n.tasbeehDeleteConfirmationMessage(tasbeehText)),
      actions: [
        TilawaButton(
          text: context.l10n.cancel,
          variant: TilawaButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        TilawaButton(
          text: context.l10n.delete,
          variant: TilawaButtonVariant.danger,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

String? resolveTasbeehErrorText(BuildContext context, TasbeehState state) {
  final failure = state.failure;
  if (failure is ValidationFailure) {
    return context.l10n.validationError;
  }
  return state.errorMessage ?? failure?.message;
}

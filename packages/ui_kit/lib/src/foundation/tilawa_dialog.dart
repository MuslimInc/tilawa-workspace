import 'package:flutter/material.dart';

import '../atoms/tilawa_button.dart';
import 'design_tokens.dart';
import 'tilawa_bottom_sheet_title_row.dart';

/// Centered modal dialogs for Tilawa.
///
/// These mirror the `showTilawa*Sheet` preset family (see
/// `tilawa_modal_bottom_sheet.dart`) but render as centered cards on a scrim
/// instead of bottom sheets. The visual language follows the brand confirmation
/// dialog: a rounded card ([TilawaRadiusFamily.card]), a title row
/// with an end-aligned close button, an optional body, and **stacked
/// full-width** actions — primary on top, secondary (cancel) below.
///
/// Use a dialog (over a bottom sheet) for short, focused decisions and compact
/// option lists where centering the choice reads as more deliberate. Keep
/// long, scrollable, or drag-to-dismiss content in a bottom sheet.

/// Confirm dialog: destructive or high-friction choice with a stacked
/// primary + cancel.
///
/// The dialog **owns its own dismissal** — every action (confirm, cancel,
/// close, barrier tap) pops only the dialog route, using the dialog's own
/// context. The future resolves to `true` when confirmed and `false`/`null`
/// otherwise. Perform the side effect after awaiting:
///
/// ```dart
/// final confirmed = await showTilawaConfirmDialog(...);
/// if (confirmed == true) doTheThing();
/// ```
///
/// [onConfirm] is provided as a convenience for callers that prefer a callback
/// over awaiting; it fires **after** the dialog has popped, so it must not pop
/// any route itself.
Future<bool?> showTilawaConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  VoidCallback? onConfirm,
  String cancelLabel = 'Cancel',
  TilawaButtonVariant confirmVariant = TilawaButtonVariant.danger,
  bool trailingClose = true,
  String? dialogSemanticsLabel,
}) async {
  final bool? result = await _showTilawaDialog<bool>(
    context: context,
    title: title,
    dialogSemanticsLabel: dialogSemanticsLabel,
    trailingClose: trailingClose,
    // Close (X / barrier) resolves to "not confirmed".
    onClose: (dialogContext) => Navigator.of(dialogContext).pop(false),
    primaryLabel: confirmLabel,
    onPrimary: (dialogContext) => Navigator.of(dialogContext).pop(true),
    primaryVariant: confirmVariant,
    secondaryLabel: cancelLabel,
    onSecondary: (dialogContext) => Navigator.of(dialogContext).pop(false),
    bodyBuilder: (ctx) => Text(
      message,
      style: Theme.of(ctx).textTheme.bodyLarge,
    ),
  );
  if (result == true) onConfirm?.call();
  return result;
}

/// Picker dialog: list-style body (e.g. selection tiles) with no footer
/// actions — each option dismisses on tap. An end-aligned close is provided.
Future<T?> showTilawaPickerDialog<T>({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext context) bodyBuilder,
  bool trailingClose = true,
  TilawaDialogAction? onClose,
  String? dialogSemanticsLabel,
}) {
  return _showTilawaDialog<T>(
    context: context,
    title: title,
    bodyBuilder: bodyBuilder,
    trailingClose: trailingClose,
    onClose: onClose,
    dialogSemanticsLabel: dialogSemanticsLabel,
  );
}

/// Form dialog: scrollable body + stacked primary (and optional secondary)
/// actions. For compact forms; prefer a sheet for tall content.
Future<T?> showTilawaFormDialog<T>({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext context) bodyBuilder,
  required String primaryLabel,
  required TilawaDialogAction onPrimary,
  String? secondaryLabel,
  TilawaDialogAction? onSecondary,
  TilawaButtonVariant primaryVariant = TilawaButtonVariant.primary,
  bool trailingClose = true,
  TilawaDialogAction? onClose,
  String? dialogSemanticsLabel,
}) {
  return _showTilawaDialog<T>(
    context: context,
    title: title,
    bodyBuilder: bodyBuilder,
    primaryLabel: primaryLabel,
    onPrimary: onPrimary,
    secondaryLabel: secondaryLabel,
    onSecondary: onSecondary,
    primaryVariant: primaryVariant,
    trailingClose: trailingClose,
    onClose: onClose,
    dialogSemanticsLabel: dialogSemanticsLabel,
  );
}

/// A dialog action callback that receives the dialog route's own
/// [BuildContext]. Always pop via this context (e.g.
/// `Navigator.of(dialogContext).pop(result)`) so the dialog — and only the
/// dialog — is dismissed, never an ancestor route.
typedef TilawaDialogAction = void Function(BuildContext dialogContext);

Future<T?> _showTilawaDialog<T>({
  required BuildContext context,
  required String title,
  Widget Function(BuildContext context)? bodyBuilder,
  String? primaryLabel,
  TilawaDialogAction? onPrimary,
  String? secondaryLabel,
  TilawaDialogAction? onSecondary,
  TilawaButtonVariant primaryVariant = TilawaButtonVariant.primary,
  bool trailingClose = true,
  TilawaDialogAction? onClose,
  String? dialogSemanticsLabel,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  return showDialog<T>(
    context: context,
    barrierLabel: dialogSemanticsLabel ?? title,
    builder: (dialogContext) {
      final tokens = Theme.of(dialogContext).tokens;
      // Cap width so the card stays a centered card on tablets, not a banner.
      final double maxWidth = tokens.contentMaxWidthForm * 0.78;

      return Dialog(
        backgroundColor: colorScheme.surface,
        insetPadding: EdgeInsets.symmetric(
          horizontal: tokens.spaceExtraLarge,
          vertical: tokens.spaceExtraLarge,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            tokens.resolveRadius(family: TilawaRadiusFamily.card),
          ),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: _TilawaDialogContent(
            title: title,
            trailingClose: trailingClose,
            onClose: onClose,
            body: bodyBuilder?.call(dialogContext),
            primaryLabel: primaryLabel,
            onPrimary: onPrimary,
            secondaryLabel: secondaryLabel,
            onSecondary: onSecondary,
            primaryVariant: primaryVariant,
          ),
        ),
      );
    },
  );
}

class _TilawaDialogContent extends StatelessWidget {
  const _TilawaDialogContent({
    required this.title,
    required this.trailingClose,
    required this.onClose,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    required this.primaryVariant,
  });

  final String title;
  final bool trailingClose;
  final TilawaDialogAction? onClose;
  final Widget? body;
  final String? primaryLabel;
  final TilawaDialogAction? onPrimary;
  final String? secondaryLabel;
  final TilawaDialogAction? onSecondary;
  final TilawaButtonVariant primaryVariant;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final bool hasActions = primaryLabel != null;
    // Picker bodies (no footer actions) are option lists that carry their own
    // row padding, so keep the title-to-body gap tight. Message bodies
    // (confirm/form) want a clear gap below the title.
    final bool tightBody = !hasActions;

    // `context` here is under the dialog route. Bind each action to it so a
    // pop dismisses only the dialog. Default close/barrier behaviour falls
    // back to popping the dialog route when no handler is supplied.
    final double inset = tokens.spaceExtraLarge;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(inset, inset, inset, 0),
          child: TilawaBottomSheetTitleRow(
            title: title,
            trailingClose: trailingClose,
            onClose: onClose == null
                ? () => Navigator.of(context).maybePop()
                : () => onClose!(context),
          ),
        ),
        if (body != null) ...[
          // Message bodies (confirm/form) need a clear gap below the title;
          // list bodies (picker) carry their own row padding, so a tight gap
          // avoids a loose double-space under the title.
          SizedBox(
            height: tightBody ? tokens.spaceExtraSmall : tokens.spaceMedium,
          ),
          // Picker lists bleed horizontally so row [InkWell] highlights span
          // the card; confirm/form bodies keep horizontal inset.
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: tightBody ? 0 : inset,
                  end: tightBody ? 0 : inset,
                  bottom: hasActions ? 0 : inset,
                ),
                child: body!,
              ),
            ),
          ),
        ],
        if (hasActions)
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(inset, 0, inset, inset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: tokens.spaceExtraLarge),
                TilawaButton(
                  text: primaryLabel!,
                  variant: primaryVariant,
                  isFullWidth: true,
                  onPressed: onPrimary == null
                      ? null
                      : () => onPrimary!(context),
                ),
                if (secondaryLabel != null) ...[
                  SizedBox(height: tokens.spaceSmall),
                  TilawaButton(
                    text: secondaryLabel!,
                    variant: TilawaButtonVariant.outline,
                    isFullWidth: true,
                    onPressed: onSecondary == null
                        ? null
                        : () => onSecondary!(context),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

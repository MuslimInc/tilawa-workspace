import 'package:flutter/material.dart';

import '../atoms/tilawa_button.dart';
import 'tilawa_bottom_sheet_actions.dart';
import 'tilawa_bottom_sheet_scaffold.dart';
import 'tilawa_bottom_sheet_title_row.dart';

/// Opens a modal bottom sheet with a consistent maximum height.
///
/// Call sites should still include [TilawaSheetHandle] at the top of their
/// content when the sheet is draggable, unless using [TilawaBottomSheetScaffold]
/// which inserts the handle for you.
///
/// Prefer [TilawaBottomSheetScaffold.modalShape] with a matching surface
/// [backgroundColor] when the sheet uses [TilawaBottomSheetScaffold] for
/// layout so the system clip aligns with tokenized corners.
///
/// Preset helpers [showTilawaFormSheet], [showTilawaPickerSheet], and
/// [showTilawaConfirmSheet] compose [TilawaBottomSheetScaffold] with footer
/// actions for common flows (spec 015 FR-A03).
Future<T?> showTilawaModalBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext context) builder,
  bool isScrollControlled = true,
  Color? backgroundColor,
  ShapeBorder? shape,
  bool useSafeArea = false,
  Color? barrierColor,
  bool isDismissible = true,
  String? sheetSemanticsLabel,
}) {
  final double maxHeight = MediaQuery.sizeOf(context).height * 0.9;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    backgroundColor: backgroundColor,
    shape: shape,
    barrierColor: barrierColor,
    isDismissible: isDismissible,
    constraints: BoxConstraints(maxHeight: maxHeight),
    builder: (BuildContext sheetContext) {
      final Widget content = builder(sheetContext);
      if (sheetSemanticsLabel == null) return content;
      return Semantics(
        label: sheetSemanticsLabel,
        child: content,
      );
    },
  );
}

/// Form sheet: scrollable body + sticky primary (and optional secondary) footer.
Future<T?> showTilawaFormSheet<T>({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext context) bodyBuilder,
  required String primaryLabel,
  required VoidCallback onPrimary,
  String? secondaryLabel,
  VoidCallback? onSecondary,
  TilawaButtonVariant primaryVariant = TilawaButtonVariant.primary,
  bool trailingClose = true,
  VoidCallback? onClose,
  String? sheetSemanticsLabel,
  double maxHeightFraction = 0.75,
}) {
  return _showTilawaPresetSheet<T>(
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
    sheetSemanticsLabel: sheetSemanticsLabel,
    maxHeightFraction: maxHeightFraction,
  );
}

/// Picker sheet: list-style body + optional Done footer action.
Future<T?> showTilawaPickerSheet<T>({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext context) bodyBuilder,
  required String doneLabel,
  required VoidCallback onDone,
  bool trailingClose = true,
  VoidCallback? onClose,
  String? sheetSemanticsLabel,
  double maxHeightFraction = 0.75,
}) {
  return _showTilawaPresetSheet<T>(
    context: context,
    title: title,
    bodyBuilder: bodyBuilder,
    primaryLabel: doneLabel,
    onPrimary: onDone,
    trailingClose: trailingClose,
    onClose: onClose,
    sheetSemanticsLabel: sheetSemanticsLabel,
    maxHeightFraction: maxHeightFraction,
  );
}

/// Confirm sheet: destructive or high-friction choice with primary + cancel.
Future<bool?> showTilawaConfirmSheet({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  required VoidCallback onConfirm,
  String cancelLabel = 'Cancel',
  TilawaButtonVariant confirmVariant = TilawaButtonVariant.danger,
  bool trailingClose = true,
  VoidCallback? onClose,
  String? sheetSemanticsLabel,
  double maxHeightFraction = 0.5,
}) {
  return showTilawaFormSheet<bool>(
    context: context,
    title: title,
    sheetSemanticsLabel: sheetSemanticsLabel,
    maxHeightFraction: maxHeightFraction,
    trailingClose: trailingClose,
    onClose: onClose,
    primaryLabel: confirmLabel,
    onPrimary: onConfirm,
    primaryVariant: confirmVariant,
    secondaryLabel: cancelLabel,
    onSecondary: onClose ?? () => Navigator.maybePop(context, false),
    bodyBuilder: (ctx) {
      final padding = TilawaBottomSheetScaffold.resolvedBodyPadding(ctx);
      return SingleChildScrollView(
        padding: padding,
        child: Text(
          message,
          style: Theme.of(ctx).textTheme.bodyLarge,
        ),
      );
    },
  );
}

Future<T?> _showTilawaPresetSheet<T>({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext context) bodyBuilder,
  required String primaryLabel,
  required VoidCallback onPrimary,
  String? secondaryLabel,
  VoidCallback? onSecondary,
  TilawaButtonVariant primaryVariant = TilawaButtonVariant.primary,
  bool trailingClose = true,
  VoidCallback? onClose,
  String? sheetSemanticsLabel,
  double maxHeightFraction = 0.75,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  return showTilawaModalBottomSheet<T>(
    context: context,
    backgroundColor: colorScheme.surface,
    shape: TilawaBottomSheetScaffold.modalShape(context),
    sheetSemanticsLabel: sheetSemanticsLabel ?? title,
    builder: (sheetContext) {
      final height = MediaQuery.sizeOf(sheetContext).height * maxHeightFraction;
      return SizedBox(
        height: height,
        child: TilawaBottomSheetScaffold(
          topBar: TilawaBottomSheetTitleRow(
            title: title,
            trailingClose: trailingClose,
            onClose: onClose,
          ),
          footer: TilawaBottomSheetActions(
            primaryLabel: primaryLabel,
            onPrimary: onPrimary,
            secondaryLabel: secondaryLabel,
            onSecondary: onSecondary,
            primaryVariant: primaryVariant,
          ),
          children: [
            Expanded(child: bodyBuilder(sheetContext)),
          ],
        ),
      );
    },
  );
}

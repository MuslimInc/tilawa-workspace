import 'package:flutter/material.dart';

/// Opens a modal bottom sheet with a consistent maximum height.
///
/// Call sites should still include [TilawaSheetHandle] at the top of their
/// content when the sheet is draggable, unless using [TilawaBottomSheetScaffold]
/// which inserts the handle for you.
///
/// Prefer [TilawaBottomSheetScaffold.modalShape] with a matching surface
/// [backgroundColor] when the sheet uses [TilawaBottomSheetScaffold] for
/// layout so the system clip aligns with tokenized corners.
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
    // fix: Feedback & states — expose barrier + dismiss for parity with Material
    barrierColor: barrierColor,
    isDismissible: isDismissible,
    constraints: BoxConstraints(maxHeight: maxHeight),
    builder: (BuildContext sheetContext) {
      final Widget content = builder(sheetContext);
      if (sheetSemanticsLabel == null) return content;
      // fix: Accessibility — optional sheet title for screen readers
      return Semantics(
        label: sheetSemanticsLabel,
        child: content,
      );
    },
  );
}

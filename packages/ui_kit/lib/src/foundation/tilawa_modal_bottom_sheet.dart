import 'package:flutter/material.dart';

/// Opens a modal bottom sheet with a consistent maximum height.
///
/// Call sites should still include [TilawaSheetHandle] at the top of their
/// content when the sheet is draggable.
Future<T?> showTilawaModalBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext context) builder,
  bool isScrollControlled = true,
  Color? backgroundColor,
  ShapeBorder? shape,
  bool useSafeArea = false,
}) {
  final double maxHeight = MediaQuery.sizeOf(context).height * 0.9;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    backgroundColor: backgroundColor,
    shape: shape,
    constraints: BoxConstraints(maxHeight: maxHeight),
    builder: builder,
  );
}

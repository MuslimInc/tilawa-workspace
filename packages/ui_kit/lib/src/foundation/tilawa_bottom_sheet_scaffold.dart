import 'package:flutter/material.dart';

import '../atoms/tilawa_sheet_handle.dart';
import 'component_tokens.dart';

/// Standard layout for modal bottom sheet content aligned with
/// [TilawaBottomSheetScaffoldTokens].
///
/// Use with [modalShape] and a matching surface on
/// [showTilawaModalBottomSheet] so the system sheet clip matches this chrome.
///
/// Place scrollable regions (e.g. [ListView] inside [Flexible]) in [children];
/// apply [resolvedBodyPadding] inside the scrollable viewport when the child
/// cannot be wrapped in [Padding] (e.g. when using [Flexible]).
class TilawaBottomSheetScaffold extends StatelessWidget {
  const TilawaBottomSheetScaffold({
    super.key,
    this.showHandle = true,
    this.topBar,
    this.betweenTopBarAndBody = const <Widget>[],
    required this.children,
  });

  final bool showHandle;

  /// Typically a title row; wrapped with [TilawaBottomSheetScaffoldTokens]
  /// [headerPadding].
  final Widget? topBar;

  /// Full-width widgets after [topBar] (e.g. [Divider]) without extra
  /// horizontal inset.
  final List<Widget> betweenTopBarAndBody;

  /// Remaining column children (e.g. [Flexible] + [ListView]).
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).componentTokens.bottomSheetScaffold;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (showHandle) const TilawaSheetHandle(),
        if (topBar != null)
          Padding(
            padding: tokens.headerPadding,
            child: topBar,
          ),
        ...betweenTopBarAndBody,
        ...children,
      ],
    );
  }

  /// Shape for [showTilawaModalBottomSheet] and similar APIs.
  static ShapeBorder modalShape(BuildContext context) {
    final r = Theme.of(context).componentTokens.bottomSheetScaffold.topRadius;
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(r)),
    );
  }

  /// Resolved [TilawaBottomSheetScaffoldTokens.bodyPadding] for the current
  /// directionality.
  static EdgeInsets resolvedBodyPadding(BuildContext context) {
    final g = Theme.of(context).componentTokens.bottomSheetScaffold.bodyPadding;
    return g.resolve(Directionality.of(context));
  }
}

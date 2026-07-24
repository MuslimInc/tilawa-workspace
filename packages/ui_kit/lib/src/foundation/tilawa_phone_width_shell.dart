import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// Centers a phone-width app surface on wide windows (tablets, foldables,
/// desktop-sized windows) without stretching the mobile layout.
///
/// Below [maxContentWidth] this is a pass-through. Above it, the child is
/// constrained to [maxContentWidth], centered horizontally, and given a
/// [MediaQuery] whose size matches the constrained column so layouts that
/// read [MediaQuery.sizeOf] keep phone-scale math.
///
/// Intended for a single integration point such as [MaterialApp.builder], so
/// the navigator, snackbars, dialogs, and sheets share the same width.
class TilawaPhoneWidthShell extends StatelessWidget {
  const TilawaPhoneWidthShell({
    super.key,
    required this.child,
    this.maxContentWidth = TilawaBreakpoints.narrowUpperBound,
  });

  /// App subtree (typically the [MaterialApp] navigator child).
  final Widget? child;

  /// Maximum logical width of the centered app surface.
  ///
  /// Defaults to [TilawaBreakpoints.narrowUpperBound] (600) — Material 3
  /// compact upper bound and within a modern phone layout range.
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final Widget content = child ?? const SizedBox.shrink();
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double availableWidth = constraints.maxWidth;
        if (!availableWidth.isFinite || availableWidth <= maxContentWidth) {
          return content;
        }

        final MediaQueryData parentQuery = MediaQuery.of(context);
        final double contentWidth = maxContentWidth;
        final double contentHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : parentQuery.size.height;

        final EdgeInsets parentPadding = parentQuery.padding;
        final EdgeInsets parentViewPadding = parentQuery.viewPadding;

        return ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: contentWidth,
              height: contentHeight,
              child: MediaQuery(
                data: parentQuery.copyWith(
                  size: Size(contentWidth, parentQuery.size.height),
                  // Side safe areas belong to the full window letterbox, not
                  // the centered column.
                  padding: parentPadding.copyWith(left: 0, right: 0),
                  viewPadding: parentViewPadding.copyWith(left: 0, right: 0),
                ),
                child: content,
              ),
            ),
          ),
        );
      },
    );
  }
}

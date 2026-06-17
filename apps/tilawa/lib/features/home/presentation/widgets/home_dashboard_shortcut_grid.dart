import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Phone Home grids default to two columns; wider breakpoints use three.
int homeShortcutGridColumnCount(BuildContext context, {int? override}) {
  if (override != null) {
    return override;
  }
  return context.isAtLeastMedium ? 3 : 2;
}

/// Shared tile height — fits icon + two-line title + two-line subtitle.
double homeShortcutGridTileHeight(BuildContext context) {
  final tokens = Theme.of(context).tokens;
  final textTheme = Theme.of(context).textTheme;
  final double iconExtent = tokens.iconSizeMedium + tokens.spaceMedium * 2;
  final double titleLineHeight =
      (textTheme.titleSmall?.fontSize ?? 14) * 1.25;
  final double subtitleLineHeight =
      (textTheme.bodySmall?.fontSize ?? 12) * 1.3;
  final double textBlockHeight =
      titleLineHeight * 2 +
      tokens.spaceExtraSmall +
      subtitleLineHeight * 2;
  final double rowHeight = iconExtent > textBlockHeight
      ? iconExtent
      : textBlockHeight;
  return rowHeight + tokens.spaceSmall * 2;
}

/// Responsive shortcut grid with stable LTR/RTL layout.
///
/// Partial last rows keep column slots so the trailing tile aligns with the
/// column above (empty cells fill the remainder).
class HomeDashboardShortcutGrid extends StatelessWidget {
  const HomeDashboardShortcutGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.columnCount,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int? columnCount;

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) {
      return const SizedBox.shrink();
    }

    final tokens = Theme.of(context).tokens;
    final int columns = homeShortcutGridColumnCount(
      context,
      override: columnCount,
    );
    final double gap = tokens.spaceMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int rowStart = 0; rowStart < itemCount; rowStart += columns)
          Padding(
            padding: EdgeInsets.only(
              bottom: rowStart + columns < itemCount ? gap : 0,
            ),
            child: _ShortcutGridRow(
              gap: gap,
              columns: columns,
              rowStart: rowStart,
              itemCount: itemCount,
              tileHeight: homeShortcutGridTileHeight(context),
              itemBuilder: itemBuilder,
            ),
          ),
      ],
    );
  }
}

class _ShortcutGridRow extends StatelessWidget {
  const _ShortcutGridRow({
    required this.gap,
    required this.columns,
    required this.rowStart,
    required this.itemCount,
    required this.tileHeight,
    required this.itemBuilder,
  });

  final double gap;
  final int columns;
  final int rowStart;
  final int itemCount;
  final double tileHeight;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    final int itemsInRow = (itemCount - rowStart).clamp(0, columns);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: gap,
      children: [
        for (int column = 0; column < columns; column++)
          Expanded(
            child: column < itemsInRow
                ? SizedBox(
                    height: tileHeight,
                    width: double.infinity,
                    child: itemBuilder(context, rowStart + column),
                  )
                : SizedBox(height: tileHeight),
          ),
      ],
    );
  }
}

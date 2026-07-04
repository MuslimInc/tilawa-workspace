import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Lazy, height-bounded slot rows for one day on [TeacherDashboardScreen].
///
/// Renders only visible rows via [ListView.builder] and scrolls internally when
/// a day has more than [maxVisibleRows] slots.
class TeacherDashboardLazySlotDayList extends StatelessWidget {
  const TeacherDashboardLazySlotDayList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.maxVisibleRows = defaultMaxVisibleRows,
  });

  static const defaultMaxVisibleRows = 6;

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int maxVisibleRows;

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) return const SizedBox.shrink();

    final tokens = Theme.of(context).tokens;
    final rowExtent = tokens.minInteractiveDimension + tokens.spaceExtraSmall;
    final visibleRows = itemCount.clamp(0, maxVisibleRows);
    final scrollable = itemCount > maxVisibleRows;

    return SizedBox(
      height: rowExtent * visibleRows,
      child: ListView.builder(
        itemCount: itemCount,
        physics: scrollable
            ? const ClampingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        itemBuilder: itemBuilder,
      ),
    );
  }
}

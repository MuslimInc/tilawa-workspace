import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Fixed width of each day chip in [DateGroupedDayTabBar].
const double kDateGroupedDayTabChipWidth = 56;

/// Gap between day chips in [DateGroupedDayTabBar].
const double kDateGroupedDayTabSeparatorWidth = 8;

/// Horizontal padding on the tab bar [ListView].
const double kDateGroupedDayTabBarHorizontalPadding = 4;

/// Scroll offset to center chip at [index]; null when already centered enough.
@visibleForTesting
double? computeDateGroupedDayTabBarScrollTarget({
  required int index,
  required double viewportWidth,
  required double currentOffset,
  required double maxScrollExtent,
  double chipWidth = kDateGroupedDayTabChipWidth,
  double separatorWidth = kDateGroupedDayTabSeparatorWidth,
  double horizontalPadding = kDateGroupedDayTabBarHorizontalPadding,
  double alignment = 0.5,
}) {
  if (index < 0) {
    return null;
  }

  final itemLeading = horizontalPadding + index * (chipWidth + separatorWidth);
  final itemCenter = itemLeading + chipWidth / 2;
  final centeredOffset = (itemCenter - viewportWidth * alignment).clamp(
    0.0,
    maxScrollExtent,
  );

  if ((currentOffset - centeredOffset).abs() < 1) {
    return null;
  }
  return centeredOffset;
}

/// Horizontal scrollable day chips (Swvl-style) for date-grouped slot pickers.
class DateGroupedDayTabBar extends StatefulWidget {
  const DateGroupedDayTabBar({
    super.key,
    required this.days,
    required this.selected,
    required this.onDaySelected,
  });

  final List<DateTime> days;
  final DateTime selected;
  final ValueChanged<DateTime> onDaySelected;

  @override
  State<DateGroupedDayTabBar> createState() => _DateGroupedDayTabBarState();
}

class _DateGroupedDayTabBarState extends State<DateGroupedDayTabBar> {
  final _scrollCtrl = ScrollController();
  late List<GlobalKey> _chipKeys;

  @override
  void initState() {
    super.initState();
    _chipKeys = _keysForCount(widget.days.length);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollSelectedIntoView();
    });
  }

  @override
  void didUpdateWidget(DateGroupedDayTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.days.length != _chipKeys.length) {
      _chipKeys = _keysForCount(widget.days.length);
    }
    if (oldWidget.selected != widget.selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollSelectedIntoView();
      });
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  List<GlobalKey> _keysForCount(int count) =>
      List<GlobalKey>.generate(count, (_) => GlobalKey());

  void _scrollSelectedIntoView() {
    if (!mounted || !_scrollCtrl.hasClients) {
      return;
    }

    final index = widget.days.indexWhere((day) => day == widget.selected);
    if (index < 0 || index >= _chipKeys.length) {
      return;
    }

    final position = _scrollCtrl.position;
    final target = computeDateGroupedDayTabBarScrollTarget(
      index: index,
      viewportWidth: position.viewportDimension,
      currentOffset: position.pixels,
      maxScrollExtent: position.maxScrollExtent,
    );

    final chipContext = _chipKeys[index].currentContext;
    if (target == null && chipContext != null) {
      return;
    }

    if (target != null) {
      position
          .animateTo(
            target,
            duration: Theme.of(context).tokens.durationMedium,
            curve: Curves.easeInOut,
          )
          .then((_) {
            if (mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _refineSelectedChipVisibility(index);
              });
            }
          });
      return;
    }

    _refineSelectedChipVisibility(index);
  }

  void _refineSelectedChipVisibility(int index) {
    if (!mounted || index >= _chipKeys.length) {
      return;
    }

    final chipContext = _chipKeys[index].currentContext;
    if (chipContext == null) {
      return;
    }

    // ensureVisible respects text direction — correct for RTL day tabs.
    Scrollable.ensureVisible(
      chipContext,
      duration: Theme.of(context).tokens.durationMedium,
      curve: Curves.easeInOut,
      alignment: 0.5,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.tokens;
    final dayRadius = tokens.resolveRadius(
      family: TilawaRadiusFamily.selection,
    );
    final locale = Localizations.localeOf(context).languageCode;
    final weekdayFmt = DateFormat('EEE', locale);
    final dayFmt = DateFormat('d', locale);
    final monthFmt = DateFormat('MMM', locale);
    final tabHeight = tokens.spaceXXL * 2 + tokens.spaceMedium;
    final chipWidth = tokens.spaceXXL + tokens.spaceExtraLarge;
    final textTheme = theme.textTheme;

    return SizedBox(
      height: tabHeight,
      child: ListView.separated(
        controller: _scrollCtrl,
        scrollDirection: Axis.horizontal,
        itemCount: widget.days.length,
        separatorBuilder: (_, _) => SizedBox(width: tokens.spaceSmall),
        itemBuilder: (context, i) {
          final day = widget.days[i];
          final isSelected = day == widget.selected;

          return KeyedSubtree(
            key: _chipKeys[i],
            child: TilawaInteractiveSurface(
              onTap: () => widget.onDaySelected(day),
              borderRadius: BorderRadius.circular(dayRadius),
              selected: isSelected,
              semanticLabel:
                  '${weekdayFmt.format(day)} '
                  '${dayFmt.format(day)} ${monthFmt.format(day)}',
              child: AnimatedContainer(
                duration: tokens.durationFast,
                width: chipWidth,
                decoration: BoxDecoration(
                  color: isSelected
                      ? scheme.primary
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(dayRadius),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      weekdayFmt.format(day),
                      style: textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? scheme.onPrimary
                            : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: tokens.spaceExtraSmall / 2),
                    Text(
                      dayFmt.format(day),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isSelected ? scheme.onPrimary : scheme.onSurface,
                      ),
                    ),
                    Text(
                      monthFmt.format(day),
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: textTheme.labelSmall!.fontSize! - 1,
                        color: isSelected
                            ? scheme.onPrimary.withValues(alpha: 0.8)
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

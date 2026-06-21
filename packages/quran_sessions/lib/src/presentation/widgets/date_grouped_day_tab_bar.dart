import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

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

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
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

    return SizedBox(
      height: 72,
      child: ListView.separated(
        controller: _scrollCtrl,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: widget.days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final day = widget.days[i];
          final isSelected = day == widget.selected;

          return GestureDetector(
            onTap: () => widget.onDaySelected(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 56,
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
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? scheme.onPrimary
                          : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dayFmt.format(day),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? scheme.onPrimary : scheme.onSurface,
                    ),
                  ),
                  Text(
                    monthFmt.format(day),
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected
                          ? scheme.onPrimary.withValues(alpha: 0.8)
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

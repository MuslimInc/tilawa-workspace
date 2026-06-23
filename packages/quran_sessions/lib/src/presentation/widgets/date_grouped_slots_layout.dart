import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/teacher_availability.dart';
import '../utils/teacher_availability_by_date.dart';
import 'date_grouped_day_tab_bar.dart';

/// Swvl-style layout: horizontal day tabs, body for the selected day's slots.
class DateGroupedSlotsLayout extends StatefulWidget {
  const DateGroupedSlotsLayout({
    super.key,
    required this.slots,
    required this.slotsForDayBuilder,
    this.emptyChild,
    this.initialDay,
    this.padding = EdgeInsets.zero,
    this.belowTabsBuilder,
    this.onSelectedDayChanged,
  });

  final List<TeacherAvailability> slots;
  final Widget? emptyChild;
  final DateTime? initialDay;
  final EdgeInsetsGeometry padding;

  /// Optional caption or helper row under the day chips (e.g. selected day).
  final Widget Function(BuildContext context, DateTime selectedDay)?
  belowTabsBuilder;

  /// Called when the user picks a different day tab.
  final ValueChanged<DateTime>? onSelectedDayChanged;

  /// Builds the slot list/grid for [daySlots] on the selected tab.
  final Widget Function(
    BuildContext context,
    List<TeacherAvailability> daySlots,
  )
  slotsForDayBuilder;

  @override
  State<DateGroupedSlotsLayout> createState() => _DateGroupedSlotsLayoutState();
}

class _DateGroupedSlotsLayoutState extends State<DateGroupedSlotsLayout> {
  late DateTime _selectedDay;
  late List<DateTime> _days;
  late Map<DateTime, List<TeacherAvailability>> _byDay;

  @override
  void initState() {
    super.initState();
    _applySlots(widget.slots);
    _selectedDay = _pickInitialDay();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSelectedDayChanged?.call(_selectedDay);
    });
  }

  @override
  void didUpdateWidget(DateGroupedSlotsLayout old) {
    super.didUpdateWidget(old);
    if (old.slots != widget.slots) {
      _applySlots(widget.slots);
      setState(() {
        if (!_days.contains(_selectedDay)) {
          _selectedDay = _pickInitialDay();
        }
      });
    }
  }

  void _applySlots(List<TeacherAvailability> slots) {
    final grouped = groupTeacherAvailabilityByLocalDay(slots);
    _days = grouped.days;
    _byDay = grouped.byDay;
  }

  DateTime _pickInitialDay() {
    if (_days.isEmpty) return localDayKey(DateTime.now());
    if (widget.initialDay != null && _days.contains(widget.initialDay)) {
      return widget.initialDay!;
    }
    return _days.first;
  }

  @override
  Widget build(BuildContext context) {
    if (_days.isEmpty) {
      return widget.emptyChild ?? const SizedBox.shrink();
    }

    final daySlots = _byDay[_selectedDay] ?? const [];
    final tokens = Theme.of(context).tokens;

    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DateGroupedDayTabBar(
            days: _days,
            selected: _selectedDay,
            onDaySelected: (day) {
              setState(() => _selectedDay = day);
              widget.onSelectedDayChanged?.call(day);
            },
          ),
          if (widget.belowTabsBuilder != null) ...[
            SizedBox(height: tokens.spaceSmall),
            widget.belowTabsBuilder!(context, _selectedDay),
          ],
          SizedBox(height: tokens.spaceMedium),
          widget.slotsForDayBuilder(context, daySlots),
        ],
      ),
    );
  }
}

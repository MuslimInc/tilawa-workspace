import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/teacher_availability.dart';

/// Appointment-style slot picker: horizontal day tabs on top, time grid below.
///
/// Groups [slots] by calendar date, shows the next 14 days (skipping days with
/// no available slots), and highlights the selected slot.
class DateGroupedSlotPicker extends StatefulWidget {
  const DateGroupedSlotPicker({
    super.key,
    required this.slots,
    required this.selectedSlotId,
    required this.onSlotSelected,
    this.initialSlotId,
  });

  final List<TeacherAvailability> slots;
  final String? selectedSlotId;
  final String? initialSlotId;
  final ValueChanged<TeacherAvailability> onSlotSelected;

  @override
  State<DateGroupedSlotPicker> createState() => _DateGroupedSlotPickerState();
}

class _DateGroupedSlotPickerState extends State<DateGroupedSlotPicker> {
  late DateTime _selectedDay;
  late Map<DateTime, List<TeacherAvailability>> _grouped;
  late List<DateTime> _days;

  @override
  void initState() {
    super.initState();
    _grouped = _groupByDay(widget.slots);
    _days = _grouped.keys.toList()..sort();
    _selectedDay = _pickInitialDay();
  }

  @override
  void didUpdateWidget(DateGroupedSlotPicker old) {
    super.didUpdateWidget(old);
    if (old.slots != widget.slots) {
      _grouped = _groupByDay(widget.slots);
      _days = _grouped.keys.toList()..sort();
      if (!_days.contains(_selectedDay)) {
        _selectedDay = _pickInitialDay();
      }
    }
  }

  DateTime _pickInitialDay() {
    if (_days.isEmpty) return _today();
    // If a pre-selected slot exists, jump to its day.
    if (widget.initialSlotId != null) {
      for (final slot in widget.slots) {
        if (slot.slotId == widget.initialSlotId) {
          final d = _dateOnly(slot.startsAt);
          if (_days.contains(d)) return d;
        }
      }
    }
    return _days.first;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_days.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('لا توجد مواعيد متاحة')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DayTabBar(
          days: _days,
          selected: _selectedDay,
          onDaySelected: (d) => setState(() => _selectedDay = d),
        ),
        const SizedBox(height: 12),
        _TimeGrid(
          slots: _grouped[_selectedDay] ?? [],
          selectedSlotId: widget.selectedSlotId,
          onSlotSelected: widget.onSlotSelected,
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Map<DateTime, List<TeacherAvailability>> _groupByDay(
    List<TeacherAvailability> slots,
  ) {
    final map = <DateTime, List<TeacherAvailability>>{};
    for (final slot in slots) {
      final day = _dateOnly(slot.startsAt);
      (map[day] ??= []).add(slot);
    }
    return map;
  }

  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }
}

// ── Day tab bar ────────────────────────────────────────────────────────────────

class _DayTabBar extends StatefulWidget {
  const _DayTabBar({
    required this.days,
    required this.selected,
    required this.onDaySelected,
  });

  final List<DateTime> days;
  final DateTime selected;
  final ValueChanged<DateTime> onDaySelected;

  @override
  State<_DayTabBar> createState() => _DayTabBarState();
}

class _DayTabBarState extends State<_DayTabBar> {
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final weekdayFmt = DateFormat('EEE', 'ar');
    final dayFmt = DateFormat('d', 'ar');
    final monthFmt = DateFormat('MMM', 'ar');

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
                color: isSelected ? scheme.primary : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
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
                      color: isSelected
                          ? scheme.onPrimary
                          : scheme.onSurface,
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

// ── Time grid ─────────────────────────────────────────────────────────────────

class _TimeGrid extends StatelessWidget {
  const _TimeGrid({
    required this.slots,
    required this.selectedSlotId,
    required this.onSlotSelected,
  });

  final List<TeacherAvailability> slots;
  final String? selectedSlotId;
  final ValueChanged<TeacherAvailability> onSlotSelected;

  @override
  Widget build(BuildContext context) {
    final available = slots.where((s) => !s.isBooked).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    if (available.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: Text('لا توجد مواعيد متاحة في هذا اليوم')),
      );
    }

    final timeFmt = DateFormat('h:mm a', 'ar');
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: available.map((slot) {
        final isSelected = slot.slotId == selectedSlotId;
        return ChoiceChip(
          label: Text(timeFmt.format(slot.startsAt.toLocal())),
          selected: isSelected,
          selectedColor: scheme.primary,
          labelStyle: TextStyle(
            color: isSelected ? scheme.onPrimary : scheme.onSurface,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          ),
          onSelected: (_) => onSlotSelected(slot),
        );
      }).toList(),
    );
  }
}

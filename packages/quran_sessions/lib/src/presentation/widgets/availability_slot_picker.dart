import 'package:flutter/material.dart';

import '../../domain/entities/teacher_availability.dart';

/// Horizontal scroll list of available time slots.
/// Placeholder — replace with a proper calendar/grid in the implementation phase.
class AvailabilitySlotPicker extends StatelessWidget {
  const AvailabilitySlotPicker({
    super.key,
    required this.slots,
    required this.selectedSlotId,
    required this.onSlotSelected,
  });

  final List<TeacherAvailability> slots;
  final String? selectedSlotId;
  final ValueChanged<TeacherAvailability> onSlotSelected;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return const Text('No available slots');
    }
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: slots.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final slot = slots[i];
          final isSelected = slot.slotId == selectedSlotId;
          return ChoiceChip(
            label: Text(
              '${slot.startsAt.hour}:${slot.startsAt.minute.toString().padLeft(2, '0')}',
            ),
            selected: isSelected,
            onSelected: slot.isBooked ? null : (_) => onSlotSelected(slot),
          );
        },
      ),
    );
  }
}

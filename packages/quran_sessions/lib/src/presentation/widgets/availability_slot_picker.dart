import 'package:flutter/material.dart';

import '../../domain/entities/teacher_availability.dart';
import 'date_grouped_slot_picker.dart';

/// Wraps [DateGroupedSlotPicker] — retained for backward-compatible call sites.
class AvailabilitySlotPicker extends StatelessWidget {
  const AvailabilitySlotPicker({
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
  Widget build(BuildContext context) {
    return DateGroupedSlotPicker(
      slots: slots,
      selectedSlotId: selectedSlotId,
      initialSlotId: initialSlotId ?? selectedSlotId,
      onSlotSelected: onSlotSelected,
    );
  }
}

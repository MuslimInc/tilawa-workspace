import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/teacher_availability.dart';
import '../../domain/services/teacher_availability_sort.dart';
import '../utils/teacher_availability_by_date.dart';
import 'date_grouped_slots_layout.dart';

/// Appointment-style slot picker: horizontal day tabs on top, time grid below.
///
/// Groups [slots] by calendar date (local timezone), earliest day first, and
/// highlights the selected slot.
class DateGroupedSlotPicker extends StatelessWidget {
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

  DateTime? _initialDay() {
    if (initialSlotId == null) return null;
    for (final slot in slots) {
      if (slot.slotId == initialSlotId) {
        return localDayKey(slot.startsAt);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SlotPickerTimezoneBanner(message: l10n.slotPickerLocalTimezoneNote),
        SizedBox(height: theme.tokens.spaceSmall),
        DateGroupedSlotsLayout(
          slots: slots,
          initialDay: _initialDay(),
          emptyChild: Padding(
            padding: EdgeInsets.all(theme.tokens.spaceSmall),
            child: Center(
              child: Text(
                l10n.noSlotsAvailable,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ),
          ),
          slotsForDayBuilder: (context, daySlots) => _TimeGrid(
            slots: daySlots,
            selectedSlotId: selectedSlotId,
            onSlotSelected: onSlotSelected,
          ),
        ),
      ],
    );
  }
}

class _SlotPickerTimezoneBanner extends StatelessWidget {
  const _SlotPickerTimezoneBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.tokens;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(
          tokens.resolveRadius(family: TilawaRadiusFamily.chrome),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceSmall,
          vertical: tokens.spaceExtraSmall + 2,
        ),
        child: Row(
          children: [
            Icon(
              Icons.schedule_outlined,
              size: tokens.iconSizeSmall,
              color: scheme.onSurfaceVariant,
            ),
            SizedBox(width: tokens.spaceExtraSmall),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
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
    final l10n = context.quranSessionsL10n;
    final theme = Theme.of(context);
    final available = sortTeacherAvailabilityByStart(
      slots.where((s) => !s.isBooked).toList(),
    );

    if (available.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: theme.tokens.spaceSmall),
        child: Center(
          child: Text(
            l10n.noSlotsAvailableThisDay,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ),
      );
    }

    final locale = Localizations.localeOf(context).languageCode;
    final timeFmt = DateFormat('h:mm a', locale);

    return Wrap(
      spacing: theme.tokens.spaceExtraSmall + 2,
      runSpacing: theme.tokens.spaceExtraSmall + 2,
      children: available.map((slot) {
        final isSelected = slot.slotId == selectedSlotId;
        return TilawaSelectionPill(
          label: timeFmt.format(slot.startsAt.toLocal()),
          selected: isSelected,
          onTap: () => onSlotSelected(slot),
        );
      }).toList(),
    );
  }
}

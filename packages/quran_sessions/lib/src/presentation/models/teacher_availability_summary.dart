import 'package:intl/intl.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';

import '../../domain/entities/teacher_availability.dart';

enum TeacherAvailabilityStatus {
  availableToday,
  availableTomorrow,
  future,
  noSlots,
  unavailable,
}

class TeacherAvailabilitySummary {
  const TeacherAvailabilitySummary({
    required this.teacherId,
    required this.status,
    this.nextAvailableSlot,
  });

  final String teacherId;
  final TeacherAvailabilityStatus status;
  final TeacherAvailability? nextAvailableSlot;

  bool get hasAvailableSlots => nextAvailableSlot != null;

  String availabilityLabel(
    QuranSessionsLocalizations l10n, {
    required String localeName,
  }) {
    return switch (status) {
      TeacherAvailabilityStatus.availableToday => l10n.teacherAvailabilityToday,
      TeacherAvailabilityStatus.availableTomorrow =>
        l10n.teacherAvailabilityTomorrow,
      TeacherAvailabilityStatus.future => l10n.teacherAvailabilityNextAt(
        _formatSlotStart(localeName),
      ),
      TeacherAvailabilityStatus.noSlots => l10n.teacherAvailabilityNoSlots,
      TeacherAvailabilityStatus.unavailable =>
        l10n.teacherAvailabilityUnavailable,
    };
  }

  String _formatSlotStart(String localeName) {
    final slot = nextAvailableSlot;
    if (slot == null) return '';
    return DateFormat('EEE h:mm a', localeName).format(slot.startsAt.toLocal());
  }
}

class TeacherAvailabilitySummaryPresenter {
  const TeacherAvailabilitySummaryPresenter({this.now});

  final DateTime Function()? now;

  TeacherAvailabilitySummary fromSlots({
    required String teacherId,
    required List<TeacherAvailability> slots,
  }) {
    final current = now?.call() ?? DateTime.now();
    final availableSlots =
        slots
            .where((slot) => !slot.isBooked && slot.startsAt.isAfter(current))
            .toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    if (availableSlots.isEmpty) {
      return TeacherAvailabilitySummary(
        teacherId: teacherId,
        status: TeacherAvailabilityStatus.noSlots,
      );
    }

    final nextSlot = availableSlots.first;
    final localNow = current.toLocal();
    final localStart = nextSlot.startsAt.toLocal();
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    final slotDay = DateTime(localStart.year, localStart.month, localStart.day);
    final daysUntil = slotDay.difference(today).inDays;

    final status = switch (daysUntil) {
      0 => TeacherAvailabilityStatus.availableToday,
      1 => TeacherAvailabilityStatus.availableTomorrow,
      _ => TeacherAvailabilityStatus.future,
    };

    return TeacherAvailabilitySummary(
      teacherId: teacherId,
      status: status,
      nextAvailableSlot: nextSlot,
    );
  }

  TeacherAvailabilitySummary unavailable(String teacherId) {
    return TeacherAvailabilitySummary(
      teacherId: teacherId,
      status: TeacherAvailabilityStatus.unavailable,
    );
  }
}

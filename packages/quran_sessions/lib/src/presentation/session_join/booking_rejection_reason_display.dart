import '../widgets/tutor_reject_booking_sheet.dart'
    show tutorRejectBookingReasonMaxLength;

/// Returns [raw] trimmed and stripped of control chars for student display.
///
/// Returns null when empty or unsafe to show.
String? safeBookingRejectionReasonForDisplay(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final cleaned = trimmed.replaceAll(
    RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'),
    '',
  );
  if (cleaned.isEmpty) return null;
  if (cleaned.length > tutorRejectBookingReasonMaxLength) {
    return cleaned.substring(0, tutorRejectBookingReasonMaxLength);
  }
  return cleaned;
}

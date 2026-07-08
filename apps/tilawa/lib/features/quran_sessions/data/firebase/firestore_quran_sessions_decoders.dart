import 'package:quran_sessions/quran_sessions.dart';

import 'firestore_exception_mapper.dart';

/// Shared raw-doc → DTO decoders.
///
/// The dashboard summary doc embeds sessions/schedule/overrides with the same
/// raw field shapes as their source collections, so the summary data source
/// and the per-collection data sources MUST decode through these same
/// functions — that is what keeps the one-read path and the legacy path in
/// lockstep.

QuranSessionDto quranSessionDtoFromDocData(
  String docId,
  Map<String, dynamic> data,
) {
  final lifecycleRaw = resolveLifecycleStatusRawFromFirestore(data);
  final bookingId = resolveBookingIdFromFirestore(docId, data);
  final statusRaw = lifecycleRaw ?? data['status'] as String? ?? 'scheduled';
  return QuranSessionDto(
    id: docId,
    bookingId: bookingId,
    teacherId: data['teacherId'] as String? ?? '',
    studentId: data['studentId'] as String? ?? '',
    startsAt: readRequiredDateTime(data['startsAt']).toUtc().toIso8601String(),
    endsAt: readRequiredDateTime(data['endsAt']).toUtc().toIso8601String(),
    callType: _mapCallType(data['callType'] as String?),
    status: _mapSessionStatus(statusRaw),
    lifecycleStatus: lifecycleRaw ?? data['lifecycleStatus'] as String?,
    meetingLink: (data['meetingLink'] ?? data['meeting_link']) as String?,
    callRoomId: (data['providerSessionId'] ?? data['callRoomId']) as String?,
    bookingType: data['bookingType'] as String?,
    callProvider: data['callProvider'] as String?,
    providerSessionId: data['providerSessionId'] as String?,
    joinToken: data['joinToken'] as String?,
    participants: data['participants'],
    notes: data['notes'] as String?,
    paymentReference:
        (data['paymentReference'] ?? data['payment_reference']) as String?,
    paymentProvider:
        (data['paymentProvider'] ?? data['payment_provider']) as String?,
    paymentStatus: (data['paymentStatus'] ?? data['payment_status']) as String?,
  );
}

String _mapCallType(String? raw) => switch (raw) {
  'voiceCall' => 'voice_call',
  'videoCall' => 'video_call',
  _ => 'external_meeting',
};

String _mapSessionStatus(String? raw) => switch (raw) {
  'inProgress' => 'in_progress',
  'cancelledByStudent' => 'cancelled_by_student',
  'cancelledByTeacher' => 'cancelled_by_teacher',
  'noShow' => 'no_show',
  _ => raw ?? 'scheduled',
};

WeeklyScheduleDto weeklyScheduleDtoFromDocData(
  String teacherId,
  Map<String, dynamic> data,
) {
  return WeeklyScheduleDto(
    teacherId: teacherId,
    timezone: data['timezone'] as String? ?? 'Africa/Cairo',
    slotDurationMinutes: data['slotDurationMinutes'] as int? ?? 30,
    minNoticeMinutes: data['minNoticeMinutes'] as int? ?? 120,
    maxHorizonDays: data['maxHorizonDays'] as int? ?? 30,
    bufferBeforeMinutes: data['bufferBeforeMinutes'] as int? ?? 0,
    bufferAfterMinutes: data['bufferAfterMinutes'] as int? ?? 0,
    weeklyRules: readWeeklyRules(data['weeklyRules']),
    version: data['version'] as int? ?? 1,
    updatedAt: readDateTime(data['updatedAt'])?.toUtc().toIso8601String(),
  );
}

AvailabilityOverrideDto availabilityOverrideDtoFromDocData(
  String docId,
  Map<String, dynamic> data,
) {
  return AvailabilityOverrideDto(
    date: data['date'] as String? ?? docId,
    type: data['type'] as String? ?? 'unavailable',
    intervals: readTimeIntervals(data['intervals']),
    reason: data['reason'] as String?,
  );
}

Map<String, List<Map<String, String>>> readWeeklyRules(Object? raw) {
  if (raw is! Map) return const {};
  final result = <String, List<Map<String, String>>>{};
  raw.forEach((key, value) {
    result['$key'] = readTimeIntervals(value);
  });
  return result;
}

List<Map<String, String>> readTimeIntervals(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map(
        (m) => {
          'start': m['start'] as String? ?? '00:00',
          'end': m['end'] as String? ?? '00:00',
        },
      )
      .toList();
}

import '../../domain/entities/session_lifecycle_status.dart';
import '../../domain/entities/quran_session.dart';
import '../../domain/entities/session_booking_type.dart';
import '../../domain/entities/session_call_provider_kind.dart';
import '../../domain/entities/session_call_type.dart';
import '../../domain/entities/session_participant.dart';
import '../../domain/entities/session_participant_role.dart';
import '../dtos/quran_session_dto.dart';

extension QuranSessionDtoMapper on QuranSessionDto {
  QuranSession toDomain() => QuranSession(
    id: id,
    bookingId: bookingId,
    teacherId: teacherId,
    studentId: studentId,
    startsAt: DateTime.parse(startsAt),
    endsAt: DateTime.parse(endsAt),
    callType: _mapCallType(callType),
    status: _mapStatus(status),
    lifecycleStatus: lifecycleStatus == null
        ? null
        : _mapLifecycleStatus(lifecycleStatus!),
    bookingType: _mapBookingType(bookingType),
    callProviderKind: _mapCallProvider(callProvider),
    meetingLink: meetingLink,
    callRoomId: callRoomId,
    providerSessionId: providerSessionId ?? callRoomId,
    joinToken: joinToken,
    participants: _mapParticipants(participants),
    notes: notes,
  );
}

SessionCallType _mapCallType(String raw) => switch (raw) {
  'external_meeting' || 'externalMeeting' => SessionCallType.externalMeeting,
  'voice_call' || 'voiceCall' => SessionCallType.voiceCall,
  'video_call' || 'videoCall' => SessionCallType.videoCall,
  _ => SessionCallType.externalMeeting,
};

SessionBookingType _mapBookingType(String? raw) => switch (raw) {
  'group' => SessionBookingType.group,
  _ => SessionBookingType.individual,
};

SessionCallProviderKind _mapCallProvider(String? raw) => switch (raw) {
  'mock' => SessionCallProviderKind.mock,
  'agora' => SessionCallProviderKind.agora,
  'webrtc' => SessionCallProviderKind.webrtc,
  _ => SessionCallProviderKind.external,
};

List<SessionParticipant> _mapParticipants(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map(
        (entry) => SessionParticipant(
          userId: entry['userId'] as String? ?? '',
          role: _mapParticipantRole(entry['role'] as String?),
        ),
      )
      .where((p) => p.userId.isNotEmpty)
      .toList();
}

SessionParticipantRole _mapParticipantRole(String? raw) => raw == 'teacher'
    ? SessionParticipantRole.teacher
    : SessionParticipantRole.student;

QuranSessionStatus _mapStatus(String raw) => switch (raw) {
  'scheduled' || 'confirmed' => QuranSessionStatus.scheduled,
  'pending' => QuranSessionStatus.scheduled,
  'in_progress' || 'inProgress' => QuranSessionStatus.inProgress,
  'completed' => QuranSessionStatus.completed,
  'cancelled_by_student' ||
  'cancelledByStudent' => QuranSessionStatus.cancelledByStudent,
  'cancelled_by_teacher' ||
  'cancelledByTeacher' => QuranSessionStatus.cancelledByTeacher,
  'no_show' || 'noShow' => QuranSessionStatus.noShow,
  'rejected' => QuranSessionStatus.noShow,
  _ => QuranSessionStatus.scheduled,
};

SessionLifecycleStatus _mapLifecycleStatus(String raw) {
  final normalized = raw.replaceAllMapped(
    RegExp(r'_([a-z])'),
    (match) => match.group(1)!.toUpperCase(),
  );
  return SessionLifecycleStatus.values.firstWhere(
    (s) => s.name == raw || s.name == normalized,
    orElse: () => SessionLifecycleStatus.scheduled,
  );
}

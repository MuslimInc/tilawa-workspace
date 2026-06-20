import '../../domain/entities/quran_session.dart';
import '../../domain/entities/session_call_type.dart';
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
    meetingLink: meetingLink,
    callRoomId: callRoomId,
    notes: notes,
  );
}

SessionCallType _mapCallType(String raw) => switch (raw) {
  'external_meeting' => SessionCallType.externalMeeting,
  'voice_call' => SessionCallType.voiceCall,
  'video_call' => SessionCallType.videoCall,
  _ => SessionCallType.externalMeeting,
};

QuranSessionStatus _mapStatus(String raw) => switch (raw) {
  'scheduled' => QuranSessionStatus.scheduled,
  'in_progress' => QuranSessionStatus.inProgress,
  'completed' => QuranSessionStatus.completed,
  'cancelled_by_student' => QuranSessionStatus.cancelledByStudent,
  'cancelled_by_teacher' => QuranSessionStatus.cancelledByTeacher,
  'no_show' => QuranSessionStatus.noShow,
  _ => QuranSessionStatus.scheduled,
};

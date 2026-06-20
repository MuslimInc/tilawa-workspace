import '../../lib/src/domain/entities/quran_booking.dart';
import '../../lib/src/domain/entities/quran_session.dart';
import '../../lib/src/domain/entities/quran_teacher.dart';
import '../../lib/src/domain/entities/session_call_type.dart';
import '../../lib/src/domain/entities/session_pricing_type.dart';
import '../../lib/src/domain/entities/teacher_availability.dart';
import '../../lib/src/domain/entities/teacher_verification_status.dart';

QuranBooking makeBooking({
  String id = 'booking_1',
  String teacherId = 'teacher_1',
  String studentId = 'student_1',
  String slotId = 'slot_1',
  BookingStatus status = BookingStatus.confirmed,
  DateTime? createdAt,
}) => QuranBooking(
  id: id,
  teacherId: teacherId,
  studentId: studentId,
  slotId: slotId,
  requestedCallType: SessionCallType.externalMeeting,
  pricingType: SessionPricingType.free,
  status: status,
  createdAt: createdAt ?? DateTime.now(),
);

QuranTeacher makeTeacher({
  String id = 'teacher_1',
  String displayName = 'Sheikh Ahmed',
  TeacherVerificationStatus status = TeacherVerificationStatus.verified,
  List<String> specializations = const ['tajweed'],
  double rating = 4.8,
}) => QuranTeacher(
  id: id,
  displayName: displayName,
  bio: 'Experienced Quran teacher',
  avatarUrl: 'https://example.com/avatar.png',
  verificationStatus: status,
  supportedCallTypes: const [SessionCallType.externalMeeting],
  pricingType: SessionPricingType.fixedPerSession,
  pricePerSessionUsd: 20.0,
  specializations: specializations,
  languages: const ['ar', 'en'],
  averageRating: rating,
  totalReviews: 42,
  totalSessionsCompleted: 120,
);

TeacherAvailability makeSlot({
  String slotId = 'slot_1',
  String teacherId = 'teacher_1',
  bool isBooked = false,
  DateTime? startsAt,
}) {
  final start = startsAt ?? DateTime.now().add(const Duration(days: 1));
  return TeacherAvailability(
    slotId: slotId,
    teacherId: teacherId,
    startsAt: start,
    endsAt: start.add(const Duration(hours: 1)),
    isBooked: isBooked,
  );
}

QuranSession makeSession({
  String id = 'session_1',
  String studentId = 'student_1',
  String teacherId = 'teacher_1',
  QuranSessionStatus status = QuranSessionStatus.scheduled,
  DateTime? startsAt,
}) {
  final start = startsAt ?? DateTime.now().add(const Duration(days: 1));
  return QuranSession(
    id: id,
    bookingId: 'booking_1',
    teacherId: teacherId,
    studentId: studentId,
    startsAt: start,
    endsAt: start.add(const Duration(hours: 1)),
    callType: SessionCallType.externalMeeting,
    status: status,
    meetingLink: 'https://meet.example.com/room',
  );
}

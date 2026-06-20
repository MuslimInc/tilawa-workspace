import 'package:quran_sessions/quran_sessions.dart';

/// Singleton in-memory data store for the Quran Sessions MVP.
///
/// All fake repositories share this instance so that a booking created in
/// [FakeMvpBookingRepository] is immediately visible in
/// [FakeMvpSessionRepository].
class QuranSessionsMvpStore {
  QuranSessionsMvpStore._();
  static final QuranSessionsMvpStore instance = QuranSessionsMvpStore._();

  final List<QuranTeacher> teachers = _buildTeachers();
  final List<TeacherAvailability> slots = _buildSlots();
  final List<QuranBooking> bookings = [];
  final List<QuranSession> sessions = [];

  // ── Fake teacher data ──────────────────────────────────────────────────────

  static List<QuranTeacher> _buildTeachers() => [
    const QuranTeacher(
      id: 'teacher_1',
      displayName: 'الشيخ عبدالله الأحمدي',
      bio:
          'حافظ للقرآن الكريم بالقراءات العشر، متخصص في تعليم أحكام التجويد '
          'والقراءة الصحيحة. خبرة تزيد على خمس عشرة سنة في تدريس القرآن '
          'لكافة الأعمار عبر الإنترنت ووجهاً لوجه.',
      avatarUrl: '',
      verificationStatus: TeacherVerificationStatus.verified,
      supportedCallTypes: [SessionCallType.externalMeeting],
      pricingType: SessionPricingType.fixedPerSession,
      pricePerSessionUsd: 15,
      specializations: ['tajweed', 'recitation', 'review'],
      languages: ['ar', 'en'],
      averageRating: 4.9,
      totalReviews: 128,
      totalSessionsCompleted: 340,
    ),
    const QuranTeacher(
      id: 'teacher_2',
      displayName: 'أ. فاطمة النووي',
      bio:
          'متخصصة في تعليم الأطفال قراءة القرآن الكريم، حاصلة على إجازة '
          'بالسند المتصل بالقراءة الحفص. أسلوبها محبب ومشجع يجعل الطفل '
          'يحب القرآن الكريم منذ الصغر.',
      avatarUrl: '',
      verificationStatus: TeacherVerificationStatus.verified,
      supportedCallTypes: [SessionCallType.externalMeeting],
      pricingType: SessionPricingType.free,
      pricePerSessionUsd: null,
      specializations: ['children', 'hifz'],
      languages: ['ar'],
      averageRating: 4.8,
      totalReviews: 74,
      totalSessionsCompleted: 210,
    ),
    const QuranTeacher(
      id: 'teacher_3',
      displayName: 'الشيخ ماهر الزياد',
      bio:
          'معلم قرآن كريم متميز، حافظ للقرآن مع الإتقان الكامل لأحكام '
          'التجويد. يدرّس الحفظ والمراجعة وتصحيح التلاوة بأسلوب منهجي '
          'مبني على التكرار والتثبيت. متاح للطلاب الناطقين بالعربية والأردية.',
      avatarUrl: '',
      verificationStatus: TeacherVerificationStatus.verified,
      supportedCallTypes: [SessionCallType.externalMeeting],
      pricingType: SessionPricingType.fixedPerSession,
      pricePerSessionUsd: 20,
      specializations: ['hifz', 'review', 'recitation', 'tajweed'],
      languages: ['ar', 'ur'],
      averageRating: 4.7,
      totalReviews: 55,
      totalSessionsCompleted: 180,
    ),
  ];

  // ── Fake availability slots ────────────────────────────────────────────────
  // Each teacher has a slightly different schedule to feel realistic.

  static List<TeacherAvailability> _buildSlots() {
    final slots = <TeacherAvailability>[];
    final now = DateTime.now();

    for (var dayOffset = 1; dayOffset <= 14; dayOffset++) {
      final day = now.add(Duration(days: dayOffset));
      if (day.weekday == DateTime.friday) continue;

      // Teacher 1: morning + evening, Mon–Thu + Sat–Sun
      if (day.weekday != DateTime.friday) {
        _addSlot(slots, 'teacher_1', day, 9, 0, dayOffset);
        _addSlot(slots, 'teacher_1', day, 11, 0, dayOffset);
        if (day.weekday != DateTime.saturday &&
            day.weekday != DateTime.sunday) {
          _addSlot(slots, 'teacher_1', day, 20, 0, dayOffset);
        }
      }

      // Teacher 2: mornings only (family schedule)
      _addSlot(slots, 'teacher_2', day, 8, 0, dayOffset);
      _addSlot(slots, 'teacher_2', day, 10, 0, dayOffset);
      if (day.weekday == DateTime.saturday ||
          day.weekday == DateTime.sunday) {
        _addSlot(slots, 'teacher_2', day, 14, 0, dayOffset);
      }

      // Teacher 3: afternoon + evening
      _addSlot(slots, 'teacher_3', day, 15, 0, dayOffset);
      _addSlot(slots, 'teacher_3', day, 17, 0, dayOffset);
      if (day.weekday != DateTime.wednesday) {
        _addSlot(slots, 'teacher_3', day, 21, 0, dayOffset);
      }
    }

    return slots;
  }

  static int _slotCounter = 0;

  static void _addSlot(
    List<TeacherAvailability> slots,
    String teacherId,
    DateTime day,
    int hour,
    int minute,
    int dayOffset,
  ) {
    final start = DateTime(day.year, day.month, day.day, hour, minute);
    slots.add(
      TeacherAvailability(
        slotId: '${teacherId}_s${_slotCounter++}',
        teacherId: teacherId,
        startsAt: start,
        endsAt: start.add(const Duration(hours: 1)),
        isBooked: false,
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Returns the display name for [teacherId], or null if not found.
  String? resolveTeacherName(String teacherId) => teachers
      .where((t) => t.id == teacherId)
      .map((t) => t.displayName)
      .firstOrNull;
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}

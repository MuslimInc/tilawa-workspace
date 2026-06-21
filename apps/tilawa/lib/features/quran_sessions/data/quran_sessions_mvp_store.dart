import 'package:quran_sessions/quran_sessions.dart';

/// Singleton in-memory data store for the Quran Sessions MVP.
///
/// All fake repositories share this instance so that a booking created in
/// [FakeMvpBookingRepository] is immediately visible in
/// [FakeMvpSessionRepository].
///
/// Teacher pricing is stored per-market (country/city) rather than as a
/// single hardcoded USD amount. This mirrors the production Firestore shape:
///   `teachers/{id}/pricing/{marketId}`
/// where `marketId` is `{countryCode}_{cityId}`.
///
/// EGP is used here because the only enabled MVP market is Egypt.
/// It is NOT a global default — other markets will have their own currencies.
class QuranSessionsMvpStore {
  QuranSessionsMvpStore._();
  static final QuranSessionsMvpStore instance = QuranSessionsMvpStore._();

  final List<QuranTeacher> teachers = _buildTeachers();
  final List<TeacherAvailability> slots = _buildSlots();
  final List<QuranBooking> bookings = [];
  final List<QuranSession> sessions = [];

  // ── Teacher application & profile stores ──────────────────────────────────
  // Keyed by userId. A TeacherProfile is created only after approval.
  final Map<String, TeacherApplication> teacherApplications = {};
  final Map<String, TeacherProfile> teacherProfiles = {};

  // ── User profiles ──────────────────────────────────────────────────────────
  // student_mvp starts with NO fields to exercise the full profile-completion
  // gate (gender, DOB, country, city all required before booking).

  final Map<String, UserProfile> profiles = _buildProfiles();

  static Map<String, UserProfile> _buildProfiles() => {
    'student_mvp': const UserProfile(
      userId: 'student_mvp',
      role: UserRole.student,
      accountStatus: AccountStatus.active,
      displayName: 'Tilawa User',
      // No gender / DOB / country / city → profile gate fires on first entry.
    ),
    // Teachers are UserRole.student at the UserProfile level.
    // Their teacher capability is represented by an approved TeacherProfile.
    'teacher_1': const UserProfile(
      userId: 'teacher_1',
      role: UserRole.student,
      accountStatus: AccountStatus.active,
      displayName: 'الشيخ عبدالله الأحمدي',
      gender: UserGender.male,
      countryCode: 'EG',
      cityId: 'cairo',
    ),
    'teacher_2': const UserProfile(
      userId: 'teacher_2',
      role: UserRole.student,
      accountStatus: AccountStatus.active,
      displayName: 'أ. فاطمة النووي',
      gender: UserGender.female,
      countryCode: 'EG',
      cityId: 'cairo',
    ),
    'teacher_3': const UserProfile(
      userId: 'teacher_3',
      role: UserRole.student,
      accountStatus: AccountStatus.active,
      displayName: 'الشيخ ماهر الزياد',
      gender: UserGender.male,
      countryCode: 'EG',
      cityId: 'cairo',
    ),
  };

  // ── Safety & eligibility policies ─────────────────────────────────────────
  // Global: both genders allowed; child threshold = 14.

  QuranSessionSafetyPolicy globalSafetyPolicy =
      const QuranSessionSafetyPolicy();

  // Per-teacher eligibility:
  //   teacher_1 (male) → accepts all genders
  //   teacher_2 (female) → females only (strict)
  //   teacher_3 (male) → accepts all genders, but not children
  final Map<String, TeacherEligibilityPolicy> teacherEligibilityPolicies = {
    'teacher_1': const TeacherEligibilityPolicy(
      allowedStudentGender: TeacherAllowedStudentGender.both,
      canTeachChildren: true,
    ),
    'teacher_2': const TeacherEligibilityPolicy(
      allowedStudentGender: TeacherAllowedStudentGender.femaleOnly,
      canTeachChildren: true,
    ),
    'teacher_3': const TeacherEligibilityPolicy(
      allowedStudentGender: TeacherAllowedStudentGender.both,
      canTeachChildren: false,
    ),
  };

  // ── Per-market teacher pricing ─────────────────────────────────────────────
  // Key: teacherId → marketId ('EG_cairo') → SessionPrice.
  // teacher_2 is free → no entry (pricingType governs, not a price amount).

  static const _egyptCairo = 'EG_cairo';
  static const _egyptAlex = 'EG_alexandria';
  static const _egyptGiza = 'EG_giza';

  final Map<String, Map<String, SessionPrice>> teacherMarketPricing = {
    'teacher_1': {
      _egyptCairo: const SessionPrice(
        amount: 600,
        currencyCode: 'EGP',
        countryCode: 'EG',
        cityId: 'cairo',
      ),
      _egyptAlex: const SessionPrice(
        amount: 500,
        currencyCode: 'EGP',
        countryCode: 'EG',
        cityId: 'alexandria',
      ),
      _egyptGiza: const SessionPrice(
        amount: 600,
        currencyCode: 'EGP',
        countryCode: 'EG',
        cityId: 'giza',
      ),
    },
    'teacher_3': {
      _egyptCairo: const SessionPrice(
        amount: 800,
        currencyCode: 'EGP',
        countryCode: 'EG',
        cityId: 'cairo',
      ),
      _egyptAlex: const SessionPrice(
        amount: 700,
        currencyCode: 'EGP',
        countryCode: 'EG',
        cityId: 'alexandria',
      ),
      _egyptGiza: const SessionPrice(
        amount: 800,
        currencyCode: 'EGP',
        countryCode: 'EG',
        cityId: 'giza',
      ),
    },
  };

  /// Resolves the [SessionPrice] for [teacherId] in the given market.
  /// Returns null if the teacher is free or has no pricing for that market.
  SessionPrice? resolvePrice(
    String teacherId,
    String countryCode,
    String cityId,
  ) {
    final marketId = '${countryCode}_$cityId';
    return teacherMarketPricing[teacherId]?[marketId];
  }

  // ── Fake teacher data ──────────────────────────────────────────────────────
  // Prices here use the Egypt/Cairo market as the default display.
  // In production, teachers are loaded with market context so the price
  // is resolved per student market before reaching the UI.

  static List<QuranTeacher> _buildTeachers() => [
    const QuranTeacher(
      id: 'teacher_1',
      displayName: 'الشيخ عبدالله الأحمدي',
      bio:
          'حافظ للقرآن الكريم بالقراءات العشر، متخصص في تعليم أحكام التجويد '
          'والقراءة الصحيحة. خبرة تزيد على خمس عشرة سنة في تدريس القرآن '
          'لكافة الأعمار عبر الإنترنت ووجهاً لوجه.',
      avatarUrl: '',
      gender: UserGender.male,
      verificationStatus: TeacherVerificationStatus.verified,
      supportedCallTypes: [SessionCallType.externalMeeting],
      pricingType: SessionPricingType.fixedPerSession,
      price: SessionPrice(
        amount: 600,
        currencyCode: 'EGP',
        countryCode: 'EG',
        cityId: 'cairo',
      ),
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
      gender: UserGender.female,
      verificationStatus: TeacherVerificationStatus.verified,
      supportedCallTypes: [SessionCallType.externalMeeting],
      pricingType: SessionPricingType.free,
      price: null, // free teacher — no market price
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
      gender: UserGender.male,
      verificationStatus: TeacherVerificationStatus.verified,
      supportedCallTypes: [SessionCallType.externalMeeting],
      pricingType: SessionPricingType.fixedPerSession,
      price: SessionPrice(
        amount: 800,
        currencyCode: 'EGP',
        countryCode: 'EG',
        cityId: 'cairo',
      ),
      specializations: ['hifz', 'review', 'recitation', 'tajweed'],
      languages: ['ar', 'ur'],
      averageRating: 4.7,
      totalReviews: 55,
      totalSessionsCompleted: 180,
    ),
  ];

  // ── Fake availability slots ────────────────────────────────────────────────

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
      if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
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

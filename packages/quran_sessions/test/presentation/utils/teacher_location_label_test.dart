import 'package:checks/checks.dart';
import 'package:quran_sessions/src/domain/entities/quran_teacher.dart';
import 'package:quran_sessions/src/domain/entities/session_pricing_type.dart';
import 'package:quran_sessions/src/domain/entities/teacher_verification_status.dart';
import 'package:quran_sessions/src/domain/entities/user_profile.dart';
import 'package:quran_sessions/src/presentation/utils/teacher_location_label.dart';
import 'package:test/test.dart';

void main() {
  test('formats city and country when both present', () {
    const teacher = QuranTeacher(
      id: 't1',
      displayName: 'Teacher',
      bio: 'Bio',
      avatarUrl: '',
      gender: UserGender.male,
      verificationStatus: TeacherVerificationStatus.verified,
      supportedCallTypes: [],
      pricingType: SessionPricingType.free,
      specializations: [],
      languages: [],
      averageRating: 0,
      totalReviews: 0,
      totalSessionsCompleted: 0,
      cityName: 'Cairo',
      countryName: 'Egypt',
    );

    check(teacherLocationLabel(teacher)).equals('Cairo, Egypt');
  });

  test('returns null when location fields missing', () {
    const teacher = QuranTeacher(
      id: 't1',
      displayName: 'Teacher',
      bio: 'Bio',
      avatarUrl: '',
      gender: UserGender.male,
      verificationStatus: TeacherVerificationStatus.verified,
      supportedCallTypes: [],
      pricingType: SessionPricingType.free,
      specializations: [],
      languages: [],
      averageRating: 0,
      totalReviews: 0,
      totalSessionsCompleted: 0,
    );

    check(teacherLocationLabel(teacher)).isNull();
  });
}

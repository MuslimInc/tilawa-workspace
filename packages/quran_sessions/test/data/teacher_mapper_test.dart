import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/data/dtos/quran_teacher_dto.dart';
import '../../lib/src/data/mappers/teacher_mapper.dart';
import '../../lib/src/domain/entities/teacher_verification_status.dart';

void main() {
  group('QuranTeacherDtoMapper', () {
    test('maps verified teacher correctly', () {
      final dto = QuranTeacherDto(
        id: 'teacher_1',
        displayName: 'Sheikh Ahmed',
        bio: 'Bio',
        avatarUrl: 'https://example.com/avatar.png',
        verificationStatus: 'verified',
        supportedCallTypes: ['external_meeting'],
        pricingType: 'fixed_per_session',
        pricePerSessionUsd: 20.0,
        specializations: ['tajweed'],
        languages: ['ar'],
        averageRating: 4.9,
        totalReviews: 10,
        totalSessionsCompleted: 50,
      );

      final entity = dto.toDomain();

      check(entity.id).equals('teacher_1');
      check(
        entity.verificationStatus,
      ).equals(TeacherVerificationStatus.verified);
      check(entity.isVerified).isTrue();
      check(entity.pricePerSessionUsd).equals(20.0);
    });

    test('falls back to pending for unknown verification status', () {
      final dto = QuranTeacherDto(
        id: 't',
        displayName: 'X',
        bio: '',
        avatarUrl: '',
        verificationStatus: 'unknown_status',
        supportedCallTypes: [],
        pricingType: 'free',
        pricePerSessionUsd: null,
        specializations: [],
        languages: [],
        averageRating: 0,
        totalReviews: 0,
        totalSessionsCompleted: 0,
      );

      check(
        dto.toDomain().verificationStatus,
      ).equals(TeacherVerificationStatus.pending);
    });
  });
}

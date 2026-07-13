import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/data/dtos/quran_teacher_dto.dart';
import '../../lib/src/data/mappers/teacher_mapper.dart';
import '../../lib/src/domain/entities/session_pricing_type.dart';
import '../../lib/src/domain/entities/teacher_verification_status.dart';

void main() {
  group('QuranTeacherDtoMapper', () {
    test('maps verified teacher with market price correctly', () {
      const dto = QuranTeacherDto(
        id: 'teacher_1',
        displayName: 'Sheikh Ahmed',
        bio: 'Bio',
        avatarUrl: 'https://example.com/avatar.png',
        gender: 'male',
        verificationStatus: 'verified',
        supportedCallTypes: ['external_meeting'],
        pricingType: 'fixed_per_session',
        marketPrice: SessionPriceDto(
          amount: 600,
          currencyCode: 'EGP',
          countryCode: 'EG',
          cityId: 'cairo',
        ),
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
      check(entity.price).isNotNull();
      check(entity.price!.amount).equals(600);
      check(entity.price!.currencyCode).equals('EGP');
      check(entity.pricingType).equals(SessionPricingType.fixedPerSession);
    });

    test('maps manualPaymentPrice without changing free pricing type', () {
      const dto = QuranTeacherDto(
        id: 'founding_1',
        displayName: 'Sheikh Founding',
        bio: '',
        avatarUrl: '',
        gender: 'male',
        verificationStatus: 'verified',
        supportedCallTypes: ['voice_call'],
        pricingType: 'free',
        marketPrice: null,
        manualPaymentPrice: ManualPaymentPriceDto(
          amountMinor: 10000,
          currencyCode: 'EGP',
        ),
        specializations: [],
        languages: ['ar'],
        averageRating: 0,
        totalReviews: 0,
        totalSessionsCompleted: 0,
      );

      final entity = dto.toDomain();

      check(entity.manualPaymentPrice).isNotNull();
      check(entity.manualPaymentPrice!.amountMinor).equals(10000);
      check(entity.manualPaymentPrice!.currencyCode).equals('EGP');
      check(entity.manualPaymentPrice!.amountMajor).equals(100);
      check(entity.hasManualPaymentPrice).isTrue();
      check(entity.pricingType).equals(SessionPricingType.free);
      check(entity.price).isNull();
    });

    test('maps free teacher with no market price', () {
      const dto = QuranTeacherDto(
        id: 't',
        displayName: 'X',
        bio: '',
        avatarUrl: '',
        gender: 'male',
        verificationStatus: 'unknown_status',
        supportedCallTypes: [],
        pricingType: 'free',
        marketPrice: null,
        specializations: [],
        languages: [],
        averageRating: 0,
        totalReviews: 0,
        totalSessionsCompleted: 0,
      );

      final entity = dto.toDomain();

      check(
        entity.verificationStatus,
      ).equals(TeacherVerificationStatus.pending);
      check(entity.pricingType).equals(SessionPricingType.free);
      check(entity.price).isNull();
    });
  });
}

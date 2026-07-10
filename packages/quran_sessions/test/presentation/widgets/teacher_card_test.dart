import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/widget_pump.dart';

void main() {
  group('TeacherCard', () {
    testWidgets('renders identity, rating and price in English LTR', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        TeacherCard(
          teacher: makeTeacher(avatarUrl: ''),
          onTap: () {},
        ),
        surfaceSize: const Size(360, 800),
      );

      expect(find.text('Sheikh Ahmed'), findsOneWidget);
      expect(find.textContaining('4.8'), findsOneWidget);
      expect(find.textContaining('(42)'), findsOneWidget);
      expect(find.byType(TilawaButton), findsNothing);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });

    testWidgets('renders identity without inline actions in Arabic RTL', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        TeacherCard(
          teacher: makeTeacher(avatarUrl: '', displayName: 'الشيخ أحمد'),
          onTap: () {},
        ),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        surfaceSize: const Size(360, 800),
      );

      expect(find.text('الشيخ أحمد'), findsOneWidget);
      expect(find.text('احجز'), findsNothing);
      expect(find.text('عرض الملف'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows New / جديد when teacher has no reviews', (tester) async {
      await pumpInApp(
        tester,
        TeacherCard(
          teacher: makeTeacher(
            avatarUrl: '',
            rating: 0,
          ).copyWithReviews(totalReviews: 0),
          onTap: () {},
        ),
        surfaceSize: const Size(360, 800),
      );
      expect(find.text('New'), findsOneWidget);
      expect(find.textContaining('0.0'), findsNothing);
    });

    testWidgets('shows جديد for new teacher in Arabic', (tester) async {
      await pumpInApp(
        tester,
        TeacherCard(
          teacher: makeTeacher(
            avatarUrl: '',
            rating: 0,
          ).copyWithReviews(totalReviews: 0),
          onTap: () {},
        ),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        surfaceSize: const Size(360, 800),
      );
      expect(find.text('جديد'), findsOneWidget);
    });

    testWidgets('shows مجاني only with a resolved free market quote', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        TeacherCard(
          teacher: makeTeacher(
            avatarUrl: '',
            pricingType: SessionPricingType.free,
            price: null,
          ),
          onTap: () {},
          pricing: const SessionPricingQuote(
            pricingType: SessionPricingType.free,
            amount: 0,
            currencyCode: 'USD',
            paymentRequired: false,
            paymentProviderAvailable: false,
            bookingEnabled: true,
            quranSessionsEnabled: true,
            effectivePricingSource: EffectivePricingSource.teacherOverride,
            blockReason: BookingBlockReason.none,
          ),
        ),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        surfaceSize: const Size(360, 800),
      );
      expect(find.text('مجاني'), findsOneWidget);
    });

    testWidgets('never shows مجاني when pricing is unresolved', (tester) async {
      await pumpInApp(
        tester,
        TeacherCard(
          // Entity claims free (legacy DTO default) but no market quote was
          // resolved — the badge must hide, not promise a free session the
          // booking flow would price as paid.
          teacher: makeTeacher(
            avatarUrl: '',
            pricingType: SessionPricingType.free,
            price: null,
          ),
          onTap: () {},
        ),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        surfaceSize: const Size(360, 800),
      );
      expect(find.text('مجاني'), findsNothing);
    });

    testWidgets(
      'shows EGP manual price and never Free when manualPaymentPrice is set',
      (tester) async {
        await pumpInApp(
          tester,
          TeacherCard(
            teacher: makeTeacher(
              avatarUrl: '',
              pricingType: SessionPricingType.free,
              price: null,
              manualPaymentPrice: const ManualPaymentPrice(
                amountMinor: 10000,
                currencyCode: 'EGP',
              ),
            ),
            onTap: () {},
          ),
          locale: const Locale('ar'),
          textDirection: TextDirection.rtl,
          surfaceSize: const Size(360, 800),
        );

        expect(find.textContaining('ج.م.'), findsOneWidget);
        expect(find.textContaining('100'), findsOneWidget);
        expect(find.text('مجاني'), findsNothing);
      },
    );

    testWidgets('shows one primary specialization chip only', (tester) async {
      await pumpInApp(
        tester,
        TeacherCard(
          teacher: makeTeacher(
            avatarUrl: '',
            specializations: const ['tajweed', 'recitation', 'hifz'],
          ),
          onTap: () {},
        ),
        surfaceSize: const Size(360, 800),
      );
      expect(find.byType(TilawaMetadataChip), findsOneWidget);
    });

    testWidgets('English name stays near avatar in Arabic RTL layout', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        TeacherCard(
          teacher: makeTeacher(avatarUrl: '', displayName: 'Mohammad Kamel'),
          onTap: () {},
        ),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        surfaceSize: const Size(360, 800),
      );

      final avatarBox = tester.getRect(find.byType(CircleAvatar).first);
      final nameBox = tester.getRect(find.text('Mohammad Kamel'));

      expect(avatarBox.left - nameBox.right, lessThan(24));
      expect(tester.takeException(), isNull);
    });

    testWidgets('long Arabic name ellipsizes without overflow', (tester) async {
      await pumpInApp(
        tester,
        TeacherCard(
          teacher: makeTeacher(
            avatarUrl: '',
            displayName: 'الشيخ محمد بن عبد الله كامل الهاشمي الطويل جدًا جدًا',
          ),
          onTap: () {},
        ),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        surfaceSize: const Size(360, 800),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('long English / mixed name ellipsizes without overflow', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        TeacherCard(
          teacher: makeTeacher(
            avatarUrl: '',
            displayName:
                'Sheikh Muhammad عبد الله Abdul-Rahman Al-Hashimi Long',
          ),
          onTap: () {},
        ),
        surfaceSize: const Size(360, 800),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows verified badge for verified teachers', (tester) async {
      await pumpInApp(
        tester,
        TeacherCard(
          teacher: makeTeacher(avatarUrl: ''),
          onTap: () {},
        ),
        surfaceSize: const Size(360, 800),
      );

      expect(find.byType(TilawaVerifiedTeacherBadge), findsOneWidget);
      expect(find.text('Verified Teacher'), findsOneWidget);
    });

    testWidgets('shows session count when teacher has completed sessions', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        TeacherCard(
          teacher: makeTeacher(avatarUrl: ''),
          onTap: () {},
        ),
        surfaceSize: const Size(360, 800),
      );

      expect(find.textContaining('120'), findsOneWidget);
    });

    testWidgets('tapping the card opens the teacher profile', (tester) async {
      var cardTaps = 0;
      await pumpInApp(
        tester,
        TeacherCard(
          teacher: makeTeacher(avatarUrl: ''),
          onTap: () => cardTaps++,
        ),
        surfaceSize: const Size(360, 800),
      );

      await tester.tap(find.text('Sheikh Ahmed'));
      await tester.pump();
      expect(cardTaps, 1);
    });

    testWidgets('three cards fit 360x800 without overflow', (tester) async {
      await pumpInApp(
        tester,
        ListView(
          children: [
            for (var i = 0; i < 3; i++)
              TeacherCard(
                teacher: makeTeacher(id: 'teacher_$i', avatarUrl: ''),
                availabilitySummary: const TeacherAvailabilitySummary(
                  teacherId: 'teacher_x',
                  status: TeacherAvailabilityStatus.availableToday,
                ),
                onTap: () {},
              ),
          ],
        ),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        surfaceSize: const Size(360, 800),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('availability hint survives text scale 1.3', (tester) async {
      await pumpInApp(
        tester,
        TeacherCard(
          teacher: makeTeacher(avatarUrl: '', displayName: 'Sheikh Ahmed'),
          onTap: () {},
        ),
        textScaleFactor: 1.3,
        surfaceSize: const Size(360, 800),
      );

      expect(find.byType(TilawaButton), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('availability hint survives text scale 1.4 in Arabic', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        TeacherCard(
          teacher: makeTeacher(
            avatarUrl: '',
            displayName: 'الشيخ محمد بن عبد الله كامل الهاشمي الطويل',
          ),
          availabilitySummary: const TeacherAvailabilitySummary(
            teacherId: 'teacher_1',
            status: TeacherAvailabilityStatus.noSlots,
          ),
          onTap: () {},
        ),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        textScaleFactor: 1.4,
        surfaceSize: const Size(360, 800),
      );

      expect(find.text('لا توجد مواعيد'), findsOneWidget);
      expect(find.text('احجز'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

extension on QuranTeacher {
  QuranTeacher copyWithReviews({required int totalReviews}) {
    return QuranTeacher(
      id: id,
      displayName: displayName,
      bio: bio,
      avatarUrl: avatarUrl,
      gender: gender,
      verificationStatus: verificationStatus,
      supportedCallTypes: supportedCallTypes,
      pricingType: pricingType,
      price: price,
      specializations: specializations,
      languages: languages,
      averageRating: averageRating,
      totalReviews: totalReviews,
      totalSessionsCompleted: totalSessionsCompleted,
      cityName: cityName,
      countryName: countryName,
    );
  }
}

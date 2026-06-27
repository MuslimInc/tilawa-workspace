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
      expect(find.text('Book'), findsOneWidget);
      expect(find.text('View profile'), findsOneWidget);
    });

    testWidgets('renders identity and actions in Arabic RTL', (tester) async {
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
      expect(find.text('احجز'), findsOneWidget);
      expect(find.text('عرض الملف'), findsOneWidget);
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

    testWidgets('shows Free / مجاني for free teachers', (tester) async {
      await pumpInApp(
        tester,
        TeacherCard(
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
      expect(find.text('مجاني'), findsOneWidget);
    });

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
      expect(find.byType(QuranSessionsMetadataChip), findsOneWidget);
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

    testWidgets('primary book button is compact, not full-width', (
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

      final cardWidth = tester
          .getSize(find.byType(QuranSessionsSurfaceCard))
          .width;
      final bookWidth = tester
          .getSize(find.widgetWithText(TilawaButton, 'Book'))
          .width;

      expect(bookWidth, lessThan(cardWidth * 0.6));
    });

    testWidgets('book and view-profile sit in one shared action row', (
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

      final bookCenter = tester.getCenter(
        find.widgetWithText(TilawaButton, 'Book'),
      );
      final viewCenter = tester.getCenter(
        find.widgetWithText(TilawaButton, 'View profile'),
      );

      expect((bookCenter.dy - viewCenter.dy).abs(), lessThan(1.0));
    });

    testWidgets('tapping the card surface opens the profile', (tester) async {
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

    testWidgets('book tap starts booking once and does not navigate twice', (
      tester,
    ) async {
      var cardTaps = 0;
      var bookTaps = 0;
      await pumpInApp(
        tester,
        TeacherCard(
          teacher: makeTeacher(avatarUrl: ''),
          onTap: () => cardTaps++,
          onBook: () => bookTaps++,
          onViewProfile: () {},
        ),
        surfaceSize: const Size(360, 800),
      );

      await tester.tap(find.text('Book'));
      await tester.pump();

      expect(bookTaps, 1);
      expect(cardTaps, 0);
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

    testWidgets('availability hint and actions survive text scale 1.4', (
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
      expect(find.text('احجز'), findsOneWidget);
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
    );
  }
}

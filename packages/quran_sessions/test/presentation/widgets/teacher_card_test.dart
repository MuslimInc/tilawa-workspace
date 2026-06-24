import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/widget_pump.dart';

void main() {
  group('TeacherCard', () {
    testWidgets('renders name, rating and review count', (tester) async {
      await pumpInApp(
        tester,
        TeacherCard(
          teacher: makeTeacher(avatarUrl: ''),
          onTap: () {},
        ),
        surfaceSize: const Size(420, 240),
      );

      expect(find.text('Sheikh Ahmed'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('(42)'), findsOneWidget);
    });

    testWidgets('shows a price chip with the amount for fixed pricing', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        TeacherCard(
          teacher: makeTeacher(avatarUrl: ''),
          onTap: () {},
        ),
        surfaceSize: const Size(420, 240),
      );

      expect(find.byType(TilawaStatusChip), findsOneWidget);
      expect(find.textContaining('500'), findsOneWidget);
    });

    testWidgets('shows a price chip for free teachers', (tester) async {
      await pumpInApp(
        tester,
        TeacherCard(
          teacher: makeTeacher(
            avatarUrl: '',
            pricingType: SessionPricingType.free,
          ),
          onTap: () {},
        ),
        surfaceSize: const Size(420, 240),
      );

      expect(find.byType(TilawaStatusChip), findsOneWidget);
    });

    testWidgets('hides the price chip when fixed pricing has no price', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        TeacherCard(
          teacher: makeTeacher(avatarUrl: '', price: null),
          onTap: () {},
        ),
        surfaceSize: const Size(420, 240),
      );

      expect(find.byType(TilawaStatusChip), findsNothing);
    });

    testWidgets('renders at most three specialization chips', (tester) async {
      await pumpInApp(
        tester,
        TeacherCard(
          teacher: makeTeacher(
            avatarUrl: '',
            specializations: const ['tajweed', 'recitation', 'hifz', 'review'],
          ),
          onTap: () {},
        ),
        surfaceSize: const Size(420, 260),
      );

      expect(find.byType(TilawaMetadataChip), findsNWidgets(3));
    });

    testWidgets('hides specialization chips when none provided', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        TeacherCard(
          teacher: makeTeacher(avatarUrl: '', specializations: const []),
          onTap: () {},
        ),
        surfaceSize: const Size(420, 240),
      );

      expect(find.byType(TilawaMetadataChip), findsNothing);
    });

    testWidgets('tapping the card invokes onTap', (tester) async {
      var taps = 0;
      await pumpInApp(
        tester,
        TeacherCard(
          teacher: makeTeacher(avatarUrl: ''),
          onTap: () => taps++,
        ),
        surfaceSize: const Size(420, 240),
      );

      await tester.tap(find.byType(TilawaCard));
      await tester.pump();
      expect(taps, 1);
    });
  });
}

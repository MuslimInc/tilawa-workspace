import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations_ar.dart';
import 'package:quran_sessions/src/presentation/widgets/teacher_dashboard_loading_skeleton.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/widget_pump.dart';

void main() {
  testWidgets(
    'mirrors loaded dashboard chrome with card surfaces during loading',
    (tester) async {
      final l10n = QuranSessionsLocalizationsAr();

      await pumpInApp(
        tester,
        const TeacherDashboardLoadingSkeleton(),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        textScaleFactor: 1.4,
        settle: false,
        surfaceSize: const Size(411, 891),
      );

      expect(find.byType(TilawaSkeleton), findsOneWidget);
      expect(find.text(l10n.teacherDashboardCategoriesTitle), findsOneWidget);
      expect(
        find.text(l10n.teacherDashboardCategoriesSubtitle),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(l10n.teacherDashboardLoadingLabel),
        findsOneWidget,
      );
      expect(find.byType(TilawaContentGrid), findsOneWidget);

      // Summary stats render as a TilawaMetricTileStrip (not cards) since the
      // metric-tile redesign; card surfaces remain for the category grid.
      expect(find.byType(TilawaMetricTileStrip), findsOneWidget);
      check(find.byType(TilawaCard).evaluate().length >= 4).isTrue();
      check(find.byType(TilawaSkeletonLine).evaluate().length >= 15).isTrue();
    },
  );

  testWidgets('keeps full-card gray slabs out of the loading layout', (
    tester,
  ) async {
    await pumpInApp(
      tester,
      const TeacherDashboardLoadingSkeleton(),
      settle: false,
      surfaceSize: const Size(411, 891),
    );

    final slabHeights = tester
        .widgetList<TilawaSkeletonBone>(find.byType(TilawaSkeletonBone))
        .where(
          (bone) =>
              bone.width == null && (bone.height == 96 || bone.height == 88),
        )
        .map((bone) => bone.height)
        .toList();

    check(slabHeights).isEmpty();
  });
}

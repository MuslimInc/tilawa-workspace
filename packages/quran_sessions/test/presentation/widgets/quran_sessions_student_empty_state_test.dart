import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/presentation/config/quran_sessions_feature_config.dart';
import 'package:quran_sessions/src/presentation/widgets/quran_sessions_student_empty_state.dart';

import '../../helpers/widget_pump.dart';

const _entryEnabledConfig = QuranSessionsFeatureConfig(
  learnQuranStudentFeatureEnabled: true,
  teacherApplicationEnabled: true,
  teacherApplicationDiscoverability:
      TeacherApplicationDiscoverability.profileAndEmptyState,
);

void main() {
  group('QuranSessionsStudentEmptyState', () {
    testWidgets('renders title, subtitle and notify CTA', (tester) async {
      await pumpInApp(
        tester,
        const QuranSessionsStudentEmptyState(
          featureConfig: QuranSessionsFeatureConfig(),
        ),
      );

      expect(find.text('No teachers in your area yet'), findsOneWidget);
      expect(find.text('Notify me when available'), findsOneWidget);
    });

    testWidgets('shows change-city action only when callback provided', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        const QuranSessionsStudentEmptyState(
          featureConfig: QuranSessionsFeatureConfig(),
        ),
      );
      expect(find.text('Change city'), findsNothing);

      await pumpInApp(
        tester,
        QuranSessionsStudentEmptyState(
          featureConfig: const QuranSessionsFeatureConfig(),
          onChangeCity: () {},
        ),
      );
      expect(find.text('Change city'), findsOneWidget);
    });

    testWidgets('notify and change-city taps invoke callbacks', (tester) async {
      var notify = 0;
      var changeCity = 0;
      await pumpInApp(
        tester,
        QuranSessionsStudentEmptyState(
          featureConfig: const QuranSessionsFeatureConfig(),
          onNotifyInterest: () => notify++,
          onChangeCity: () => changeCity++,
        ),
      );

      await tester.tap(find.text('Notify me when available'));
      await tester.pump();
      expect(notify, 1);

      await tester.tap(find.text('Change city'));
      await tester.pump();
      expect(changeCity, 1);
    });

    testWidgets('teacher-apply link shown and tappable when fully enabled', (
      tester,
    ) async {
      var applyTaps = 0;
      await pumpInApp(
        tester,
        QuranSessionsStudentEmptyState(
          featureConfig: _entryEnabledConfig,
          showTeacherApplyEntry: true,
          onTeacherApplyEntry: () => applyTaps++,
        ),
      );

      expect(find.text('Interested in teaching Quran?'), findsOneWidget);
      expect(find.text('Join as a teacher'), findsOneWidget);

      await tester.tap(find.text('Join as a teacher'));
      await tester.pump();
      expect(applyTaps, 1);
    });

    testWidgets('teacher-apply link hidden when feature config disables it', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        QuranSessionsStudentEmptyState(
          featureConfig: const QuranSessionsFeatureConfig(),
          showTeacherApplyEntry: true,
          onTeacherApplyEntry: () {},
        ),
      );

      expect(find.text('Join as a teacher'), findsNothing);
    });

    testWidgets('onEmptyStateSeen fires once after first frame', (
      tester,
    ) async {
      var seen = 0;
      await pumpInApp(
        tester,
        QuranSessionsStudentEmptyState(
          featureConfig: const QuranSessionsFeatureConfig(),
          onEmptyStateSeen: () => seen++,
        ),
      );

      expect(seen, 1);
    });
  });
}

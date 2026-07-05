import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:quran_sessions/src/presentation/layout/quran_sessions_scroll_padding.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/fixtures.dart';
import 'my_sessions_empty_bloc.dart';
import 'my_sessions_layout_bloc.dart';

Future<void> _pumpMySessions(
  WidgetTester tester,
  MySessionsSuccess seed, {
  double textScaleFactor = 1.0,
  void Function({
    required String bookingId,
    required String teacherId,
    required String studentId,
  })?
  onRescheduleRequested,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
      localizationsDelegates: QuranSessionsLocalizations.localizationsDelegates,
      supportedLocales: QuranSessionsLocalizations.supportedLocales,
      home: BlocProvider<MySessionsBloc>.value(
        value: MySessionsLayoutBloc(seed: seed),
        child: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(textScaleFactor),
          ),
          child: MySessionsScreen(
            studentId: 'student_1',
            onRescheduleRequested: onRescheduleRequested,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows summary strip and segmented tabs with upcoming cards', (
    tester,
  ) async {
    final start = DateTime.now().add(const Duration(hours: 3));
    await _pumpMySessions(
      tester,
      MySessionsSuccess(
        upcoming: [
          makeSession(
            id: 'up_1',
            startsAt: start,
            endsAt: start.add(const Duration(hours: 1)),
          ),
          makeSession(
            id: 'up_2',
            startsAt: start.add(const Duration(hours: 5)),
            endsAt: start.add(const Duration(hours: 6)),
          ),
        ],
        past: const [],
      ),
    );

    expect(find.byType(QuranSessionSummaryStrip), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.byType(QuranSessionCard), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('past tab does not show heavy join buttons', (tester) async {
    await _pumpMySessions(
      tester,
      MySessionsSuccess(
        upcoming: const [],
        past: [
          makeSession(id: 'past_1', status: QuranSessionStatus.completed),
        ],
      ),
    );

    await tester.tap(find.text('Past'));
    await tester.pumpAndSettle();

    expect(find.text('Join now'), findsNothing);
    expect(find.text('Join'), findsNothing);
  });

  testWidgets('empty sessions state is shown when bloc is empty', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates:
            QuranSessionsLocalizations.localizationsDelegates,
        supportedLocales: QuranSessionsLocalizations.supportedLocales,
        home: BlocProvider<MySessionsBloc>.value(
          value: MySessionsEmptyBloc(),
          child: const MySessionsScreen(studentId: 'student_1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No sessions yet'), findsOneWidget);
  });

  testWidgets('upcoming sessions stay compact at text scale 1.4 on 360x800', (
    tester,
  ) async {
    final start = DateTime.now().add(const Duration(minutes: 20));
    await _pumpMySessions(
      tester,
      MySessionsSuccess(
        upcoming: [
          makeSession(
            id: 'up_scaled',
            startsAt: start,
            endsAt: start.add(const Duration(hours: 1)),
          ),
        ],
        past: const [],
      ),
      textScaleFactor: 1.4,
    );

    expect(find.byType(QuranSessionSummaryStrip), findsOneWidget);
    expect(find.byType(QuranSessionCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reschedule appears only outside the 24 hour window', (
    tester,
  ) async {
    final soon = DateTime.now().add(const Duration(hours: 3));
    final later = DateTime.now().add(const Duration(days: 2));

    await _pumpMySessions(
      tester,
      MySessionsSuccess(
        upcoming: [
          makeSession(id: 'soon', startsAt: soon),
          makeSession(id: 'later', startsAt: later),
        ],
        past: const [],
      ),
      onRescheduleRequested:
          ({
            required bookingId,
            required teacherId,
            required studentId,
          }) {},
    );

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    expect(find.text('Reschedule'), findsNothing);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert).last);
    await tester.pumpAndSettle();

    expect(find.text('Reschedule'), findsOneWidget);
  });

  testWidgets('list reserves comfortable scroll bottom padding', (
    tester,
  ) async {
    final start = DateTime.now().add(const Duration(hours: 3));
    await _pumpMySessions(
      tester,
      MySessionsSuccess(
        upcoming: [
          makeSession(
            id: 'up_bottom_pad',
            startsAt: start,
            endsAt: start.add(const Duration(hours: 1)),
          ),
        ],
        past: const [],
      ),
    );

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
    await tester.pumpAndSettle();

    final cardBottom = tester.getBottomLeft(find.byType(QuranSessionCard));
    final expectedPadding = quranSessionsDefaultScrollBottomPadding(
      tester.element(find.byType(CustomScrollView)),
    );

    expect(800 - cardBottom.dy, greaterThanOrEqualTo(expectedPadding - 1));
  });

  testWidgets('upcoming actions align to the trailing edge', (tester) async {
    final start = DateTime.now().add(const Duration(hours: 3));
    await _pumpMySessions(
      tester,
      MySessionsSuccess(
        upcoming: [
          makeSession(
            id: 'up_actions',
            startsAt: start,
            endsAt: start.add(const Duration(hours: 1)),
          ),
        ],
        past: const [],
      ),
    );

    final cardRect = tester.getRect(find.byType(QuranSessionCard));
    final menuRect = tester.getRect(find.byIcon(Icons.more_vert));

    expect(menuRect.center.dx, greaterThan(cardRect.center.dx));
  });
}

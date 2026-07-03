import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_availability_provider.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/lifecycle_test_helpers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  testWidgets('shows offline state when dashboard load fails offline', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final scheduleRepo = FakeScheduleRepository()
      ..schedule = makeWeeklySchedule();
    final bloc = buildTestTeacherDashboardBloc(
      sessionRepo: FakeSessionRepository(),
      getAvailability: buildGetTeacherAvailabilityUseCase(
        scheduleRepository: scheduleRepo,
      ),
      blockGeneratedSlot: BlockGeneratedSlotUseCase(scheduleRepo),
      availabilityProvider: FakeAvailabilityProvider(),
      cancelSession: buildCancelSessionViaServerUseCase(),
      completeSession: buildCompleteSessionViaServerUseCase(),
      scheduleRepo: scheduleRepo,
      isConnected: () async => false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        locale: const Locale('ar'),
        localizationsDelegates: const [
          ...QuranSessionsLocalizations.localizationsDelegates,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: QuranSessionsLocalizations.supportedLocales,
        home: BlocProvider<TeacherDashboardBloc>.value(
          value: bloc,
          child: const TeacherDashboardScreen(teacherId: 'teacher_1'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.wifi_off_outlined), findsOneWidget);
    expect(find.text('يلزم اتصال بالإنترنت.'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

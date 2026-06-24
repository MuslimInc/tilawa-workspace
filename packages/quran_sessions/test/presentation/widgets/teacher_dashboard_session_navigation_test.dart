import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_availability_provider.dart';
import '../../helpers/fakes/fake_booked_slot_lock_repository.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fakes/fake_user_profile_repository.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/lifecycle_test_helpers.dart';

void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await initializeDateFormatting('en');
  });

  testWidgets('teacher dashboard upcoming session opens detail', (
    tester,
  ) async {
    String? openedBookingId;
    final sessionRepo = FakeSessionRepository()
      ..sessions = [
        makeSession(startsAt: DateTime.now().add(const Duration(days: 1))),
      ];
    final scheduleRepo = FakeScheduleRepository();
    final bloc = buildTestTeacherDashboardBloc(
      sessionRepo: sessionRepo,
      getAvailability: SpyGetTeacherAvailabilityUseCase(
        scheduleRepository: scheduleRepo,
        bookedSlotLocks: FakeBookedSlotLockRepository(),
      ),
      blockGeneratedSlot: BlockGeneratedSlotUseCase(scheduleRepo),
      availabilityProvider: FakeAvailabilityProvider(),
      cancelSession: buildCancelSessionViaServerUseCase(),
      completeSession: buildCompleteSessionViaServerUseCase(),
      scheduleRepo: scheduleRepo,
      userProfileRepo: FakeUserProfileRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        locale: const Locale('en'),
        localizationsDelegates: const [
          ...QuranSessionsLocalizations.localizationsDelegates,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: QuranSessionsLocalizations.supportedLocales,
        home: TilawaFeedbackHost(
          child: BlocProvider<TeacherDashboardBloc>(
            create: (_) => bloc,
            child: TeacherDashboardScreen(
              teacherId: 'teacher_1',
              onSessionDetailRequested: (bookingId) {
                openedBookingId = bookingId;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SessionCard));
    await tester.pumpAndSettle();

    check(openedBookingId).equals('booking_1');
  });
}

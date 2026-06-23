import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_market_config_repository.dart';
import '../../helpers/fakes/fake_session_policy_repository.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fakes/fake_teacher_repository.dart';
import '../../helpers/fakes/fake_user_profile_repository.dart';
import '../../helpers/lifecycle_test_helpers.dart';

class _SeededBookingBloc extends BookingBloc {
  _SeededBookingBloc({required BookingSelecting seed})
    : super(
        getAvailability: buildGetTeacherAvailabilityUseCase(
          scheduleRepository: FakeScheduleRepository(),
          sessionRepository: FakeSessionRepository(),
        ),
        submitBooking: buildSubmitSessionBookingUseCase(
          getAvailability: buildGetTeacherAvailabilityUseCase(
            scheduleRepository: FakeScheduleRepository(),
            sessionRepository: FakeSessionRepository(),
          ),
        ),
        validateEligibility: ValidateBookingEligibilityUseCase(
          profileRepository: FakeUserProfileRepository(),
          policyRepository: FakeSessionPolicyRepository(),
          teacherRepository: FakeTeacherRepository(),
          marketConfigRepository: FakeMarketConfigRepository(),
        ),
      ) {
    emit(seed);
  }

  @override
  void add(BookingEvent event) {}
}

TeacherAvailability _slot(int day) {
  final start = DateTime.utc(2026, 7, day, 10);
  return TeacherAvailability(
    slotId: 'slot_$day',
    teacherId: 'teacher_1',
    startsAt: start,
    endsAt: start.add(const Duration(hours: 1)),
    isBooked: false,
  );
}

void main() {
  testWidgets('booking confirm stays visible with many slots', (tester) async {
    tester.view.physicalSize = const Size(390, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final slots = List.generate(20, (index) => _slot(index + 1));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: const [
          QuranSessionsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: QuranSessionsLocalizations.supportedLocales,
        home: BlocProvider<BookingBloc>(
          create: (_) => _SeededBookingBloc(
            seed: BookingSelecting(
              teacherId: 'teacher_1',
              availableSlots: slots,
              selectedSlot: slots.first,
              selectedCallType: SessionCallType.externalMeeting,
            ),
          ),
          child: const BookingScreen(
            teacherId: 'teacher_1',
            studentId: 'student_1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TilawaBottomActionArea), findsOneWidget);
    expect(find.text('Confirm booking'), findsOneWidget);
    expect(find.text('Choose a time'), findsOneWidget);
    expect(find.text('Session type'), findsOneWidget);
  });
}

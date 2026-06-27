import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/fakes/fake_booking_repository.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fakes/fake_teacher_profile_repository.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/lifecycle_test_helpers.dart';

class _JoinNavigationTestBloc extends MySessionsBloc {
  _JoinNavigationTestBloc({required MySessionsSuccess seed})
    : super(
        getStudentSessions: GetStudentSessionsUseCase(FakeSessionRepository()),
        cancelSession: buildCancelSessionViaServerUseCase(),
        submitReview: SubmitReviewUseCase(FakeBookingRepository()),
        joinSession: JoinSessionUseCase(
          sessionRepository: FakeSessionRepository(),
          callProvider: const MockSessionCallProvider(),
          authSession: _FakeAuthSession('student_1'),
          teacherProfileRepository: FakeTeacherProfileRepository(),
        ),
        studentId: 'student_1',
      ) {
    emit(seed);
  }

  @override
  void add(MySessionsEvent event) {
    if (event is MySessionsLoadRequested) {
      return;
    }
    if (event is SessionJoinRequested) {
      final current = state;
      if (current is! MySessionsSuccess) {
        return;
      }
      emit(
        current.copyWith(
          clearJoinInProgress: true,
          joinCompletedSessionId: event.sessionId,
        ),
      );
      return;
    }
    super.add(event);
  }
}

class _FakeAuthSession implements AuthSessionProvider {
  const _FakeAuthSession(this.userId);

  final String userId;

  @override
  String? get currentUserId => userId;

  @override
  Stream<String?> watchUserId() => Stream.value(userId);
}

QuranSession _inAppSession({
  SessionCallProviderKind providerKind = SessionCallProviderKind.mock,
}) {
  final start = DateTime.now().add(const Duration(minutes: 5));
  return QuranSession(
    id: 'session_join',
    bookingId: 'booking_1',
    teacherId: 'teacher_1',
    studentId: 'student_1',
    startsAt: start,
    endsAt: start.add(const Duration(hours: 1)),
    callType: SessionCallType.voiceCall,
    status: QuranSessionStatus.scheduled,
    callProviderKind: providerKind,
  );
}

Future<void> _pumpMySessionsScreen(
  WidgetTester tester, {
  required MySessionsBloc bloc,
}) async {
  tester.view.physicalSize = const Size(390, 640);
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
      builder: (context, child) => TilawaFeedbackHost(child: child!),
      home: BlocProvider<MySessionsBloc>.value(
        value: bloc,
        child: MySessionsScreen(
          studentId: 'student_1',
          createCallControlGateway: (_) => _NoOpCallControlGateway(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('in-app join from list opens call shell', (tester) async {
    final bloc = _JoinNavigationTestBloc(
      seed: MySessionsSuccess(
        upcoming: [_inAppSession(providerKind: SessionCallProviderKind.mock)],
        past: const [],
      ),
    );

    await _pumpMySessionsScreen(tester, bloc: bloc);

    await tester.tap(find.text('Join now'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('call_shell_end')), findsOneWidget);
  });

  testWidgets('external join shows pre-join sheet before dispatching join', (
    tester,
  ) async {
    final bloc = _JoinNavigationTestBloc(
      seed: MySessionsSuccess(
        upcoming: [
          makeSession(
            id: 'session_join',
            studentId: 'student_1',
            startsAt: DateTime.now().add(const Duration(minutes: 5)),
          ),
        ],
        past: const [],
      ),
    );

    await _pumpMySessionsScreen(tester, bloc: bloc);

    await tester.tap(find.text('Join now'));
    await tester.pumpAndSettle();

    expect(find.text('Join outside MeMuslim?'), findsOneWidget);
    expect(find.text('Leave call'), findsNothing);
  });
}

class _NoOpCallControlGateway implements SessionCallControlGateway {
  @override
  Future<void> leave() async {}

  @override
  Future<void> setCameraEnabled({required bool enabled}) async {}

  @override
  Future<void> setMicrophoneEnabled({required bool enabled}) async {}

  @override
  Future<void> setSpeakerEnabled({required bool enabled}) async {}

  @override
  Future<void> switchCamera() async {}
}

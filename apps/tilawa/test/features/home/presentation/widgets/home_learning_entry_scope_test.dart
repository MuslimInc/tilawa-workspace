import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/features/quran_sessions/domain/entities/quran_sessions_platform_config.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_platform_config_store.dart';
import 'package:tilawa/features/home/presentation/cubit/home_learning_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_learning_state.dart';
import 'package:tilawa/features/home/presentation/widgets/home_learning_entry.dart';
import 'package:tilawa/features/home/presentation/widgets/home_learning_cards.dart';
import 'package:tilawa/features/settings/presentation/cubit/teacher_capability_cubit.dart';
import 'package:tilawa/features/settings/domain/services/teacher_capability_refresh_notifier.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'home_learning_entry_scope_test.mocks.dart';

class FakeGetCurrentUserTeacherCapabilityUseCase extends Mock
    implements GetCurrentUserTeacherCapabilityUseCase {
  @override
  Future<Either<QuranSessionsFailure, TeacherCapability>> call(
    String userId,
  ) async {
    return const Right(TeacherCapability(state: TeacherCapabilityState.none));
  }
}

class FakeAuthSessionProvider implements AuthSessionProvider {
  @override
  String? get currentUserId => 'student_1';

  @override
  Stream<String?> watchUserId() => Stream.value('student_1');
}

@GenerateMocks([HomeLearningCubit, TeacherCapabilityCubit])
void main() {
  late MockHomeLearningCubit mockHomeLearningCubit;
  late MockTeacherCapabilityCubit mockTeacherCapabilityCubit;

  setUpAll(() {
    // VisibilityDetector synchronous mode
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  setUp(() {
    mockHomeLearningCubit = MockHomeLearningCubit();
    mockTeacherCapabilityCubit = MockTeacherCapabilityCubit();

    // Register GetIt dependencies
    if (getIt.isRegistered<QuranSessionsPlatformConfigStore>()) {
      getIt.unregister<QuranSessionsPlatformConfigStore>();
    }
    getIt.registerSingleton<QuranSessionsPlatformConfigStore>(
      QuranSessionsPlatformConfigStore()..setConfig(
        const QuranSessionsPlatformConfig(
          quranSessionsEnabled: true,
          studentEntryEnabled: true,
          bookingEnabled: true,
          bookingMode: 'requiresTutorApproval',
          sessionMode: 'videoOnly',
          enabledCallProviders: {'mock'},
          teacherApplicationEnabled: false,
          teacherApplicationEntryEnabled: false,
          homeTeacherApplicationCardEnabled: false,
          teacherApplicationDiscoverability: 'none',
        ),
      ),
    );

    if (getIt.isRegistered<AppLaunchConfig>()) {
      getIt.unregister<AppLaunchConfig>();
    }
    getIt.registerSingleton<AppLaunchConfig>(const AppLaunchConfig());

    if (getIt.isRegistered<AuthSessionProvider>()) {
      getIt.unregister<AuthSessionProvider>();
    }
    getIt.registerSingleton<AuthSessionProvider>(FakeAuthSessionProvider());

    if (getIt.isRegistered<GetCurrentUserTeacherCapabilityUseCase>()) {
      getIt.unregister<GetCurrentUserTeacherCapabilityUseCase>();
    }
    getIt.registerSingleton<GetCurrentUserTeacherCapabilityUseCase>(
      FakeGetCurrentUserTeacherCapabilityUseCase(),
    );

    if (getIt.isRegistered<TeacherCapabilityRefreshNotifier>()) {
      getIt.unregister<TeacherCapabilityRefreshNotifier>();
    }
    getIt.registerSingleton<TeacherCapabilityRefreshNotifier>(
      TeacherCapabilityRefreshNotifier(),
    );

    if (getIt.isRegistered<HomeLearningCubit>()) {
      getIt.unregister<HomeLearningCubit>();
    }
    getIt.registerSingleton<HomeLearningCubit>(mockHomeLearningCubit);

    // Mock TeacherCapabilityCubit states
    when(mockTeacherCapabilityCubit.state).thenReturn(
      const SettingsTeacherCapabilityLoadState(
        isLoading: false,
        hasLoaded: true,
      ),
    );
    when(
      mockTeacherCapabilityCubit.stream,
    ).thenAnswer((_) => const Stream.empty());

    // Mock HomeLearningCubit stream
    when(mockHomeLearningCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  tearDown(() {
    if (getIt.isRegistered<HomeLearningCubit>()) {
      getIt.unregister<HomeLearningCubit>();
    }
    if (getIt.isRegistered<QuranSessionsPlatformConfigStore>()) {
      getIt.unregister<QuranSessionsPlatformConfigStore>();
    }
    if (getIt.isRegistered<AppLaunchConfig>()) {
      getIt.unregister<AppLaunchConfig>();
    }
    if (getIt.isRegistered<AuthSessionProvider>()) {
      getIt.unregister<AuthSessionProvider>();
    }
    if (getIt.isRegistered<GetCurrentUserTeacherCapabilityUseCase>()) {
      getIt.unregister<GetCurrentUserTeacherCapabilityUseCase>();
    }
    if (getIt.isRegistered<TeacherCapabilityRefreshNotifier>()) {
      getIt.unregister<TeacherCapabilityRefreshNotifier>();
    }
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      locale: const Locale('en'),
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        QuranSessionsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: CustomScrollView(
          slivers: [
            HomeLearningEntryScope(),
          ],
        ),
      ),
    );
  }

  testWidgets('renders nothing when state is loading', (tester) async {
    when(mockHomeLearningCubit.state).thenReturn(
      const HomeLearningState(status: HomeLearningStatus.loading),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(HomeLearningInterestCard), findsNothing);
  });

  testWidgets('renders browse entry when the user answered yes', (
    tester,
  ) async {
    when(mockHomeLearningCubit.state).thenReturn(
      const HomeLearningState(
        status: HomeLearningStatus.none,
        isBrowseEntryVisible: true,
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(HomeLearningBrowseCard), findsOneWidget);
    expect(find.byType(HomeLearningInterestCard), findsNothing);
  });

  testWidgets('renders nothing when the user answered not-now', (
    tester,
  ) async {
    when(mockHomeLearningCubit.state).thenReturn(
      const HomeLearningState(status: HomeLearningStatus.none),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(HomeLearningBrowseCard), findsNothing);
    expect(find.byType(HomeLearningInterestCard), findsNothing);
  });

  testWidgets('renders next session card when status is nextSession', (
    tester,
  ) async {
    final now = DateTime.now();
    final mockSession = QuranSession(
      id: 'session_next',
      bookingId: 'booking_1',
      studentId: 'student_1',
      teacherId: 'teacher_1',
      startsAt: now.add(const Duration(minutes: 30)),
      endsAt: now.add(const Duration(hours: 1)),
      callType: SessionCallType.videoCall,
      status: QuranSessionStatus.scheduled,
      lifecycleStatus: SessionLifecycleStatus.scheduled,
    );

    when(mockHomeLearningCubit.state).thenReturn(
      HomeLearningState(
        status: HomeLearningStatus.nextSession,
        session: mockSession,
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(HomeLearningNextSessionCard), findsOneWidget);
  });

  testWidgets('renders pending booking card when status is pendingBooking', (
    tester,
  ) async {
    final now = DateTime.now();
    final mockSession = QuranSession(
      id: 'session_pending',
      bookingId: 'booking_2',
      studentId: 'student_1',
      teacherId: 'teacher_1',
      startsAt: now.add(const Duration(days: 1)),
      endsAt: now.add(const Duration(days: 1, hours: 1)),
      callType: SessionCallType.videoCall,
      status: QuranSessionStatus.scheduled,
      lifecycleStatus: SessionLifecycleStatus.pendingPayment,
      paymentStatus: 'pending_payment',
    );

    when(mockHomeLearningCubit.state).thenReturn(
      HomeLearningState(
        status: HomeLearningStatus.pendingBooking,
        session: mockSession,
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(HomeLearningPendingBookingCard), findsOneWidget);
  });

  testWidgets('renders revision card when status is continueLearning', (
    tester,
  ) async {
    final now = DateTime.now();
    final mockAggregate = SessionAggregate(
      id: 'aggregate_revision',
      studentId: 'student_1',
      teacherId: 'teacher_1',
      slotId: 'slot_1',
      startsAt: now.subtract(const Duration(days: 2)),
      lifecycleStatus: SessionLifecycleStatus.completed,
      pricingType: SessionPricingType.free,
      createdAt: now,
      updatedAt: now,
      revisionSurahNumber: 18,
      revisionAyahNumber: 1,
    );

    when(mockHomeLearningCubit.state).thenReturn(
      HomeLearningState(
        status: HomeLearningStatus.continueLearning,
        revisionAggregate: mockAggregate,
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(HomeLearningRevisionCard), findsOneWidget);
  });
}

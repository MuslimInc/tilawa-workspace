import 'package:get_it/get_it.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../data/fake_auth_session_provider.dart';
import '../data/fake_mvp_availability_provider.dart';
import '../data/fake_mvp_booking_repository.dart';
import '../data/fake_mvp_market_config_repository.dart';
import '../data/fake_mvp_schedule_repository.dart';
import '../data/fake_mvp_session_policy_repository.dart';
import '../data/fake_mvp_session_repository.dart';
import '../data/fake_mvp_teacher_application_repository.dart';
import '../data/fake_mvp_teacher_profile_repository.dart';
import '../data/fake_mvp_teacher_repository.dart';
import '../data/fake_mvp_user_profile_repository.dart';
import '../data/quran_sessions_mvp_store.dart';

/// Wires fake MVP repositories, boundaries, use cases, and BLoC factories
/// into [GetIt]. Call once after [configureDependencies].
class QuranSessionsMvpModule {
  QuranSessionsMvpModule._();

  static void register(GetIt sl) {
    final store = QuranSessionsMvpStore.instance;

    sl.registerLazySingleton<TeacherRepository>(
      () => FakeMvpTeacherRepository(store),
    );
    sl.registerLazySingleton<AuthSessionProvider>(
      () => const FakeAuthSessionProvider(userId: 'student_mvp'),
    );
    sl.registerLazySingleton<BookingRepository>(
      () => FakeMvpBookingRepository(store, sl<AuthSessionProvider>()),
    );
    sl.registerLazySingleton<SessionRepository>(
      () => FakeMvpSessionRepository(store),
    );
    sl.registerLazySingleton<AvailabilityProvider>(
      () => FakeMvpAvailabilityProvider(store),
    );
    sl.registerLazySingleton<UserProfileRepository>(
      () => FakeMvpUserProfileRepository(store),
    );
    sl.registerLazySingleton<SessionPolicyRepository>(
      () => FakeMvpSessionPolicyRepository(store),
    );
    sl.registerLazySingleton<MarketConfigRepository>(
      () => FakeMvpMarketConfigRepository(),
    );
    sl.registerLazySingleton<TeacherApplicationRepository>(
      () => FakeMvpTeacherApplicationRepository(store),
    );
    sl.registerLazySingleton<TeacherProfileRepository>(
      () => FakeMvpTeacherProfileRepository(store),
    );
    sl.registerLazySingleton<ScheduleRepository>(
      () => FakeMvpScheduleRepository(store),
    );

    registerUseCases(sl);
    registerBlocs(sl);
  }

  /// Registers use cases assuming repositories are already in [sl].
  static void registerUseCases(GetIt sl) {
    sl.registerLazySingleton(
      () => GetTeachersUseCase(sl<TeacherRepository>()),
    );
    sl.registerLazySingleton(
      () => GetTeacherProfileUseCase(sl<TeacherRepository>()),
    );
    sl.registerLazySingleton(
      () => GetTeacherAvailabilityUseCase(sl<TeacherRepository>()),
    );
    sl.registerLazySingleton(
      () => GetStudentSessionsUseCase(sl<SessionRepository>()),
    );
    sl.registerLazySingleton(
      () => GetTeacherSessionsUseCase(sl<SessionRepository>()),
    );
    sl.registerLazySingleton(
      () => CreateBookingUseCase(sl<BookingRepository>()),
    );
    sl.registerLazySingleton(
      () => CancelBookingUseCase(sl<BookingRepository>()),
    );
    sl.registerLazySingleton(
      () => SubmitReviewUseCase(sl<BookingRepository>()),
    );
    sl.registerLazySingleton(
      () => GetUserProfileUseCase(sl<UserProfileRepository>()),
    );
    sl.registerLazySingleton(
      () => CompleteStudentProfileUseCase(
        sl<UserProfileRepository>(),
        sl<SessionPolicyRepository>(),
      ),
    );
    sl.registerLazySingleton(
      () => CompleteTeacherProfileUseCase(
        sl<UserProfileRepository>(),
        sl<SessionPolicyRepository>(),
      ),
    );
    sl.registerLazySingleton(
      () => GetSessionPolicyUseCase(sl<SessionPolicyRepository>()),
    );
    sl.registerLazySingleton(
      () => UpdateTeacherEligibilityPolicyUseCase(
        sl<SessionPolicyRepository>(),
      ),
    );
    sl.registerLazySingleton(
      () => BlockAccountUseCase(sl<UserProfileRepository>()),
    );
    sl.registerLazySingleton(
      () => StartTeacherApplicationUseCase(sl<TeacherApplicationRepository>()),
    );
    sl.registerLazySingleton(
      () => SaveTeacherApplicationDraftUseCase(
        sl<TeacherApplicationRepository>(),
      ),
    );
    sl.registerLazySingleton(
      () => SubmitTeacherApplicationUseCase(sl<TeacherApplicationRepository>()),
    );
    sl.registerLazySingleton(
      () => GetTeacherApplicationStatusUseCase(
        sl<TeacherApplicationRepository>(),
      ),
    );
    sl.registerLazySingleton(
      () => GetCurrentUserTeacherCapabilityUseCase(
        applicationRepository: sl<TeacherApplicationRepository>(),
        profileRepository: sl<TeacherProfileRepository>(),
      ),
    );
    sl.registerLazySingleton(
      () => SaveTeacherPublicProfileUseCase(sl<TeacherProfileRepository>()),
    );
    sl.registerLazySingleton(
      () => ApproveTeacherApplicationUseCase(
        applicationRepository: sl<TeacherApplicationRepository>(),
        profileRepository: sl<TeacherProfileRepository>(),
      ),
    );
    sl.registerLazySingleton(
      () => RejectTeacherApplicationUseCase(sl<TeacherApplicationRepository>()),
    );
    sl.registerLazySingleton(
      () => SuspendTeacherProfileUseCase(
        applicationRepository: sl<TeacherApplicationRepository>(),
        profileRepository: sl<TeacherProfileRepository>(),
      ),
    );
    sl.registerLazySingleton(
      () => RevokeTeacherProfileUseCase(
        applicationRepository: sl<TeacherApplicationRepository>(),
        profileRepository: sl<TeacherProfileRepository>(),
      ),
    );
    sl.registerLazySingleton(
      () => GetMarketConfigUseCase(sl<MarketConfigRepository>()),
    );
    sl.registerLazySingleton(
      () => ValidateBookingEligibilityUseCase(
        profileRepository: sl<UserProfileRepository>(),
        policyRepository: sl<SessionPolicyRepository>(),
        teacherRepository: sl<TeacherRepository>(),
        marketConfigRepository: sl<MarketConfigRepository>(),
      ),
    );
  }

  /// Registers BLoC factories — new instance per navigation.
  static void registerBlocs(GetIt sl) {
    sl.registerFactory(
      () => TeacherApplicationBloc(
        startApplication: sl<StartTeacherApplicationUseCase>(),
        saveDraft: sl<SaveTeacherApplicationDraftUseCase>(),
        submitApplication: sl<SubmitTeacherApplicationUseCase>(),
        getStatus: sl<GetTeacherApplicationStatusUseCase>(),
        approveApplication: sl<ApproveTeacherApplicationUseCase>(),
        getUserProfile: sl<GetUserProfileUseCase>(),
      ),
    );
    sl.registerFactory(() => TeacherListBloc(sl<GetTeachersUseCase>()));
    sl.registerFactory(
      () => TeacherProfileBloc(
        getProfile: sl<GetTeacherProfileUseCase>(),
        getAvailability: sl<GetTeacherAvailabilityUseCase>(),
      ),
    );
    sl.registerFactory(
      () => BookingBloc(
        getAvailability: sl<GetTeacherAvailabilityUseCase>(),
        createBooking: sl<CreateBookingUseCase>(),
        validateEligibility: sl<ValidateBookingEligibilityUseCase>(),
      ),
    );
    sl.registerFactory(
      () => MySessionsBloc(
        getStudentSessions: sl<GetStudentSessionsUseCase>(),
        cancelBooking: sl<CancelBookingUseCase>(),
        submitReview: sl<SubmitReviewUseCase>(),
      ),
    );
    sl.registerFactory(
      () => TeacherDashboardBloc(
        getTeacherSessions: sl<GetTeacherSessionsUseCase>(),
        getAvailability: sl<GetTeacherAvailabilityUseCase>(),
        availabilityProvider: sl<AvailabilityProvider>(),
      ),
    );
    sl.registerFactory(
      () => AvailabilityCubit(repository: sl<ScheduleRepository>()),
    );
    sl.registerFactory(
      () => ProfileCompletionBloc(
        getUserProfile: sl<GetUserProfileUseCase>(),
        completeStudentProfile: sl<CompleteStudentProfileUseCase>(),
        getMarketConfig: sl<GetMarketConfigUseCase>(),
        getSessionPolicy: sl<GetSessionPolicyUseCase>(),
      ),
    );
  }
}

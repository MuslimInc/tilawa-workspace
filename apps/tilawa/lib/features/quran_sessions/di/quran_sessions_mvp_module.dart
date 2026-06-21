import 'package:get_it/get_it.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../data/fake_mvp_availability_provider.dart';
import '../data/fake_mvp_booking_repository.dart';
import '../data/fake_mvp_market_config_repository.dart';
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

    // ── Repositories ────────────────────────────────────────────────────────
    final teacherRepo = FakeMvpTeacherRepository(store);
    final bookingRepo = FakeMvpBookingRepository(store);
    final sessionRepo = FakeMvpSessionRepository(store);
    final availabilityProvider = FakeMvpAvailabilityProvider(store);
    final profileRepo = FakeMvpUserProfileRepository(store);
    final policyRepo = FakeMvpSessionPolicyRepository(store);
    final marketConfigRepo = FakeMvpMarketConfigRepository();

    final applicationRepo = FakeMvpTeacherApplicationRepository(store);
    final teacherProfileRepo = FakeMvpTeacherProfileRepository(store);

    sl.registerLazySingleton<TeacherRepository>(() => teacherRepo);
    sl.registerLazySingleton<BookingRepository>(() => bookingRepo);
    sl.registerLazySingleton<SessionRepository>(() => sessionRepo);
    sl.registerLazySingleton<AvailabilityProvider>(() => availabilityProvider);
    sl.registerLazySingleton<UserProfileRepository>(() => profileRepo);
    sl.registerLazySingleton<SessionPolicyRepository>(() => policyRepo);
    sl.registerLazySingleton<MarketConfigRepository>(() => marketConfigRepo);
    sl.registerLazySingleton<TeacherApplicationRepository>(
      () => applicationRepo,
    );
    sl.registerLazySingleton<TeacherProfileRepository>(
      () => teacherProfileRepo,
    );

    // ── Use cases ────────────────────────────────────────────────────────────
    sl.registerLazySingleton(() => GetTeachersUseCase(teacherRepo));
    sl.registerLazySingleton(() => GetTeacherProfileUseCase(teacherRepo));
    sl.registerLazySingleton(
      () => GetTeacherAvailabilityUseCase(teacherRepo),
    );
    sl.registerLazySingleton(
      () => GetStudentSessionsUseCase(sessionRepo),
    );
    sl.registerLazySingleton(
      () => GetTeacherSessionsUseCase(sessionRepo),
    );
    sl.registerLazySingleton(() => CreateBookingUseCase(bookingRepo));
    sl.registerLazySingleton(() => CancelBookingUseCase(bookingRepo));
    sl.registerLazySingleton(() => SubmitReviewUseCase(bookingRepo));

    // Profile + policy + market use cases
    sl.registerLazySingleton(() => GetUserProfileUseCase(profileRepo));
    sl.registerLazySingleton(
      () => CompleteStudentProfileUseCase(profileRepo),
    );
    sl.registerLazySingleton(
      () => CompleteTeacherProfileUseCase(profileRepo),
    );
    sl.registerLazySingleton(() => GetSessionPolicyUseCase(policyRepo));
    sl.registerLazySingleton(
      () => UpdateTeacherEligibilityPolicyUseCase(policyRepo),
    );
    sl.registerLazySingleton(() => BlockAccountUseCase(profileRepo));

    // Teacher application use cases
    sl.registerLazySingleton(
      () => StartTeacherApplicationUseCase(applicationRepo),
    );
    sl.registerLazySingleton(
      () => SaveTeacherApplicationDraftUseCase(applicationRepo),
    );
    sl.registerLazySingleton(
      () => SubmitTeacherApplicationUseCase(applicationRepo),
    );
    sl.registerLazySingleton(
      () => GetTeacherApplicationStatusUseCase(applicationRepo),
    );
    sl.registerLazySingleton(
      () => ApproveTeacherApplicationUseCase(
        applicationRepository: applicationRepo,
        profileRepository: teacherProfileRepo,
      ),
    );
    sl.registerLazySingleton(
      () => RejectTeacherApplicationUseCase(applicationRepo),
    );
    sl.registerLazySingleton(
      () => SuspendTeacherProfileUseCase(
        applicationRepository: applicationRepo,
        profileRepository: teacherProfileRepo,
      ),
    );
    sl.registerLazySingleton(
      () => RevokeTeacherProfileUseCase(
        applicationRepository: applicationRepo,
        profileRepository: teacherProfileRepo,
      ),
    );
    sl.registerLazySingleton(
      () => GetMarketConfigUseCase(marketConfigRepo),
    );
    sl.registerLazySingleton(
      () => ValidateBookingEligibilityUseCase(
        profileRepository: profileRepo,
        policyRepository: policyRepo,
        teacherRepository: teacherRepo,
        marketConfigRepository: marketConfigRepo,
      ),
    );

    // ── BLoC factories — new instance per call ───────────────────────────────
    sl.registerFactory(
      () => TeacherApplicationBloc(
        startApplication: sl<StartTeacherApplicationUseCase>(),
        saveDraft: sl<SaveTeacherApplicationDraftUseCase>(),
        submitApplication: sl<SubmitTeacherApplicationUseCase>(),
        getStatus: sl<GetTeacherApplicationStatusUseCase>(),
        approveApplication: sl<ApproveTeacherApplicationUseCase>(),
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
      () => ProfileCompletionBloc(
        getUserProfile: sl<GetUserProfileUseCase>(),
        completeStudentProfile: sl<CompleteStudentProfileUseCase>(),
        getMarketConfig: sl<GetMarketConfigUseCase>(),
      ),
    );
  }
}

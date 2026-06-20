import 'package:get_it/get_it.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../data/fake_mvp_availability_provider.dart';
import '../data/fake_mvp_booking_repository.dart';
import '../data/fake_mvp_session_repository.dart';
import '../data/fake_mvp_teacher_repository.dart';
import '../data/quran_sessions_mvp_store.dart';

/// Wires fake MVP repositories, boundaries, use cases, and BLoC factories
/// into [GetIt]. Call once after [configureDependencies].
class QuranSessionsMvpModule {
  QuranSessionsMvpModule._();

  static void register(GetIt sl) {
    final store = QuranSessionsMvpStore.instance;

    // Repositories
    final teacherRepo = FakeMvpTeacherRepository(store);
    final bookingRepo = FakeMvpBookingRepository(store);
    final sessionRepo = FakeMvpSessionRepository(store);
    final availabilityProvider = FakeMvpAvailabilityProvider(store);

    sl.registerLazySingleton<TeacherRepository>(() => teacherRepo);
    sl.registerLazySingleton<BookingRepository>(() => bookingRepo);
    sl.registerLazySingleton<SessionRepository>(() => sessionRepo);
    sl.registerLazySingleton<AvailabilityProvider>(() => availabilityProvider);

    // Use cases
    sl.registerLazySingleton(() => GetTeachersUseCase(teacherRepo));
    sl.registerLazySingleton(() => GetTeacherProfileUseCase(teacherRepo));
    sl.registerLazySingleton(() => GetTeacherAvailabilityUseCase(teacherRepo));
    sl.registerLazySingleton(() => GetStudentSessionsUseCase(sessionRepo));
    sl.registerLazySingleton(() => GetTeacherSessionsUseCase(sessionRepo));
    sl.registerLazySingleton(() => CreateBookingUseCase(bookingRepo));
    sl.registerLazySingleton(() => CancelBookingUseCase(bookingRepo));
    sl.registerLazySingleton(() => SubmitReviewUseCase(bookingRepo));

    // BLoC factories — new instance per call
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
  }
}

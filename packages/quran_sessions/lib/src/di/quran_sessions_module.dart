import '../data/datasources/booking_remote_data_source.dart';
import '../data/datasources/session_remote_data_source.dart';
import '../data/datasources/teacher_remote_data_source.dart';
import '../data/repositories/booking_repository_impl.dart';
import '../data/repositories/session_repository_impl.dart';
import '../data/repositories/teacher_repository_impl.dart';
import '../domain/repositories/booking_repository.dart';
import '../domain/repositories/session_repository.dart';
import '../domain/repositories/teacher_repository.dart';
import '../domain/usecases/cancel_booking_usecase.dart';
import '../domain/usecases/create_booking_usecase.dart';
import '../domain/usecases/get_student_sessions_usecase.dart';
import '../domain/usecases/get_teacher_availability_usecase.dart';
import '../domain/usecases/get_teacher_profile_usecase.dart';
import '../domain/usecases/get_teacher_sessions_usecase.dart';
import '../domain/usecases/get_teachers_usecase.dart';
import '../domain/usecases/submit_review_usecase.dart';

/// Registration helper for the `quran_sessions` package.
///
/// Call [QuranSessionsModule.register] in the host app's DI setup,
/// supplying the three remote datasource implementations your HTTP layer
/// provides. All repositories, use cases, and BLoC dependencies are wired
/// internally — the host app never needs to import `*Impl` classes directly.
///
/// ```dart
/// // In apps/tilawa/lib/core/di/app_module.dart:
/// QuranSessionsModule.register(
///   sl,
///   teacherDataSource: MyApiTeacherDataSource(sl()),
///   sessionDataSource: MyApiSessionDataSource(sl()),
///   bookingDataSource: MyApiBookingDataSource(sl()),
/// );
/// ```
class QuranSessionsModule {
  QuranSessionsModule._();

  /// Registers all repositories and use cases into [sl].
  ///
  /// [sl] must be a callable object that resolves dependencies:
  /// `T Function<T extends Object>()` — compatible with `get_it`'s `GetIt`
  /// instance used as a locator.
  static void register(
    void Function<T extends Object>(T instance, {String? instanceName})
    registerSingleton, {
    required TeacherRemoteDataSource teacherDataSource,
    required SessionRemoteDataSource sessionDataSource,
    required BookingRemoteDataSource bookingDataSource,
  }) {
    // ── Repositories ────────────────────────────────────────────────────────
    final teacherRepo = TeacherRepositoryImpl(teacherDataSource);
    final sessionRepo = SessionRepositoryImpl(sessionDataSource);
    final bookingRepo = BookingRepositoryImpl(bookingDataSource);

    registerSingleton<TeacherRepository>(teacherRepo);
    registerSingleton<SessionRepository>(sessionRepo);
    registerSingleton<BookingRepository>(bookingRepo);

    // ── Use cases ────────────────────────────────────────────────────────────
    registerSingleton(GetTeachersUseCase(teacherRepo));
    registerSingleton(GetTeacherProfileUseCase(teacherRepo));
    registerSingleton(GetTeacherAvailabilityUseCase(teacherRepo));
    registerSingleton(GetTeacherSessionsUseCase(sessionRepo));
    registerSingleton(GetStudentSessionsUseCase(sessionRepo));
    registerSingleton(CreateBookingUseCase(bookingRepo));
    registerSingleton(CancelBookingUseCase(bookingRepo));
    registerSingleton(SubmitReviewUseCase(bookingRepo));
  }
}

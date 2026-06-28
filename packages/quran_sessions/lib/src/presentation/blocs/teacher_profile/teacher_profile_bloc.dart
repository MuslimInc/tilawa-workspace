import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/get_teacher_availability_usecase.dart';
import '../../../domain/usecases/get_teacher_profile_usecase.dart';
import '../../../domain/usecases/report_session_concern_usecase.dart';
import 'teacher_profile_event.dart';
import 'teacher_profile_state.dart';

class TeacherProfileBloc
    extends Bloc<TeacherProfileEvent, TeacherProfileState> {
  TeacherProfileBloc({
    required this._getProfile,
    required this._getAvailability,
    this._reportConcern,
  }) : super(const TeacherProfileInitial()) {
    on<TeacherProfileRequested>(
      _onProfileRequested,
      transformer: restartable(),
    );
    on<AvailabilityWeekChanged>(_onWeekChanged, transformer: sequential());
    on<MoreReviewsRequested>(_onMoreReviews, transformer: droppable());
    on<TeacherProfileReportSubmitted>(
      _onReportSubmitted,
      transformer: sequential(),
    );
    on<TeacherProfileReportAcknowledged>(
      _onReportAcknowledged,
      transformer: sequential(),
    );
  }

  final GetTeacherProfileUseCase _getProfile;
  final GetTeacherAvailabilityUseCase _getAvailability;
  final ReportSessionConcernUseCase? _reportConcern;

  Future<void> _onProfileRequested(
    TeacherProfileRequested event,
    Emitter<TeacherProfileState> emit,
  ) async {
    emit(const TeacherProfileLoading());

    final profileResult = await _getProfile(event.teacherId);

    await profileResult.fold(
      (failure) async => emit(TeacherProfileFailure(failure)),
      (teacher) async {
        final availResult = await _getAvailability(
          event.teacherId,
          from: event.availabilityFrom,
          to: event.availabilityTo,
        );

        availResult.fold(
          (failure) => emit(TeacherProfileFailure(failure)),
          (slots) => emit(
            TeacherProfileSuccess(
              teacher: teacher,
              availability: slots,
              reviews: const [],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onWeekChanged(
    AvailabilityWeekChanged event,
    Emitter<TeacherProfileState> emit,
  ) async {
    final current = state;
    if (current is! TeacherProfileSuccess) return;

    emit(current.copyWith(isLoadingAvailability: true));

    final result = await _getAvailability(
      event.teacherId,
      from: event.from,
      to: event.to,
    );

    result.fold(
      (_) => emit(current.copyWith(isLoadingAvailability: false)),
      (slots) => emit(
        current.copyWith(
          availability: slots,
          isLoadingAvailability: false,
        ),
      ),
    );
  }

  Future<void> _onMoreReviews(
    MoreReviewsRequested event,
    Emitter<TeacherProfileState> emit,
  ) async {
    // Reviews fetch is wired when ReviewRepository use case is implemented.
    // Placeholder: no-op to keep the event contract stable.
  }

  Future<void> _onReportSubmitted(
    TeacherProfileReportSubmitted event,
    Emitter<TeacherProfileState> emit,
  ) async {
    final useCase = _reportConcern;
    final current = state;
    if (useCase == null || current is! TeacherProfileSuccess) return;

    emit(
      current.copyWith(
        reportInProgress: true,
        clearReportFailure: true,
        clearReportSubmitted: true,
      ),
    );

    final result = await useCase(
      category: event.category,
      description: event.description,
    );

    final after = state;
    if (after is! TeacherProfileSuccess) return;

    result.fold(
      (failure) => emit(
        after.copyWith(
          reportFailure: failure,
          clearReportInProgress: true,
        ),
      ),
      (_) => emit(
        after.copyWith(
          reportSubmitted: true,
          clearReportInProgress: true,
        ),
      ),
    );
  }

  void _onReportAcknowledged(
    TeacherProfileReportAcknowledged event,
    Emitter<TeacherProfileState> emit,
  ) {
    final current = state;
    if (current is! TeacherProfileSuccess) return;
    emit(current.copyWith(clearReportSubmitted: true));
  }
}

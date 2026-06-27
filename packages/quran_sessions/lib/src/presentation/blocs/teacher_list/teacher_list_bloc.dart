import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/quran_teacher.dart';
import '../../../domain/usecases/get_teacher_availability_usecase.dart';
import '../../../domain/usecases/get_teachers_usecase.dart';
import '../../models/teacher_availability_summary.dart';
import 'teacher_list_event.dart';
import 'teacher_list_state.dart';

class TeacherListBloc extends Bloc<TeacherListEvent, TeacherListState> {
  TeacherListBloc(
    this._getTeachers,
    this._getAvailability, {
    this._availabilityPresenter = const TeacherAvailabilitySummaryPresenter(),
  }) : super(const TeacherListInitial()) {
    on<LoadTeachersRequested>(_onLoadRequested, transformer: restartable());
    on<LoadMoreTeachersRequested>(_onLoadMore, transformer: droppable());
    on<TeacherFilterChanged>(_onFilterChanged, transformer: restartable());
  }

  final GetTeachersUseCase _getTeachers;
  final GetTeacherAvailabilityUseCase _getAvailability;
  final TeacherAvailabilitySummaryPresenter _availabilityPresenter;

  static const _availabilityWindow = Duration(days: 14);

  Future<void> _onLoadRequested(
    LoadTeachersRequested event,
    Emitter<TeacherListState> emit,
  ) async {
    emit(const TeacherListLoading());

    final result = await _getTeachers(
      specialization: event.specialization,
      language: event.language,
    );

    if (result.isLeft()) {
      emit(
        TeacherListFailure(
          result.fold((failure) => failure, (_) {
            throw StateError('unreachable');
          }),
        ),
      );
      return;
    }

    final page = result.fold((_) => throw StateError('unreachable'), (p) => p);
    if (page.teachers.isEmpty) {
      emit(
        TeacherListEmpty(
          activeSpecialization: event.specialization,
          activeLanguage: event.language,
        ),
      );
      return;
    }

    final availabilitySummaries = await _loadAvailabilitySummaries(
      page.teachers,
    );
    emit(
      TeacherListSuccess(
        teachers: page.teachers,
        hasMore: page.nextCursor != null,
        availabilitySummaries: availabilitySummaries,
        nextCursor: page.nextCursor,
        activeSpecialization: event.specialization,
        activeLanguage: event.language,
      ),
    );
  }

  Future<void> _onLoadMore(
    LoadMoreTeachersRequested event,
    Emitter<TeacherListState> emit,
  ) async {
    final current = state;
    if (current is! TeacherListSuccess || !current.hasMore) return;

    emit(current.copyWith(isLoadingMore: true));

    final result = await _getTeachers(
      specialization: current.activeSpecialization,
      language: current.activeLanguage,
      cursor: current.nextCursor,
    );

    if (result.isLeft()) {
      // On pagination error keep existing items visible and clear the flag.
      emit(current.copyWith(isLoadingMore: false));
      return;
    }

    final page = result.fold((_) => throw StateError('unreachable'), (p) => p);
    final newSummaries = await _loadAvailabilitySummaries(page.teachers);
    emit(
      current.copyWith(
        teachers: [...current.teachers, ...page.teachers],
        availabilitySummaries: {
          ...current.availabilitySummaries,
          ...newSummaries,
        },
        hasMore: page.nextCursor != null,
        nextCursor: page.nextCursor,
        isLoadingMore: false,
      ),
    );
  }

  Future<void> _onFilterChanged(
    TeacherFilterChanged event,
    Emitter<TeacherListState> emit,
  ) async {
    // Re-use load logic — filters always reset to page 1.
    await _onLoadRequested(
      LoadTeachersRequested(
        specialization: event.specialization,
        language: event.language,
      ),
      emit,
    );
  }

  Future<Map<String, TeacherAvailabilitySummary>> _loadAvailabilitySummaries(
    List<QuranTeacher> teachers,
  ) async {
    if (teachers.isEmpty) return const {};

    final now = DateTime.now();
    final entries = await Future.wait(
      teachers.map((teacher) async {
        final result = await _getAvailability(
          teacher.id,
          from: now,
          to: now.add(_availabilityWindow),
        );
        final summary = result.fold(
          (_) => _availabilityPresenter.unavailable(teacher.id),
          (slots) => _availabilityPresenter.fromSlots(
            teacherId: teacher.id,
            slots: slots,
          ),
        );
        return MapEntry(teacher.id, summary);
      }),
    );

    return Map.fromEntries(entries);
  }
}

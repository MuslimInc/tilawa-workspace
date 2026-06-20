import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/get_teachers_usecase.dart';
import 'teacher_list_event.dart';
import 'teacher_list_state.dart';

class TeacherListBloc extends Bloc<TeacherListEvent, TeacherListState> {
  TeacherListBloc(this._getTeachers) : super(const TeacherListInitial()) {
    on<LoadTeachersRequested>(_onLoadRequested, transformer: restartable());
    on<LoadMoreTeachersRequested>(_onLoadMore, transformer: droppable());
    on<TeacherFilterChanged>(_onFilterChanged, transformer: restartable());
  }

  final GetTeachersUseCase _getTeachers;

  Future<void> _onLoadRequested(
    LoadTeachersRequested event,
    Emitter<TeacherListState> emit,
  ) async {
    emit(const TeacherListLoading());

    final result = await _getTeachers(
      specialization: event.specialization,
      language: event.language,
    );

    result.fold(
      (failure) => emit(TeacherListFailure(failure)),
      (page) => page.teachers.isEmpty
          ? emit(
              TeacherListEmpty(
                activeSpecialization: event.specialization,
                activeLanguage: event.language,
              ),
            )
          : emit(
              TeacherListSuccess(
                teachers: page.teachers,
                hasMore: page.nextCursor != null,
                nextCursor: page.nextCursor,
                activeSpecialization: event.specialization,
                activeLanguage: event.language,
              ),
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

    result.fold(
      // On pagination error keep existing items visible and clear the flag.
      (failure) => emit(current.copyWith(isLoadingMore: false)),
      (page) => emit(
        current.copyWith(
          teachers: [...current.teachers, ...page.teachers],
          hasMore: page.nextCursor != null,
          nextCursor: page.nextCursor,
          isLoadingMore: false,
        ),
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
}

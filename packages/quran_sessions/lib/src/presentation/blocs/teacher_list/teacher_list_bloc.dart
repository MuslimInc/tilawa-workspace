import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/teacher_list_item.dart';
import '../../../domain/usecases/get_teacher_availability_usecase.dart';
import '../../../domain/usecases/resolve_teacher_list_usecase.dart';
import '../../models/teacher_availability_summary.dart';
import 'teacher_list_event.dart';
import 'teacher_list_state.dart';

class TeacherListBloc extends Bloc<TeacherListEvent, TeacherListState> {
  TeacherListBloc(
    this._resolveTeacherList,
    this._getAvailability, {
    this._availabilityPresenter = const TeacherAvailabilitySummaryPresenter(),
  }) : super(const TeacherListInitial()) {
    on<LoadTeachersRequested>(_onLoadRequested, transformer: restartable());
    on<LoadMoreTeachersRequested>(_onLoadMore, transformer: droppable());
    on<TeacherFilterChanged>(_onFilterChanged, transformer: restartable());
  }

  /// Fetches teachers and resolves each row's server quote + bookability. All
  /// pricing/bookability rules live here, not in the BLoC.
  final ResolveTeacherListUseCase _resolveTeacherList;
  final GetTeacherAvailabilityUseCase _getAvailability;
  final TeacherAvailabilitySummaryPresenter _availabilityPresenter;

  static const _availabilityWindow = Duration(days: 14);

  Future<void> _onLoadRequested(
    LoadTeachersRequested event,
    Emitter<TeacherListState> emit,
  ) async {
    emit(const TeacherListLoading());

    final result = await _resolveTeacherList(
      specialization: event.specialization,
      language: event.language,
    );

    await result.fold(
      (failure) async => emit(TeacherListFailure(failure)),
      (page) async {
        if (page.rawTeacherCount == 0) {
          emit(
            TeacherListEmpty(
              activeSpecialization: event.specialization,
              activeLanguage: event.language,
            ),
          );
          return;
        }
        if (page.items.isEmpty) {
          // Teachers exist but every one is durably non-bookable for this
          // viewer (typically paid while the payment provider is disabled).
          emit(
            TeacherListNoBookableTeachers(
              activeSpecialization: event.specialization,
              activeLanguage: event.language,
              hiddenByBlockReason: page.hiddenByBlockReason,
            ),
          );
          return;
        }

        emit(
          TeacherListSuccess(
            items: page.items,
            hasMore: page.hasMore,
            availabilitySummaries: await _loadAvailabilitySummaries(page.items),
            nextCursor: page.nextCursor,
            activeSpecialization: event.specialization,
            activeLanguage: event.language,
          ),
        );
      },
    );
  }

  Future<void> _onLoadMore(
    LoadMoreTeachersRequested event,
    Emitter<TeacherListState> emit,
  ) async {
    final current = state;
    if (current is! TeacherListSuccess || !current.hasMore) return;

    emit(current.copyWith(isLoadingMore: true));

    final result = await _resolveTeacherList(
      specialization: current.activeSpecialization,
      language: current.activeLanguage,
      cursor: current.nextCursor,
    );

    await result.fold(
      // On pagination error keep existing items visible and clear the flag.
      (_) async => emit(current.copyWith(isLoadingMore: false)),
      (page) async => emit(
        current.copyWith(
          items: [...current.items, ...page.items],
          availabilitySummaries: {
            ...current.availabilitySummaries,
            ...await _loadAvailabilitySummaries(page.items),
          },
          hasMore: page.hasMore,
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

  /// Builds the per-teacher availability summary shown on each card. Keyed by
  /// teacher id for O(1) lookup; fetched only for the visible [items].
  Future<Map<String, TeacherAvailabilitySummary>> _loadAvailabilitySummaries(
    List<TeacherListItem> items,
  ) async {
    if (items.isEmpty) return const {};

    final now = DateTime.now();
    final entries = await Future.wait(
      items.map((item) async {
        final teacher = item.teacher;
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

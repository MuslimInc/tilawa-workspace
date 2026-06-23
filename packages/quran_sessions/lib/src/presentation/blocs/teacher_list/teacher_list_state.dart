import 'package:equatable/equatable.dart';

import '../../../domain/entities/quran_teacher.dart';
import '../../../domain/failures/quran_sessions_failure.dart';

sealed class TeacherListState extends Equatable {
  const TeacherListState();

  @override
  List<Object?> get props => [];
}

final class TeacherListInitial extends TeacherListState {
  const TeacherListInitial();
}

final class TeacherListLoading extends TeacherListState {
  const TeacherListLoading();
}

final class TeacherListSuccess extends TeacherListState {
  const TeacherListSuccess({
    required this.teachers,
    required this.hasMore,
    this.nextCursor,
    this.isLoadingMore = false,
    this.activeSpecialization,
    this.activeLanguage,
  });

  final List<QuranTeacher> teachers;
  final bool hasMore;
  final String? nextCursor;

  /// True while appending the next page; existing [teachers] stay visible.
  final bool isLoadingMore;

  final String? activeSpecialization;
  final String? activeLanguage;

  @override
  List<Object?> get props => [
    teachers,
    hasMore,
    nextCursor,
    isLoadingMore,
    activeSpecialization,
    activeLanguage,
  ];

  TeacherListSuccess copyWith({
    List<QuranTeacher>? teachers,
    bool? hasMore,
    String? nextCursor,
    bool? isLoadingMore,
    String? activeSpecialization,
    String? activeLanguage,
  }) => TeacherListSuccess(
    teachers: teachers ?? this.teachers,
    hasMore: hasMore ?? this.hasMore,
    nextCursor: nextCursor ?? this.nextCursor,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    activeSpecialization: activeSpecialization ?? this.activeSpecialization,
    activeLanguage: activeLanguage ?? this.activeLanguage,
  );
}

/// No results after applying the current filters.
final class TeacherListEmpty extends TeacherListState {
  const TeacherListEmpty({
    this.activeSpecialization,
    this.activeLanguage,
  });

  final String? activeSpecialization;
  final String? activeLanguage;

  @override
  List<Object?> get props => [activeSpecialization, activeLanguage];
}

final class TeacherListFailure extends TeacherListState {
  const TeacherListFailure(this.failure);

  final QuranSessionsFailure failure;

  @override
  List<Object?> get props => [failure];
}

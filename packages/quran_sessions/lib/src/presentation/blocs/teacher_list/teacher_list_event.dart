import 'package:equatable/equatable.dart';

sealed class TeacherListEvent extends Equatable {
  const TeacherListEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched when the screen mounts or the user pulls-to-refresh.
final class LoadTeachersRequested extends TeacherListEvent {
  const LoadTeachersRequested({
    this.specialization,
    this.language,
  });

  final String? specialization;
  final String? language;

  @override
  List<Object?> get props => [specialization, language];
}

/// Dispatched when the user scrolls to the end of the list and more pages exist.
final class LoadMoreTeachersRequested extends TeacherListEvent {
  const LoadMoreTeachersRequested();
}

/// Dispatched when the user changes a filter chip.
final class TeacherFilterChanged extends TeacherListEvent {
  const TeacherFilterChanged({
    this.specialization,
    this.language,
  });

  final String? specialization;
  final String? language;

  @override
  List<Object?> get props => [specialization, language];
}

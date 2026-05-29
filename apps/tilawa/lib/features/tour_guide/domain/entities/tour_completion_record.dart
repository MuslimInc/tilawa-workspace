import 'package:equatable/equatable.dart';

/// Persisted completion metadata for one tour.
class TourCompletionRecord extends Equatable {
  const TourCompletionRecord({
    required this.completed,
    this.completedVersion = 0,
  });

  final bool completed;
  final int completedVersion;

  bool isSatisfiedBy(int definitionVersion) {
    return completed && completedVersion >= definitionVersion;
  }

  @override
  List<Object?> get props => <Object?>[completed, completedVersion];
}

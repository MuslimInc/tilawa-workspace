import 'package:equatable/equatable.dart';

import '../../domain/entities/reel.dart';

enum SavedReelsStatus { initial, loading, ready, empty, error }

final class SavedReelsState extends Equatable {
  const SavedReelsState({
    this.status = SavedReelsStatus.initial,
    this.reels = const [],
    this.errorMessage,
  });

  final SavedReelsStatus status;
  final List<Reel> reels;
  final String? errorMessage;

  SavedReelsState copyWith({
    SavedReelsStatus? status,
    List<Reel>? reels,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SavedReelsState(
      status: status ?? this.status,
      reels: reels ?? this.reels,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, reels, errorMessage];
}

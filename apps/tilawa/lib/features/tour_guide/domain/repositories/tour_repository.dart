import '../entities/tour_completion_record.dart';

/// Persistence for tour completion and debug resets.
abstract interface class TourRepository {
  Future<TourCompletionRecord> getCompletion(String tourId);

  Future<void> markCompleted({
    required String tourId,
    required int version,
  });

  Future<void> resetTour(String tourId);

  Future<void> resetAllTours();
}

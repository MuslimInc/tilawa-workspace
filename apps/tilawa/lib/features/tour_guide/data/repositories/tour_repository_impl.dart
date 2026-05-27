import 'package:injectable/injectable.dart';

import '../../domain/entities/tour_completion_record.dart';
import '../../domain/repositories/tour_repository.dart';
import '../datasources/tour_progress_local_datasource.dart';

@LazySingleton(as: TourRepository)
class TourRepositoryImpl implements TourRepository {
  TourRepositoryImpl(this._local);

  final TourProgressLocalDataSource _local;

  @override
  Future<TourCompletionRecord> getCompletion(String tourId) =>
      _local.read(tourId);

  @override
  Future<void> markCompleted({
    required String tourId,
    required int version,
  }) {
    return _local.write(
      tourId: tourId,
      record: TourCompletionRecord(
        completed: true,
        completedVersion: version,
      ),
    );
  }

  @override
  Future<void> resetTour(String tourId) => _local.clearTour(tourId);

  @override
  Future<void> resetAllTours() => _local.clearAll();
}

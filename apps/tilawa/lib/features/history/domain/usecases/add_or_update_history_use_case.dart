import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/errors/failures.dart';
import '../entities/history_entity.dart';
import '../repositories/history_repository.dart';

@lazySingleton
class AddOrUpdateHistoryUseCase {
  const AddOrUpdateHistoryUseCase(this._repository);

  final HistoryRepository _repository;

  Future<Either<Failure, HistoryEntity>> call({
    required int surahId,
    required String surahName,
    required String surahNameEn,
    required String reciterId,
    required String reciterName,
    required int moshafId,
    required String moshafName,
    required int lastPositionMs,
    required int durationMs,
    required String audioUrl,
    String? artworkUrl,
    bool completed = false,
  }) async {
    try {
      final HistoryEntity history = await _repository.addOrUpdateHistory(
        surahId: surahId,
        surahName: surahName,
        surahNameEn: surahNameEn,
        reciterId: reciterId,
        reciterName: reciterName,
        moshafId: moshafId,
        moshafName: moshafName,
        lastPositionMs: lastPositionMs,
        durationMs: durationMs,
        audioUrl: audioUrl,
        artworkUrl: artworkUrl,
        completed: completed,
      );
      return Right(history);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}

import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/history/domain/entities/history_entity.dart';
import 'package:tilawa/features/history/domain/repositories/history_repository.dart';
import 'package:tilawa/features/home/presentation/cubit/home_quran_resume_cubit.dart';
import 'package:tilawa/features/quran_reader/domain/usecases/get_last_read_position_use_case.dart';
import 'package:tilawa_core/errors/failures.dart';

void main() {
  test('load emits ready state with last-read position', () async {
    final cubit = HomeQuranResumeCubit(
      _SuccessGetLastRead(),
      _FakeHistoryRepository(),
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.surahNumber, 2);
    expect(cubit.state.page, 42);
    expect(cubit.state.progressFraction(604), closeTo(42 / 604, 0.001));
  });

  test('load emits failure when use case fails', () async {
    final cubit = HomeQuranResumeCubit(
      _FailingGetLastRead(),
      _FakeHistoryRepository(),
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.failure, isNotNull);
  });
}

class _SuccessGetLastRead implements GetLastReadPositionUseCase {
  @override
  Future<Either<Failure, ({int? surahNumber, int? ayahNumber, int? page})>>
  call() async {
    return const Right((surahNumber: 2, ayahNumber: 43, page: 42));
  }
}

class _FailingGetLastRead implements GetLastReadPositionUseCase {
  @override
  Future<Either<Failure, ({int? surahNumber, int? ayahNumber, int? page})>>
  call() async {
    return Left(Failure.unexpectedError('storage'));
  }
}

class _FakeHistoryRepository implements HistoryRepository {
  @override
  Future<List<HistoryEntity>> getRecentHistory({int limit = 20}) async => [];

  @override
  Future<List<HistoryEntity>> getAllHistory() async => [];

  @override
  Future<HistoryEntity> addOrUpdateHistory({
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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAllHistory() async {}

  @override
  Future<void> deleteHistory(String id) async {}

  @override
  Future<HistoryEntity?> getHistoryById(String id) async => null;

  @override
  Future<List<HistoryEntity>> getHistoryByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async => [];

  @override
  Future<List<HistoryEntity>> getHistoryByReciter(String reciterId) async => [];

  @override
  Future<HistoryEntity?> updateLastPosition({
    required String id,
    required int lastPositionMs,
    bool? completed,
  }) async => null;

  @override
  Future<void> deleteHistoryOlderThan(DateTime date) async {}

  @override
  Future<List<HistoryEntity>> searchHistory(String query) async => [];

  @override
  Future<int> getHistoryCount() async => 0;

  @override
  Future<int> getTotalListeningTime() async => 0;

  @override
  Future<List<HistoryEntity>> getMostPlayedSurahs({int limit = 10}) async => [];

  @override
  Future<bool> hasBeenPlayed({
    required int surahId,
    required String reciterId,
    required int moshafId,
  }) async => false;
}

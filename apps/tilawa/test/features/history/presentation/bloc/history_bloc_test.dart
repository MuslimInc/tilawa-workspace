import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/history/domain/entities/history_entity.dart';
import 'package:tilawa/features/history/domain/usecases/clear_all_history_use_case.dart';
import 'package:tilawa/features/history/domain/usecases/delete_history_use_case.dart';
import 'package:tilawa/features/history/domain/usecases/get_all_history_use_case.dart';
import 'package:tilawa/features/history/domain/usecases/get_recent_history_use_case.dart';
import 'package:tilawa/features/history/domain/usecases/search_history_use_case.dart';
import 'package:tilawa/features/history/presentation/bloc/history_bloc.dart';
import 'package:tilawa_core/errors/failures.dart';

class MockGetAllHistoryUseCase extends Mock implements GetAllHistoryUseCase {}

class MockGetRecentHistoryUseCase extends Mock
    implements GetRecentHistoryUseCase {}

class MockDeleteHistoryUseCase extends Mock implements DeleteHistoryUseCase {}

class MockClearAllHistoryUseCase extends Mock
    implements ClearAllHistoryUseCase {}

class MockSearchHistoryUseCase extends Mock implements SearchHistoryUseCase {}

void main() {
  late HistoryBloc bloc;
  late MockGetAllHistoryUseCase mockGetAllHistoryUseCase;
  late MockGetRecentHistoryUseCase mockGetRecentHistoryUseCase;
  late MockDeleteHistoryUseCase mockDeleteHistoryUseCase;
  late MockClearAllHistoryUseCase mockClearAllHistoryUseCase;
  late MockSearchHistoryUseCase mockSearchHistoryUseCase;

  setUp(() {
    mockGetAllHistoryUseCase = MockGetAllHistoryUseCase();
    mockGetRecentHistoryUseCase = MockGetRecentHistoryUseCase();
    mockDeleteHistoryUseCase = MockDeleteHistoryUseCase();
    mockClearAllHistoryUseCase = MockClearAllHistoryUseCase();
    mockSearchHistoryUseCase = MockSearchHistoryUseCase();

    bloc = HistoryBloc(
      mockGetAllHistoryUseCase,
      mockGetRecentHistoryUseCase,
      mockDeleteHistoryUseCase,
      mockClearAllHistoryUseCase,
      mockSearchHistoryUseCase,
    );
  });

  final tHistoryEntity = HistoryEntity(
    id: '1',
    surahId: 1,
    surahName: 'Al-Fatihah',
    surahNameEn: 'The Opening',
    reciterId: '1',
    reciterName: 'Mishary Rashid Alafasy',
    moshafId: 1,
    moshafName: 'Hafs',
    lastPositionMs: 1000,
    durationMs: 5000,
    audioUrl: 'url',
    playedAt: DateTime.fromMicrosecondsSinceEpoch(0),
  );

  group('HistoryBloc', () {
    test('initial state should be HistoryState()', () {
      expect(bloc.state, const HistoryState());
    });

    blocTest<HistoryBloc, HistoryState>(
      'emits [loading, loaded] when LoadAllHistory is added and use case returns data',
      build: () {
        when(
          () => mockGetAllHistoryUseCase.call(),
        ).thenAnswer((_) async => Right([tHistoryEntity]));
        return bloc;
      },
      act: (bloc) => bloc.add(const HistoryEvent.loadAllHistory()),
      expect: () => [
        const HistoryState(status: HistoryStatus.loading),
        HistoryState(
          status: HistoryStatus.loaded,
          historyList: [tHistoryEntity],
          filteredList: [tHistoryEntity],
          totalListeningTimeMs: 1000,
        ),
      ],
    );

    blocTest<HistoryBloc, HistoryState>(
      'emits [loading, empty] when LoadAllHistory is added and use case returns empty list',
      build: () {
        when(
          () => mockGetAllHistoryUseCase.call(),
        ).thenAnswer((_) async => const Right([]));
        return bloc;
      },
      act: (bloc) => bloc.add(const HistoryEvent.loadAllHistory()),
      expect: () => [
        const HistoryState(status: HistoryStatus.loading),
        const HistoryState(status: HistoryStatus.empty),
      ],
    );

    blocTest<HistoryBloc, HistoryState>(
      'emits [loading, error] when LoadAllHistory is added and use case returns failure',
      build: () {
        when(
          () => mockGetAllHistoryUseCase.call(),
        ).thenAnswer((_) async => const Left(CacheFailure('Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const HistoryEvent.loadAllHistory()),
      expect: () => [
        const HistoryState(status: HistoryStatus.loading),
        const HistoryState(
          status: HistoryStatus.error,
          failure: CacheFailure('Error'),
        ),
      ],
    );

    blocTest<HistoryBloc, HistoryState>(
      'emits [loading, loaded] with filtered results when SearchHistory is added',
      build: () {
        when(
          () => mockSearchHistoryUseCase.call(any()),
        ).thenAnswer((_) async => Right([tHistoryEntity]));
        return bloc;
      },
      act: (bloc) => bloc.add(const HistoryEvent.searchHistory('Fatihah')),
      expect: () => [
        const HistoryState(
          status: HistoryStatus.loading,
          searchQuery: 'Fatihah',
        ),
        HistoryState(
          status: HistoryStatus.loaded,
          searchQuery: 'Fatihah',
          filteredList: [tHistoryEntity],
        ),
      ],
    );

    blocTest<HistoryBloc, HistoryState>(
      'clears search when clearSearch is added',
      seed: () => HistoryState(
        status: HistoryStatus.loaded,
        historyList: [tHistoryEntity],
        filteredList: const [],
        searchQuery: 'query',
      ),
      build: () => bloc,
      act: (bloc) => bloc.add(const HistoryEvent.clearSearch()),
      expect: () => [
        HistoryState(
          status: HistoryStatus.loaded,
          historyList: [tHistoryEntity],
          filteredList: [tHistoryEntity],
          searchQuery: '',
        ),
      ],
    );

    blocTest<HistoryBloc, HistoryState>(
      'removes item from list when DeleteHistory is added',
      seed: () => HistoryState(
        status: HistoryStatus.loaded,
        historyList: [tHistoryEntity],
        filteredList: [tHistoryEntity],
        totalListeningTimeMs: 1000,
      ),
      build: () {
        when(
          () => mockDeleteHistoryUseCase.call(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const HistoryEvent.deleteHistory('1')),
      expect: () => [
        const HistoryState(
          status: HistoryStatus.empty,
          historyList: [],
          filteredList: [],
          totalListeningTimeMs: 0,
        ),
      ],
    );

    blocTest<HistoryBloc, HistoryState>(
      'clears all history when ClearAllHistory is added',
      seed: () => HistoryState(
        status: HistoryStatus.loaded,
        historyList: [tHistoryEntity],
      ),
      build: () {
        when(
          () => mockClearAllHistoryUseCase.call(),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const HistoryEvent.clearAllHistory()),
      expect: () => [
        const HistoryState(status: HistoryStatus.empty, historyList: []),
      ],
    );
  });
}

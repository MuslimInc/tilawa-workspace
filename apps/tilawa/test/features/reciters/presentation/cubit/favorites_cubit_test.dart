import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa/features/reciters/domain/usecases/clear_favorite_reciters_use_case.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_favorite_reciters_use_case.dart';
import 'package:tilawa/features/reciters/domain/usecases/toggle_favorite_reciter_use_case.dart';
import 'package:tilawa/features/reciters/presentation/cubit/favorites_cubit.dart';
import 'package:tilawa/features/reciters/presentation/cubit/favorites_state.dart';

import 'favorites_cubit_test.mocks.dart';

@GenerateMocks([
  GetFavoriteRecitersUseCase,
  ToggleFavoriteReciterUseCase,
  ClearFavoriteRecitersUseCase,
])
void main() {
  late FavoritesCubit cubit;
  late MockGetFavoriteRecitersUseCase mockGetFavorites;
  late MockToggleFavoriteReciterUseCase mockToggleFavorite;
  late MockClearFavoriteRecitersUseCase mockClearFavorites;

  setUp(() {
    provideDummy<Either<Failure, List<ReciterEntity>>>(const Right([]));
    provideDummy<Either<Failure, void>>(const Right(null));
    mockGetFavorites = MockGetFavoriteRecitersUseCase();
    mockToggleFavorite = MockToggleFavoriteReciterUseCase();
    mockClearFavorites = MockClearFavoriteRecitersUseCase();
    cubit = FavoritesCubit(
      mockGetFavorites,
      mockToggleFavorite,
      mockClearFavorites,
    );
  });

  tearDown(() {
    cubit.close();
  });

  const tReciter = ReciterEntity(
    id: 1,
    name: 'Test Reciter',
    letter: 'T',
    date: '2023',
    moshaf: [],
  );

  test('initial state is FavoritesInitial', () {
    expect(cubit.state, FavoritesInitial());
  });

  group('loadFavorites', () {
    blocTest<FavoritesCubit, FavoritesState>(
      'emits [FavoritesLoading, FavoritesLoaded] when success',
      build: () {
        when(
          mockGetFavorites(any),
        ).thenAnswer((_) async => const Right([tReciter]));
        return cubit;
      },
      act: (cubit) => cubit.loadFavorites(),
      expect: () => [
        FavoritesLoading(),
        const FavoritesLoaded(favorites: [tReciter], favoriteIds: {1}),
      ],
    );

    blocTest<FavoritesCubit, FavoritesState>(
      'emits [FavoritesLoading, FavoritesError] when failure',
      build: () {
        when(
          mockGetFavorites(any),
        ).thenAnswer((_) async => const Left(ServerFailure('Error')));
        return cubit;
      },
      act: (cubit) => cubit.loadFavorites(),
      expect: () => [
        FavoritesLoading(),
        const FavoritesError(ServerFailure('Error')),
      ],
    );
  });

  group('toggleFavorite', () {
    blocTest<FavoritesCubit, FavoritesState>(
      'optimistically updates state and calls usecase',
      build: () {
        when(mockGetFavorites(any)).thenAnswer((_) async => const Right([]));
        when(
          mockToggleFavorite(any),
        ).thenAnswer((_) async => const Right(null));
        return cubit;
      },
      seed: () => const FavoritesLoaded(favorites: [], favoriteIds: {}),
      act: (cubit) => cubit.toggleFavorite(tReciter),
      expect: () => [
        // Expect optimistic update: added to favorites
        const FavoritesLoaded(favorites: [tReciter], favoriteIds: {1}),
      ],
      verify: (_) {
        verify(mockToggleFavorite(1)).called(1);
      },
    );

    blocTest<FavoritesCubit, FavoritesState>(
      'reverts state on failure',
      build: () {
        when(
          mockGetFavorites(any),
        ).thenAnswer((_) async => const Right([])); // For the revert reload
        when(
          mockToggleFavorite(any),
        ).thenAnswer((_) async => const Left(ServerFailure('Fail')));
        return cubit;
      },
      seed: () => const FavoritesLoaded(favorites: [], favoriteIds: {}),
      act: (cubit) => cubit.toggleFavorite(tReciter),
      expect: () => [
        // Optimistic add
        const FavoritesLoaded(favorites: [tReciter], favoriteIds: {1}),
        FavoritesLoading(), // from loadFavorites() called on revert
        // Error emitted immediately after calling loadFavorites
        const FavoritesError(ServerFailure('Fail')),
        // Revert (loadFavorites completion) -> Loaded empty
        const FavoritesLoaded(favorites: [], favoriteIds: {}),
      ],
    );

    blocTest<FavoritesCubit, FavoritesState>(
      'optimistically removes from state and calls usecase',
      build: () {
        when(
          mockGetFavorites(any),
        ).thenAnswer((_) async => const Right([tReciter]));
        when(
          mockToggleFavorite(any),
        ).thenAnswer((_) async => const Right(null));
        return cubit;
      },
      seed: () =>
          const FavoritesLoaded(favorites: [tReciter], favoriteIds: {1}),
      act: (cubit) => cubit.toggleFavorite(tReciter),
      expect: () => [
        // Expect optimistic update: removed from favorites
        const FavoritesLoaded(
          favorites: [],
          favoriteIds: {},
          removedReciter: tReciter,
        ),
      ],
      verify: (_) {
        verify(mockToggleFavorite(1)).called(1);
      },
    );

    blocTest<FavoritesCubit, FavoritesState>(
      'reverts removal from state on failure',
      build: () {
        when(
          mockGetFavorites(any),
        ).thenAnswer((_) async => const Right([tReciter])); // Re-sync
        when(
          mockToggleFavorite(any),
        ).thenAnswer((_) async => const Left(ServerFailure('Fail')));
        return cubit;
      },
      seed: () =>
          const FavoritesLoaded(favorites: [tReciter], favoriteIds: {1}),
      act: (cubit) => cubit.toggleFavorite(tReciter),
      expect: () => [
        // Optimistic remove
        const FavoritesLoaded(
          favorites: [],
          favoriteIds: {},
          removedReciter: tReciter,
        ),
        FavoritesLoading(),
        const FavoritesError(ServerFailure('Fail')),
        const FavoritesLoaded(favorites: [tReciter], favoriteIds: {1}),
      ],
    );

    blocTest<FavoritesCubit, FavoritesState>(
      'ignores subsequent calls while a toggle is pending (debouncing)',
      build: () {
        when(mockToggleFavorite(any)).thenAnswer((_) async {
          // Simulate network delay
          await Future.delayed(const Duration(milliseconds: 100));
          return const Right(null);
        });
        return cubit;
      },
      seed: () => const FavoritesLoaded(favorites: [], favoriteIds: {}),
      act: (cubit) async {
        // Fire twice rapidly
        final Future<void> future1 = cubit.toggleFavorite(tReciter);
        final Future<void> future2 = cubit.toggleFavorite(tReciter);
        await Future.wait([future1, future2]);
        // Wait for potential completion
        await Future.delayed(const Duration(milliseconds: 200));
      },
      expect: () => [
        // Expect only one optimistic update
        const FavoritesLoaded(favorites: [tReciter], favoriteIds: {1}),
      ],
      verify: (_) {
        // usecase should only be called once
        verify(mockToggleFavorite(1)).called(1);
      },
    );

    blocTest<FavoritesCubit, FavoritesState>(
      'handles toggle when state is not FavoritesLoaded (covers fallback)',
      build: () {
        when(
          mockToggleFavorite(any),
        ).thenAnswer((_) async => const Right(null));
        return cubit;
      },
      // State is FavoritesInitial
      act: (cubit) => cubit.toggleFavorite(tReciter),
      expect: () =>
          [], // No state change emitted because it's not FavoritesLoaded
      verify: (_) {
        verify(mockToggleFavorite(1)).called(1);
      },
    );
  });

  group('clearAllFavorites', () {
    blocTest<FavoritesCubit, FavoritesState>(
      'emits empty state when success',
      build: () {
        when(mockClearFavorites()).thenAnswer((_) async => const Right(null));
        return cubit;
      },
      seed: () =>
          const FavoritesLoaded(favorites: [tReciter], favoriteIds: {1}),
      act: (cubit) => cubit.clearAllFavorites(),
      expect: () => [const FavoritesLoaded(favorites: [], favoriteIds: {})],
      verify: (_) {
        verify(mockClearFavorites()).called(1);
      },
    );

    blocTest<FavoritesCubit, FavoritesState>(
      'reverts state when failure',
      build: () {
        when(
          mockClearFavorites(),
        ).thenAnswer((_) async => const Left(ServerFailure('Fail')));
        return cubit;
      },
      seed: () =>
          const FavoritesLoaded(favorites: [tReciter], favoriteIds: {1}),
      act: (cubit) => cubit.clearAllFavorites(),
      expect: () => [
        // Optimistic clear
        const FavoritesLoaded(favorites: [], favoriteIds: {}),
        // Revert
        const FavoritesLoaded(favorites: [tReciter], favoriteIds: {1}),
      ],
      verify: (_) {
        verify(mockClearFavorites()).called(1);
      },
    );

    test('does not clear favorites while a toggle is pending', () async {
      when(mockToggleFavorite(any)).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return const Right(null);
      });

      cubit = FavoritesCubit(
        mockGetFavorites,
        mockToggleFavorite,
        mockClearFavorites,
      );
      // Change state to Loaded so clearAllFavorites has something to do
      // (But since it's a field _isPending check, initial state doesn't matter much for returning false,
      // but the method checks _pendingReciterIds.isNotEmpty)

      // Start a toggle to set pending
      final Future<void> toggleFuture = cubit.toggleFavorite(tReciter);

      await cubit.clearAllFavorites();

      verifyNever(mockClearFavorites());

      await toggleFuture;
    });
  });
}

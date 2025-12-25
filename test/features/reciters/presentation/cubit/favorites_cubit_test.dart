import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/entities/reciter_entity.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_favorite_reciters_use_case.dart';
import 'package:tilawa/features/reciters/domain/usecases/toggle_favorite_reciter_use_case.dart';
import 'package:tilawa/features/reciters/presentation/cubit/favorites_cubit.dart';
import 'package:tilawa/features/reciters/presentation/cubit/favorites_state.dart';

import 'favorites_cubit_test.mocks.dart';

@GenerateMocks([GetFavoriteRecitersUseCase, ToggleFavoriteReciterUseCase])
void main() {
  late FavoritesCubit cubit;
  late MockGetFavoriteRecitersUseCase mockGetFavorites;
  late MockToggleFavoriteReciterUseCase mockToggleFavorite;

  setUp(() {
    provideDummy<Either<Failure, List<ReciterEntity>>>(const Right([]));
    provideDummy<Either<Failure, void>>(const Right(null));
    mockGetFavorites = MockGetFavoriteRecitersUseCase();
    mockToggleFavorite = MockToggleFavoriteReciterUseCase();
    cubit = FavoritesCubit(mockGetFavorites, mockToggleFavorite);
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
      expect: () => [FavoritesLoading(), const FavoritesError('Error')],
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
        const FavoritesError('Fail'),
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
        const FavoritesLoaded(favorites: [], favoriteIds: {}),
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
        const FavoritesLoaded(favorites: [], favoriteIds: {}),
        FavoritesLoading(),
        const FavoritesError('Fail'),
        const FavoritesLoaded(favorites: [tReciter], favoriteIds: {1}),
      ],
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
}

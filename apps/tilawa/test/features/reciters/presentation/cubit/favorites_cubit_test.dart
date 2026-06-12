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
    when(mockGetFavorites.takeCachedSuccessForStartup()).thenReturn(null);
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

  test(
    'starts in FavoritesLoaded when splash prefetched favorites are present',
    () {
      when(
        mockGetFavorites.takeCachedSuccessForStartup(),
      ).thenReturn(const [tReciter]);

      final FavoritesCubit seeded = FavoritesCubit(
        mockGetFavorites,
        mockToggleFavorite,
        mockClearFavorites,
      );
      addTearDown(seeded.close);

      expect(
        seeded.state,
        const FavoritesLoaded(favorites: [tReciter], favoriteIds: {1}),
      );
    },
  );

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
    group('offline and persistence', () {
      blocTest<FavoritesCubit, FavoritesState>(
        'reverts optimistic add when persistence fails (signed-in offline)',
        build: () {
          when(
            mockToggleFavorite(any),
          ).thenAnswer((_) async => const Left(ServerFailure('offline')));
          return cubit;
        },
        seed: () => const FavoritesLoaded(favorites: [], favoriteIds: {}),
        act: (cubit) => cubit.toggleFavorite(tReciter),
        expect: () => [
          const FavoritesLoaded(favorites: [tReciter], favoriteIds: {1}),
          const FavoritesLoaded(favorites: [], favoriteIds: {}),
        ],
      );

      blocTest<FavoritesCubit, FavoritesState>(
        'keeps optimistic add when persistence succeeds after offline delay',
        build: () {
          when(mockToggleFavorite(any)).thenAnswer((_) async {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            return const Right(null);
          });
          return cubit;
        },
        seed: () => const FavoritesLoaded(favorites: [], favoriteIds: {}),
        act: (cubit) async {
          await cubit.toggleFavorite(tReciter);
          await Future<void>.delayed(const Duration(milliseconds: 100));
        },
        expect: () => [
          const FavoritesLoaded(favorites: [tReciter], favoriteIds: {1}),
        ],
      );
    });

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
      'reverts optimistic state on failure without reloading',
      build: () {
        when(
          mockToggleFavorite(any),
        ).thenAnswer((_) async => const Left(ServerFailure('Fail')));
        return cubit;
      },
      seed: () => const FavoritesLoaded(favorites: [], favoriteIds: {}),
      act: (cubit) => cubit.toggleFavorite(tReciter),
      expect: () => [
        const FavoritesLoaded(favorites: [tReciter], favoriteIds: {1}),
        const FavoritesLoaded(favorites: [], favoriteIds: {}),
      ],
      verify: (_) {
        verifyNever(mockGetFavorites(any));
      },
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
      'reverts optimistic removal on failure without reloading',
      build: () {
        when(
          mockToggleFavorite(any),
        ).thenAnswer((_) async => const Left(ServerFailure('Fail')));
        return cubit;
      },
      seed: () =>
          const FavoritesLoaded(favorites: [tReciter], favoriteIds: {1}),
      act: (cubit) => cubit.toggleFavorite(tReciter),
      expect: () => [
        const FavoritesLoaded(
          favorites: [],
          favoriteIds: {},
          removedReciter: tReciter,
        ),
        const FavoritesLoaded(favorites: [tReciter], favoriteIds: {1}),
      ],
      verify: (_) {
        verifyNever(mockGetFavorites(any));
      },
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
      'optimistically emits loaded state when favorites are not loaded yet',
      build: () {
        when(
          mockToggleFavorite(any),
        ).thenAnswer((_) async => const Right(null));
        return cubit;
      },
      act: (cubit) => cubit.toggleFavorite(tReciter),
      expect: () => [
        const FavoritesLoaded(favorites: [tReciter], favoriteIds: {1}),
      ],
      verify: (_) {
        expect(
          cubit.state,
          const FavoritesLoaded(favorites: [tReciter], favoriteIds: {1}),
        );
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

  group('applyCatalogOrder', () {
    const tReciter2 = ReciterEntity(
      id: 2,
      name: 'Second',
      letter: 'S',
      date: '2023',
      moshaf: [],
    );
    const tReciter3 = ReciterEntity(
      id: 3,
      name: 'Third',
      letter: 'T',
      date: '2023',
      moshaf: [],
    );
    const catalog = [tReciter, tReciter2, tReciter3];

    test('reorders favorites to match catalog without fetching', () async {
      when(mockGetFavorites(any)).thenAnswer(
        (_) async => const Right(<ReciterEntity>[tReciter2]),
      );
      when(mockToggleFavorite(any)).thenAnswer(
        (_) async => const Right(null),
      );
      await cubit.loadFavorites();
      await cubit.toggleFavorite(tReciter);

      final FavoritesLoaded optimistic = cubit.state as FavoritesLoaded;
      expect(optimistic.favorites.map((r) => r.id).toList(), [2, 1]);

      cubit.applyCatalogOrder(catalog);

      final FavoritesLoaded reordered = cubit.state as FavoritesLoaded;
      expect(reordered.favorites.map((r) => r.id).toList(), [1, 2]);
      expect(reordered.favoriteIds, {1, 2});
    });

    test('does not emit when order already matches catalog', () async {
      when(mockGetFavorites(any)).thenAnswer(
        (_) async => const Right(<ReciterEntity>[tReciter, tReciter2]),
      );
      await cubit.loadFavorites();

      final List<FavoritesState> states = <FavoritesState>[];
      final subscription = cubit.stream.listen(states.add);

      cubit.applyCatalogOrder(catalog);
      await Future<void>.delayed(Duration.zero);

      expect(states, isEmpty);
      await subscription.cancel();
    });
  });
}

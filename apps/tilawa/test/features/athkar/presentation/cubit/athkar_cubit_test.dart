import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import 'package:tilawa_core/utils/typedefs.dart';
import 'package:tilawa/features/athkar/data/datasources/athkar_daily_progress_local_datasource.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_category.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_item.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_athkar_by_category_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_athkar_categories_use_case.dart';
import 'package:tilawa/features/athkar/presentation/cubit/athkar_cubit.dart';
import 'package:tilawa/features/athkar/presentation/cubit/athkar_state.dart';

import 'athkar_cubit_test.mocks.dart';

@GenerateMocks([GetAthkarCategoriesUseCase, GetAthkarByCategoryUseCase])
void main() {
  late AthkarCubit cubit;
  late MockGetAthkarCategoriesUseCase mockGetCategories;
  late MockGetAthkarByCategoryUseCase mockGetAthkarByCategory;
  late _FakeAthkarDailyProgressLocalDataSource fakeProgress;

  setUp(() {
    provideDummy<ResultFuture<List<AthkarCategory>>>(
      Future.value(const Right([])),
    );
    provideDummy<ResultFuture<List<AthkarItem>>>(Future.value(const Right([])));
    provideDummy<Either<Failure, List<AthkarCategory>>>(const Right([]));
    provideDummy<Either<Failure, List<AthkarItem>>>(const Right([]));

    mockGetCategories = MockGetAthkarCategoriesUseCase();
    mockGetAthkarByCategory = MockGetAthkarByCategoryUseCase();
    fakeProgress = _FakeAthkarDailyProgressLocalDataSource();
    cubit = AthkarCubit(
      mockGetCategories,
      mockGetAthkarByCategory,
      fakeProgress,
    );
  });

  tearDown(() {
    cubit.close();
  });

  const tCategories = [
    AthkarCategory(
      id: 1,
      nameAr: 'أذكار الصباح',
      nameEn: 'Morning Athkar',
      icon: 'wb_sunny_rounded',
    ),
  ];

  const tAthkarItem = AthkarItem(
    id: 1,
    categoryId: 1,
    textAr: 'Test Ar',
    textEn: 'Test En',
    count: 3,
    reference: 'Test Ref',
  );

  final tAthkarItems = [tAthkarItem];

  group('loadCategories', () {
    blocTest<AthkarCubit, AthkarState>(
      'emits [AthkarLoading, AthkarCategoriesLoaded] when loadCategories is successful',
      build: () {
        when(
          mockGetCategories(any),
        ).thenAnswer((_) async => const Right(tCategories));
        return cubit;
      },
      act: (cubit) => cubit.loadCategories(),
      expect: () => [
        const AthkarLoading(),
        const AthkarCategoriesLoaded(tCategories),
      ],
      verify: (_) {
        verify(mockGetCategories(const NoParams()));
      },
    );

    blocTest<AthkarCubit, AthkarState>(
      'emits [AthkarLoading, AthkarError] when loadCategories fails',
      build: () {
        when(
          mockGetCategories(any),
        ).thenAnswer((_) async => const Left(ServerFailure('Server Error')));
        return cubit;
      },
      act: (cubit) => cubit.loadCategories(),
      expect: () => [
        const AthkarLoading(),
        const AthkarError(ServerFailure('Server Error')),
      ],
    );
  });

  group('loadAthkar', () {
    blocTest<AthkarCubit, AthkarState>(
      'emits [AthkarLoading, AthkarItemsLoaded] when loadAthkar is successful',
      build: () {
        when(
          mockGetAthkarByCategory(any),
        ).thenAnswer((_) async => Right(tAthkarItems));
        return cubit;
      },
      act: (cubit) => cubit.loadAthkar(1),
      expect: () => [
        const AthkarLoading(),
        AthkarItemsLoaded(
          items: tAthkarItems,
          currentCounts: const {1: 3},
          resumeIndex: 0,
        ),
      ],
      verify: (_) {
        verify(mockGetAthkarByCategory(1));
      },
    );

    blocTest<AthkarCubit, AthkarState>(
      'emits [AthkarLoading, AthkarError] when loadAthkar fails',
      build: () {
        when(
          mockGetAthkarByCategory(any),
        ).thenAnswer((_) async => const Left(ServerFailure('Server Error')));
        return cubit;
      },
      act: (cubit) => cubit.loadAthkar(1),
      expect: () => [
        const AthkarLoading(),
        const AthkarError(ServerFailure('Server Error')),
      ],
    );

    blocTest<AthkarCubit, AthkarState>(
      'restores saved counts and resumeIndex when restoreProgress is true',
      build: () {
        fakeProgress.savedCounts = const {1: 1};
        when(
          mockGetAthkarByCategory(any),
        ).thenAnswer((_) async => Right(tAthkarItems));
        return cubit;
      },
      act: (cubit) => cubit.loadAthkar(1, restoreProgress: true),
      expect: () => [
        const AthkarLoading(),
        AthkarItemsLoaded(
          items: tAthkarItems,
          currentCounts: const {1: 1},
          resumeIndex: 0,
        ),
      ],
      verify: (_) {
        expect(fakeProgress.saveCalls, 0);
      },
    );

    blocTest<AthkarCubit, AthkarState>(
      'fresh load overwrites saved progress',
      build: () {
        fakeProgress.savedCounts = const {1: 1};
        when(
          mockGetAthkarByCategory(any),
        ).thenAnswer((_) async => Right(tAthkarItems));
        return cubit;
      },
      act: (cubit) => cubit.loadAthkar(1),
      expect: () => [
        const AthkarLoading(),
        AthkarItemsLoaded(
          items: tAthkarItems,
          currentCounts: const {1: 3},
          resumeIndex: 0,
        ),
      ],
      verify: (_) {
        expect(fakeProgress.saveCalls, 1);
        expect(fakeProgress.savedCounts, const {1: 3});
      },
    );

    test('resumeIndexForCounts selects first incomplete item', () {
      const items = [
        AthkarItem(
          id: 1,
          categoryId: 1,
          textAr: 'a',
          textEn: '',
          count: 3,
          reference: 'r',
        ),
        AthkarItem(
          id: 2,
          categoryId: 1,
          textAr: 'b',
          textEn: '',
          count: 2,
          reference: 'r',
        ),
      ];
      expect(
        AthkarCubit.resumeIndexForCounts(items, const {1: 0, 2: 2}),
        1,
      );
    });

    group('counter management', () {
      blocTest<AthkarCubit, AthkarState>(
        'decrements count correctly',
        build: () {
          return cubit;
        },
        seed: () => AthkarItemsLoaded(
          items: tAthkarItems,
          currentCounts: const {1: 3},
          resumeIndex: 0,
        ),
        act: (cubit) => cubit.decrementCount(1),
        expect: () => [
          AthkarItemsLoaded(items: tAthkarItems, currentCounts: const {1: 2}),
        ],
      );

      blocTest<AthkarCubit, AthkarState>(
        'does not decrement count below 0',
        build: () {
          return cubit;
        },
        seed: () =>
            AthkarItemsLoaded(items: tAthkarItems, currentCounts: const {1: 0}),
        act: (cubit) => cubit.decrementCount(1),
        expect: () => [],
      );

      blocTest<AthkarCubit, AthkarState>(
        'resets count correctly',
        build: () {
          return cubit;
        },
        seed: () =>
            AthkarItemsLoaded(items: tAthkarItems, currentCounts: const {1: 1}),
        act: (cubit) => cubit.resetCount(1),
        expect: () => [
          AthkarItemsLoaded(
            items: tAthkarItems,
            currentCounts: const {1: 3},
            resumeIndex: 0,
          ),
        ],
      );
    });
  });
}

class _FakeAthkarDailyProgressLocalDataSource
    implements AthkarDailyProgressLocalDataSource {
  Map<int, int> savedCounts = const {};
  int saveCalls = 0;

  @override
  Future<Map<int, int>> loadCounts({
    required int categoryId,
    required String dateKey,
  }) async => savedCounts;

  @override
  Future<void> saveCounts({
    required int categoryId,
    required String dateKey,
    required Map<int, int> remainingCounts,
  }) async {
    saveCalls += 1;
    savedCounts = Map<int, int>.from(remainingCounts);
  }
}

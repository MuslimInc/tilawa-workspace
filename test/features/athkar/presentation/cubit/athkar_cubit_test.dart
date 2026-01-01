import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/core/services/analytics_service.dart';
import 'package:tilawa/core/usecases/usecase.dart';
import 'package:tilawa/core/utils/typedefs.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_category.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_item.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_athkar_by_category_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_athkar_categories_use_case.dart';
import 'package:tilawa/features/athkar/presentation/cubit/athkar_cubit.dart';
import 'package:tilawa/features/athkar/presentation/cubit/athkar_state.dart';

import 'athkar_cubit_test.mocks.dart';

@GenerateMocks([
  GetAthkarCategoriesUseCase,
  GetAthkarByCategoryUseCase,
  AnalyticsService,
])
void main() {
  late AthkarCubit cubit;
  late MockGetAthkarCategoriesUseCase mockGetCategories;
  late MockGetAthkarByCategoryUseCase mockGetAthkarByCategory;
  late MockAnalyticsService mockAnalyticsService;

  setUp(() {
    provideDummy<ResultFuture<List<AthkarCategory>>>(
      Future.value(const Right([])),
    );
    provideDummy<ResultFuture<List<AthkarItem>>>(Future.value(const Right([])));
    provideDummy<Either<Failure, List<AthkarCategory>>>(const Right([]));
    provideDummy<Either<Failure, List<AthkarItem>>>(const Right([]));

    mockGetCategories = MockGetAthkarCategoriesUseCase();
    mockGetAthkarByCategory = MockGetAthkarByCategoryUseCase();
    mockAnalyticsService = MockAnalyticsService();
    cubit = AthkarCubit(
      mockGetCategories,
      mockGetAthkarByCategory,
      mockAnalyticsService,
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
        AthkarLoading(),
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
      expect: () => [AthkarLoading(), const AthkarError('Server Error')],
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
        AthkarLoading(),
        AthkarItemsLoaded(items: tAthkarItems, currentCounts: const {1: 3}),
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
      expect: () => [AthkarLoading(), const AthkarError('Server Error')],
    );
    group('counter management', () {
      blocTest<AthkarCubit, AthkarState>(
        'decrements count correctly',
        build: () {
          return cubit;
        },
        seed: () =>
            AthkarItemsLoaded(items: tAthkarItems, currentCounts: const {1: 3}),
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
          AthkarItemsLoaded(items: tAthkarItems, currentCounts: const {1: 3}),
        ],
      );
    });
  });
}

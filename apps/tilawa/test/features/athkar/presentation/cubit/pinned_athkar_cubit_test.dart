import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_category.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_item.dart';
import 'package:tilawa/features/athkar/domain/entities/pinned_athkar_preference.dart';
import 'package:tilawa/features/athkar/domain/repositories/athkar_repository.dart';
import 'package:tilawa/features/athkar/domain/repositories/pinned_athkar_repository.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_athkar_categories_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_pinned_athkar_preference_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/save_pinned_athkar_category_ids_use_case.dart';
import 'package:tilawa/features/athkar/presentation/cubit/pinned_athkar_cubit.dart';
import 'package:tilawa/features/athkar/presentation/cubit/pinned_athkar_state.dart';
import 'package:tilawa_core/utils/typedefs.dart';

void main() {
  group('PinnedAthkarCubit', () {
    late _FakeAthkarRepository athkarRepository;
    late _FakePinnedAthkarRepository pinnedRepository;

    PinnedAthkarCubit buildCubit() {
      return PinnedAthkarCubit(
        GetAthkarCategoriesUseCase(athkarRepository),
        GetPinnedAthkarPreferenceUseCase(pinnedRepository),
        SavePinnedAthkarCategoryIdsUseCase(pinnedRepository),
      );
    }

    setUp(() {
      athkarRepository = _FakeAthkarRepository();
      pinnedRepository = _FakePinnedAthkarRepository();
    });

    blocTest<PinnedAthkarCubit, PinnedAthkarState>(
      'loads default pinned categories until customized',
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        const PinnedAthkarState(status: PinnedAthkarStatus.loading),
        PinnedAthkarState(
          status: PinnedAthkarStatus.ready,
          categories: _categories,
          pinnedCategoryIds: const [1, 2],
        ),
      ],
    );

    blocTest<PinnedAthkarCubit, PinnedAthkarState>(
      'adds, removes, and persists selected categories',
      build: buildCubit,
      seed: () => PinnedAthkarState(
        status: PinnedAthkarStatus.ready,
        categories: _categories,
        pinnedCategoryIds: const [1, 2],
      ),
      act: (cubit) => cubit.toggleCategory(3),
      expect: () => [
        PinnedAthkarState(
          status: PinnedAthkarStatus.saving,
          categories: _categories,
          pinnedCategoryIds: const [1, 2, 3],
          isCustomized: true,
        ),
        PinnedAthkarState(
          status: PinnedAthkarStatus.ready,
          categories: _categories,
          pinnedCategoryIds: const [1, 2, 3],
          isCustomized: true,
        ),
      ],
      verify: (_) {
        expect(pinnedRepository.savedCategoryIds, [1, 2, 3]);
      },
    );

    blocTest<PinnedAthkarCubit, PinnedAthkarState>(
      'reorders pinned category IDs',
      build: buildCubit,
      seed: () => PinnedAthkarState(
        status: PinnedAthkarStatus.ready,
        categories: _categories,
        pinnedCategoryIds: const [1, 2, 3],
      ),
      act: (cubit) => cubit.movePinnedCategory(oldIndex: 2, newIndex: 0),
      expect: () => [
        PinnedAthkarState(
          status: PinnedAthkarStatus.saving,
          categories: _categories,
          pinnedCategoryIds: const [3, 1, 2],
          isCustomized: true,
        ),
        PinnedAthkarState(
          status: PinnedAthkarStatus.ready,
          categories: _categories,
          pinnedCategoryIds: const [3, 1, 2],
          isCustomized: true,
        ),
      ],
      verify: (_) {
        expect(pinnedRepository.savedCategoryIds, [3, 1, 2]);
      },
    );
  });
}

const _categories = [
  AthkarCategory(
    id: 1,
    nameAr: 'أذكار الصباح',
    nameEn: 'Morning Athkar',
    icon: 'wb_sunny_rounded',
  ),
  AthkarCategory(
    id: 2,
    nameAr: 'أذكار المساء',
    nameEn: 'Evening Athkar',
    icon: 'nights_stay_rounded',
  ),
  AthkarCategory(
    id: 3,
    nameAr: 'أذكار النوم',
    nameEn: 'Sleep Athkar',
    icon: 'bedtime_rounded',
  ),
];

class _FakeAthkarRepository implements AthkarRepository {
  @override
  ResultFuture<List<AthkarCategory>> getCategories() async {
    return const Right(_categories);
  }

  @override
  ResultFuture<List<AthkarItem>> getAthkarByCategory(int categoryId) async {
    return const Right([]);
  }
}

class _FakePinnedAthkarRepository implements PinnedAthkarRepository {
  List<int>? savedCategoryIds;

  @override
  ResultFuture<PinnedAthkarPreference> getPreference() async {
    return const Right(
      PinnedAthkarPreference(categoryIds: [1, 2], isCustomized: false),
    );
  }

  @override
  ResultVoid saveCategoryIds(List<int> categoryIds) async {
    savedCategoryIds = categoryIds;
    return const Right(null);
  }
}

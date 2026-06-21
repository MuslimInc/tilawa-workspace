import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/athkar/data/datasources/pinned_athkar_local_datasource.dart';
import 'package:tilawa/features/athkar/data/repositories/pinned_athkar_repository_impl.dart';
import 'package:tilawa/features/athkar/domain/constants/pinned_athkar_constants.dart';

void main() {
  group('PinnedAthkarRepositoryImpl', () {
    late _FakePinnedAthkarLocalDataSource dataSource;
    late PinnedAthkarRepositoryImpl repository;

    setUp(() {
      dataSource = _FakePinnedAthkarLocalDataSource();
      repository = PinnedAthkarRepositoryImpl(dataSource);
    });

    test('returns curated defaults before the user customizes pins', () async {
      final result = await repository.getPreference();

      expect(result.isRight(), isTrue);
      final preference = result.getOrElse(
        () => throw StateError('Expected preference'),
      );
      expect(
        preference.categoryIds,
        PinnedAthkarConstants.defaultCategoryIds,
      );
      expect(preference.isCustomized, isFalse);
    });

    test('sanitizes and persists user-selected category IDs', () async {
      final result = await repository.saveCategoryIds([1, 2, 2, -1, 3, 4, 5]);

      expect(result.isRight(), isTrue);
      expect(dataSource.writtenCategoryIds, [1, 2, 3, 4]);
    });
  });
}

class _FakePinnedAthkarLocalDataSource implements PinnedAthkarLocalDataSource {
  List<int>? categoryIds;
  List<int>? writtenCategoryIds;

  @override
  Future<List<int>?> readCategoryIds() async => categoryIds;

  @override
  Future<void> writeCategoryIds(List<int> categoryIds) async {
    writtenCategoryIds = categoryIds;
    this.categoryIds = categoryIds;
  }
}

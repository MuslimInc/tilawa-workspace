import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/utils/typedefs.dart';

import '../../domain/constants/pinned_athkar_constants.dart';
import '../../domain/entities/pinned_athkar_preference.dart';
import '../../domain/repositories/pinned_athkar_repository.dart';
import '../datasources/pinned_athkar_local_datasource.dart';

@LazySingleton(as: PinnedAthkarRepository)
class PinnedAthkarRepositoryImpl implements PinnedAthkarRepository {
  PinnedAthkarRepositoryImpl(this._localDataSource);

  final PinnedAthkarLocalDataSource _localDataSource;

  @override
  ResultFuture<PinnedAthkarPreference> getPreference() async {
    try {
      final List<int>? categoryIds = await _localDataSource.readCategoryIds();
      if (categoryIds == null) {
        return const Right(
          PinnedAthkarPreference(
            categoryIds: PinnedAthkarConstants.defaultCategoryIds,
            isCustomized: false,
          ),
        );
      }
      return Right(
        PinnedAthkarPreference(
          categoryIds: _sanitize(categoryIds),
          isCustomized: true,
        ),
      );
    } on Exception catch (error) {
      return Left(PersistenceFailure(error.toString()));
    }
  }

  @override
  ResultVoid saveCategoryIds(List<int> categoryIds) async {
    try {
      await _localDataSource.writeCategoryIds(_sanitize(categoryIds));
      return const Right(null);
    } on Exception catch (error) {
      return Left(PersistenceFailure(error.toString()));
    }
  }

  List<int> _sanitize(List<int> categoryIds) {
    final seen = <int>{};
    return [
      for (final int id in categoryIds)
        if (id > 0 && seen.add(id)) id,
    ].take(PinnedAthkarConstants.maxPinnedCategories).toList(growable: false);
  }
}

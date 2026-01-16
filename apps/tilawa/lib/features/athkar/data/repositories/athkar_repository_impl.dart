import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import 'package:tilawa_core/utils/typedefs.dart';
import '../../domain/entities/athkar_category.dart';
import '../../domain/entities/athkar_item.dart';
import '../../domain/repositories/athkar_repository.dart';
import '../datasources/athkar_local_datasource.dart';
import '../models/athkar_category_model.dart';
import '../models/athkar_item_model.dart';

@LazySingleton(as: AthkarRepository)
class AthkarRepositoryImpl implements AthkarRepository {
  AthkarRepositoryImpl(this._localDataSource, this._analyticsService);
  final AthkarLocalDataSource _localDataSource;
  final AnalyticsService _analyticsService;

  @override
  ResultFuture<List<AthkarCategory>> getCategories() async {
    try {
      final List<AthkarCategoryModel> categories = await _localDataSource
          .getCategories();

      // [MODIFIED] Log analytics event
      await _analyticsService.logEvent(
        AnalyticsEvents.athkarCategoriesLoaded,
        parameters: {AnalyticsParams.count: categories.length},
      );

      return Right(categories);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<AthkarItem>> getAthkarByCategory(int categoryId) async {
    try {
      final List<AthkarItemModel> athkar = await _localDataSource
          .getAthkarByCategory(categoryId);

      // [MODIFIED] Log analytics event
      await _analyticsService.logEvent(
        AnalyticsEvents.athkarItemsLoaded,
        parameters: {
          AnalyticsParams.categoryId: categoryId,
          AnalyticsParams.count: athkar.length,
        },
      );

      return Right(athkar);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

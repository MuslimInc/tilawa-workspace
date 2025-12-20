import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/athkar_category.dart';
import '../../domain/entities/athkar_item.dart';
import '../../domain/repositories/athkar_repository.dart';
import '../datasources/athkar_local_datasource.dart';
import '../models/athkar_category_model.dart';
import '../models/athkar_item_model.dart';

@LazySingleton(as: AthkarRepository)
class AthkarRepositoryImpl implements AthkarRepository {
  AthkarRepositoryImpl(this._localDataSource);
  final AthkarLocalDataSource _localDataSource;

  @override
  ResultFuture<List<AthkarCategory>> getCategories() async {
    try {
      final List<AthkarCategoryModel> categories = await _localDataSource
          .getCategories();
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
      return Right(athkar);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

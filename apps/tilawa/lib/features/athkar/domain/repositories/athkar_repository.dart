import 'package:tilawa_core/utils/typedefs.dart';
import '../entities/athkar_category.dart';
import '../entities/athkar_item.dart';

abstract class AthkarRepository {
  ResultFuture<List<AthkarCategory>> getCategories();
  ResultFuture<List<AthkarItem>> getAthkarByCategory(int categoryId);
}

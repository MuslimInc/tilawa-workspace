import '../../../../core/entities/reciter_entity.dart';
import '../../../../core/utils/typedefs.dart';

abstract class RecitersRepository {
  ResultFuture<List<ReciterEntity>> getReciters();
  ResultFuture<List<ReciterEntity>> searchReciters(String query);
  ResultFuture<List<ReciterEntity>> getRecitersByLetter(String letter);
  ResultFuture<ReciterEntity?> getReciterById(String id);

  // Favorites
  ResultFuture<List<ReciterEntity>> getFavoriteReciters();
  ResultFuture<void> toggleFavoriteReciter(int id);
  ResultFuture<List<String>> getFavoriteReciterIds();
}

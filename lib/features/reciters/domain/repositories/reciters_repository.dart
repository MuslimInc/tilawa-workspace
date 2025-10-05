import 'package:muzakri/core/entities/reciter.dart';
import 'package:muzakri/core/utils/typedefs.dart';

abstract class RecitersRepository {
  ResultFuture<List<ReciterEntity>> getReciters();
  ResultFuture<List<ReciterEntity>> searchReciters(String query);
  ResultFuture<List<ReciterEntity>> getRecitersByLetter(String letter);
}

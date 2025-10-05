import 'package:dartz/dartz.dart';
import 'package:muzakri/core/entities/reciter.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/core/utils/typedefs.dart';
import 'package:muzakri/features/reciters/data/datasources/reciters_remote_datasource.dart';
import 'package:muzakri/features/reciters/data/models/reciter_model.dart';
import 'package:muzakri/features/reciters/domain/repositories/reciters_repository.dart';

class RecitersRepositoryImpl implements RecitersRepository {
  const RecitersRepositoryImpl(this._remoteDataSource);

  final RecitersRemoteDataSource _remoteDataSource;

  @override
  ResultFuture<List<ReciterEntity>> getReciters() async {
    try {
      final reciters = await _remoteDataSource.getReciters();
      return Right(reciters.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<ReciterEntity>> searchReciters(String query) async {
    try {
      final allReciters = await _remoteDataSource.getReciters();
      final filteredReciters = allReciters
          .where(
            (reciter) =>
                reciter.name.toLowerCase().contains(query.toLowerCase()),
          )
          .map((model) => model.toEntity())
          .toList();
      return Right(filteredReciters);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<ReciterEntity>> getRecitersByLetter(String letter) async {
    try {
      final allReciters = await _remoteDataSource.getReciters();
      final filteredReciters = allReciters
          .where((reciter) => reciter.letter == letter)
          .map((model) => model.toEntity())
          .toList();
      return Right(filteredReciters);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

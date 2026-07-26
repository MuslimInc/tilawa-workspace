import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/utils/typedefs.dart';

import '../../domain/entities/dedication.dart';
import '../../domain/repositories/dedications_repository.dart';
import '../datasources/dedications_remote_data_source.dart';

@LazySingleton(as: DedicationsRepository)
class DedicationsRepositoryImpl implements DedicationsRepository {
  DedicationsRepositoryImpl(this._remote);

  final DedicationsRemoteDataSource _remote;

  @override
  ResultFuture<List<Dedication>> getPublishedDedications() async {
    try {
      final List<Dedication> list = await _remote.getPublishedDedications();
      return Right(list);
    } on Object catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }
}

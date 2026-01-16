import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import '../repositories/downloads_repository.dart';

@lazySingleton
class GetTotalDownloadsSizeUseCase implements UseCase<int, NoParams> {
  GetTotalDownloadsSizeUseCase(this.repository);

  final DownloadsRepository repository;

  @override
  Future<Either<Failure, int>> call(NoParams params) async {
    try {
      final int size = await repository.getTotalDownloadsSize();
      return Right(size);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}

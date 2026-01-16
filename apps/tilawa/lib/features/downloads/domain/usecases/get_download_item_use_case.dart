import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import '../entities/download_item.dart';
import '../repositories/downloads_repository.dart';

@lazySingleton
class GetDownloadItemUseCase implements UseCase<DownloadItem?, String> {
  GetDownloadItemUseCase(this._repository);
  final DownloadsRepository _repository;

  @override
  Future<Either<Failure, DownloadItem?>> call(String id) async {
    try {
      final DownloadItem? result = await _repository.getDownloadItem(id);
      return Right(result);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}

import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/download_item.dart';
import '../repositories/downloads_repository.dart';

@lazySingleton
class GetValidCompletedDownloadsUseCase
    implements UseCase<List<DownloadItem>, String> {
  GetValidCompletedDownloadsUseCase(this._repository);
  final DownloadsRepository _repository;

  @override
  Future<Either<Failure, List<DownloadItem>>> call(String reciterName) async {
    try {
      final List<DownloadItem> results = await _repository
          .getValidCompletedDownloads(reciterName);
      return Right(results);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}

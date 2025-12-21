import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/download_item.dart';
import '../repositories/downloads_repository.dart';

@lazySingleton
class ValidateDownloadedFileUseCase implements UseCase<bool, DownloadItem> {
  ValidateDownloadedFileUseCase(this._repository);
  final DownloadsRepository _repository;

  @override
  Future<Either<Failure, bool>> call(DownloadItem downloadItem) async {
    try {
      final bool isValid = await _repository.validateDownloadedFile(
        downloadItem,
      );
      return Right(isValid);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}

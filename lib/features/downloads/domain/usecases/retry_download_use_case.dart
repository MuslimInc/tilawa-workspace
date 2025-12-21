import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/downloads_repository.dart';

@lazySingleton
class RetryDownloadUseCase implements UseCase<void, String> {
  RetryDownloadUseCase(this._repository);
  final DownloadsRepository _repository;

  @override
  Future<Either<Failure, void>> call(String downloadId) async {
    try {
      await _repository.retryDownload(downloadId);
      return const Right(null);
    } catch (e) {
      // Assuming generic failure for now, ideally repository should throw standardized failures
      return Left(ServerFailure(e.toString()));
    }
  }
}

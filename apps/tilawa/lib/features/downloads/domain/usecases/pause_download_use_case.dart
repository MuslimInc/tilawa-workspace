import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../repositories/downloads_repository.dart';

@lazySingleton
class PauseDownloadUseCase {
  PauseDownloadUseCase(this._repository);

  final DownloadsRepository _repository;

  Future<Either<Failure, void>> call(String id) async {
    try {
      await _repository.pauseDownload(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to pause download: $e'));
    }
  }
}

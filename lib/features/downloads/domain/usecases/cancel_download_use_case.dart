import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/downloads_repository.dart';

@injectable
class CancelDownloadUseCase implements UseCase<void, String> {
  CancelDownloadUseCase(this._repository);

  final DownloadsRepository _repository;

  @override
  Future<Either<Failure, void>> call(String downloadId) async {
    try {
      await _repository.cancelDownload(downloadId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

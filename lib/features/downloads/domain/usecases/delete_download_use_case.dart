import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/typedefs.dart';
import '../repositories/downloads_repository.dart';

@Singleton()
class DeleteDownloadUseCase {
  const DeleteDownloadUseCase(this._repository);

  final DownloadsRepository _repository;

  ResultFuture<void> call(String downloadId) async {
    try {
      await _repository.deleteDownload(downloadId);
      return const Right(null);
    } catch (e) {
      return Left(AudioFailure(e.toString()));
    }
  }
}

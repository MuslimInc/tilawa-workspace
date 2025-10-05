import 'package:dartz/dartz.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/core/utils/typedefs.dart';
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart';

class DeleteDownload {
  const DeleteDownload(this._repository);

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

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/core/utils/typedefs.dart';
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart';

@Singleton()
class CheckSurahDownloadedUseCase {
  const CheckSurahDownloadedUseCase(this._repository);

  final DownloadsRepository _repository;

  ResultFuture<bool> call({
    required String surahId,
    required String reciterName,
  }) async {
    try {
      final isDownloaded = await _repository.isSurahDownloaded(
        surahId,
        reciterName,
      );
      return Right(isDownloaded);
    } catch (e) {
      return Left(AudioFailure(e.toString()));
    }
  }
}

import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/typedefs.dart';
import '../repositories/downloads_repository.dart';

@Singleton()
class CheckSurahDownloadedUseCase {
  const CheckSurahDownloadedUseCase(this._repository);

  final DownloadsRepository _repository;

  ResultFuture<bool> call({
    required String surahId,
    required String reciterName,
  }) async {
    try {
      final bool isDownloaded = await _repository.isSurahDownloaded(
        surahId,
        reciterName,
      );
      return Right(isDownloaded);
    } catch (e) {
      return Left(AudioFailure(e.toString()));
    }
  }
}

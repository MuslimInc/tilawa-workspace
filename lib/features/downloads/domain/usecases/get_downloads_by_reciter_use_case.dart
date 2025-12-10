import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../entities/download_item.dart';
import '../repositories/downloads_repository.dart';

@Singleton()
class GetDownloadsByReciterUseCase {
  const GetDownloadsByReciterUseCase(this._repository);

  final DownloadsRepository _repository;

  Future<Either<Failure, Map<String, Map<String, List<DownloadItem>>>>>
  call() async {
    try {
      final Map<String, Map<String, List<DownloadItem>>> downloads =
          await _repository.getDownloadsByReciter();
      return Right(downloads);
    } catch (e) {
      return Left(AudioFailure(e.toString()));
    }
  }
}

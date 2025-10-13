import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart';

@Singleton()
class GetDownloadsByReciterUseCase {
  const GetDownloadsByReciterUseCase(this._repository);

  final DownloadsRepository _repository;

  Future<Either<Failure, Map<String, List<DownloadItem>>>> call() async {
    try {
      final downloads = await _repository.getDownloadsByReciter();
      return Right(downloads);
    } catch (e) {
      return Left(AudioFailure(e.toString()));
    }
  }
}

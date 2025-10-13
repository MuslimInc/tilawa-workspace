import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/core/utils/typedefs.dart';
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart';

@Singleton()
class ClearAllDownloadsUseCase {
  const ClearAllDownloadsUseCase(this._repository);

  final DownloadsRepository _repository;

  ResultFuture<void> call() async {
    try {
      await _repository.clearAllDownloads();
      return const Right(null);
    } catch (e) {
      return Left(AudioFailure(e.toString()));
    }
  }
}

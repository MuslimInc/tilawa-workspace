import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/core/utils/typedefs.dart';
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart';

@Singleton()
class DeleteReciterDownloadsUseCase {
  const DeleteReciterDownloadsUseCase(this._repository);

  final DownloadsRepository _repository;

  ResultFuture<void> call(String reciterName) async {
    try {
      await _repository.deleteDownloadsForReciter(reciterName);
      return const Right(null);
    } catch (e) {
      return Left(AudioFailure(e.toString()));
    }
  }
}

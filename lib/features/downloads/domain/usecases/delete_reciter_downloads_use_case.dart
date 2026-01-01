import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/downloads_repository.dart';

@injectable
class DeleteReciterDownloadsUseCase {
  const DeleteReciterDownloadsUseCase(this._repository);

  final DownloadsRepository _repository;

  Future<Either<Failure, void>> call(String reciterName) async {
    try {
      // 1. Delete reciter downloads via repository (includes analytics)
      await _repository.deleteReciterDownloads(reciterName);

      return const Right(null);
    } catch (e) {
      return Left(AudioFailure(e.toString()));
    }
  }
}

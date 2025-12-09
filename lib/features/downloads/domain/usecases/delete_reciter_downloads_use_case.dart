import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/typedefs.dart';
import '../repositories/downloads_repository.dart';

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

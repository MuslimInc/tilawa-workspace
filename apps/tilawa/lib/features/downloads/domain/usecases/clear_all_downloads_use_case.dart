import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/utils/typedefs.dart';
import '../repositories/downloads_repository.dart';

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

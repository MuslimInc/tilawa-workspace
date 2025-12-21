import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/downloads_repository.dart';

@injectable
class CancelDownloadsForReciterUseCase implements UseCase<void, String> {
  CancelDownloadsForReciterUseCase(this._repository);

  final DownloadsRepository _repository;

  @override
  Future<Either<Failure, void>> call(String reciterName) async {
    try {
      await _repository.cancelDownloadsForReciter(reciterName);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

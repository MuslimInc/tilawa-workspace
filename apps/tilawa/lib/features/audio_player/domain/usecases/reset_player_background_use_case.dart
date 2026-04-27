import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';
import '../repositories/player_background_repository.dart';

@injectable
class ResetPlayerBackgroundUseCase {
  const ResetPlayerBackgroundUseCase(this._repository);

  final PlayerBackgroundRepository _repository;

  Future<Either<Failure, void>> call(String? currentImagePath) async {
    try {
      if (currentImagePath != null) {
        await _repository.deleteImage(currentImagePath);
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}

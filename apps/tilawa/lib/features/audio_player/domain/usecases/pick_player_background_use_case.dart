import 'package:dartz_plus/dartz_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';
import '../repositories/player_background_repository.dart';

@injectable
class PickPlayerBackgroundUseCase {
  const PickPlayerBackgroundUseCase(this._repository);

  final PlayerBackgroundRepository _repository;

  Future<Either<Failure, String>> call(ImageSource source) async {
    try {
      final String? imagePath = await _repository.pickImage(source);

      if (imagePath == null) {
        return const Left(UserCancelledFailure('No image selected'));
      }

      final String persistentPath = await _repository.persistImage(imagePath);
      return Right(persistentPath);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}

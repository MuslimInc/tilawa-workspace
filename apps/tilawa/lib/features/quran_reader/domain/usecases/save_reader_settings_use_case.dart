import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/core.dart';
import '../entities/entities.dart';
import '../repositories/quran_reader_repository.dart';

class SaveReaderSettingsUseCase {
  SaveReaderSettingsUseCase(this._repository);

  final QuranReaderRepository _repository;

  Future<Either<Failure, void>> call({
    required ReaderSettingsEntity settings,
  }) async {
    try {
      await _repository.saveSettings(settings);
      return const Right(null);
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
}

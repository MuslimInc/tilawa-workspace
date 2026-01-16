import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/core.dart';
import '../entities/entities.dart';
import '../repositories/quran_reader_repository.dart';

@injectable
class LoadReaderSettingsUseCase {
  LoadReaderSettingsUseCase(this._repository);

  final QuranReaderRepository _repository;

  Future<Either<Failure, ReaderSettingsEntity>> call() async {
    try {
      final ReaderSettingsEntity settings = await _repository.loadSettings();
      return Right(settings);
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
}

import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/core.dart';
import '../repositories/quran_reader_repository.dart';

@injectable
class SaveLastReadPositionUseCase {
  SaveLastReadPositionUseCase(this._repository);

  final QuranReaderRepository _repository;

  Future<Either<Failure, void>> call({
    required int surahNumber,
    int? ayahNumber,
    int? page,
  }) async {
    try {
      await _repository.saveLastReadPosition(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        page: page,
      );
      return const Right(null);
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
}

import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/core.dart';
import '../entities/entities.dart';
import '../repositories/quran_reader_repository.dart';

@injectable
class GetSurahContentUseCase {
  GetSurahContentUseCase(this._repository);

  final QuranReaderRepository _repository;

  Future<Either<Failure, SurahContentEntity>> call({
    required int surahNumber,
  }) async {
    try {
      if (surahNumber < 1 || surahNumber > 114) {
        return Left(Failure.validationError('Invalid surah number'));
      }

      final SurahContentEntity surahContent = await _repository.getSurahContent(
        surahNumber,
      );
      return Right(surahContent);
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
}

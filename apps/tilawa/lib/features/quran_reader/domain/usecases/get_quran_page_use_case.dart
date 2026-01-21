import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/core.dart';
import '../entities/entities.dart';
import '../repositories/quran_reader_repository.dart';

@injectable
class GetQuranPageUseCase {
  GetQuranPageUseCase(this._repository);

  final QuranReaderRepository _repository;

  Future<Either<Failure, QuranPageEntity>> call({
    required int pageNumber,
  }) async {
    try {
      if (pageNumber < 1 || pageNumber > 604) {
        return Left(Failure.validationError('Invalid page number'));
      }

      final QuranPageEntity page = await _repository.getPage(pageNumber);
      return Right(page);
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
}

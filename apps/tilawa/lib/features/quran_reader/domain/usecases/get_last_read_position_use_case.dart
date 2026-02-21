import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/core.dart';

import '../repositories/quran_reader_repository.dart';

@injectable
class GetLastReadPositionUseCase {
  GetLastReadPositionUseCase(this._repository);

  final QuranReaderRepository _repository;

  Future<Either<Failure, ({int? surahNumber, int? ayahNumber, int? page})>>
  call() async {
    try {
      final result = await _repository.getLastReadPosition();
      return Right(result);
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
}

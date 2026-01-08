import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/core.dart';
import '../entities/entities.dart';
import '../repositories/quran_reader_repository.dart';

@injectable
class SearchSurahsUseCase {
  SearchSurahsUseCase(this._repository);

  final QuranReaderRepository _repository;

  Future<Either<Failure, List<SurahContentEntity>>> call({
    required String query,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return const Right([]);
      }

      final List<SurahContentEntity> surahs = await _repository.searchSurahs(
        query,
      );
      return Right(surahs);
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
}

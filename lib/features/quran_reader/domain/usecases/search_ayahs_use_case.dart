import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/core.dart';
import '../entities/entities.dart';
import '../repositories/quran_reader_repository.dart';

@injectable
class SearchAyahsUseCase {
  SearchAyahsUseCase(this._repository);

  final QuranReaderRepository _repository;

  Future<Either<Failure, List<AyahEntity>>> call({
    required String query,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return const Right([]);
      }

      final List<AyahEntity> ayahs = await _repository.searchAyahs(query);
      return Right(ayahs);
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
}

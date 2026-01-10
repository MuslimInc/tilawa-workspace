import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/entities.dart';
import '../repositories/quran_reader_repository.dart';

@lazySingleton
class GetAllPagesUseCase {
  GetAllPagesUseCase(this._repository);

  final QuranReaderRepository _repository;

  Future<Either<Failure, Map<int, QuranPageEntity>>> call() async {
    try {
      final Map<int, QuranPageEntity> pages = await _repository.getAllPages();
      return Right(pages);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}

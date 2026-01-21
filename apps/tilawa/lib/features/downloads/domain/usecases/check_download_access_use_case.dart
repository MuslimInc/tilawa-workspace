import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import '../../../premium/domain/repositories/premium_repository.dart';

@lazySingleton
class CheckDownloadAccessUseCase implements UseCase<bool, NoParams> {
  CheckDownloadAccessUseCase(this._premiumRepository);
  final PremiumRepository _premiumRepository;

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    try {
      final bool canDownload = await _premiumRepository.canDownload();
      return Right(canDownload);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

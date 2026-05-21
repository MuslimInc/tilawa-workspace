import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';

/// Downloads are free for all users; support is voluntary (no gating).
@lazySingleton
class CheckDownloadAccessUseCase implements UseCase<bool, NoParams> {
  const CheckDownloadAccessUseCase();

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return const Right(true);
  }
}

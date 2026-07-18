import 'package:injectable/injectable.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import 'package:tilawa_core/utils/typedefs.dart';

import '../entities/reel.dart';
import '../repositories/reels_repository.dart';

@lazySingleton
class GetSavedReelsUseCase extends UseCase<List<Reel>, NoParams> {
  GetSavedReelsUseCase(this._repository);

  final ReelsRepository _repository;

  @override
  ResultFuture<List<Reel>> call(NoParams params) => _repository.getSavedReels();
}

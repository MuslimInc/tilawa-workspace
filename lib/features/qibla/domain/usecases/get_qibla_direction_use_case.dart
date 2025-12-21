import 'package:injectable/injectable.dart';

import '../../../../core/usecases/usecase.dart';
import '../entities/qibla_direction_entity.dart';
import '../repositories/qibla_repository.dart';

@injectable
class GetQiblaDirectionUseCase
    extends StreamUseCase<QiblaDirectionEntity, NoParams> {
  GetQiblaDirectionUseCase(this._repository);
  final QiblaRepository _repository;

  @override
  Stream<QiblaDirectionEntity> call(NoParams params) {
    return _repository.getQiblaDirection();
  }
}

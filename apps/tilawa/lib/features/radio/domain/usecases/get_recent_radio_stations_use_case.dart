import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../entities/radio_station.dart';
import '../repositories/radio_repository.dart';

@lazySingleton
class GetRecentRadioStationsUseCase
    extends UseCase<List<RadioStation>, NoParams> {
  GetRecentRadioStationsUseCase(this._repository);

  final RadioRepository _repository;

  @override
  Future<Either<Failure, List<RadioStation>>> call(NoParams params) {
    return _repository.getRecentStations();
  }
}

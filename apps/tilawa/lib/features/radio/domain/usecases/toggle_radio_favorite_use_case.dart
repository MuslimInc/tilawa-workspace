import 'package:dartz_plus/dartz_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../entities/radio_station.dart';
import '../repositories/radio_repository.dart';

class ToggleRadioFavoriteParams extends Equatable {
  const ToggleRadioFavoriteParams(this.stationId);

  final String stationId;

  @override
  List<Object?> get props => [stationId];
}

@lazySingleton
class ToggleRadioFavoriteUseCase
    extends UseCase<RadioStation, ToggleRadioFavoriteParams> {
  ToggleRadioFavoriteUseCase(this._repository);

  final RadioRepository _repository;

  @override
  Future<Either<Failure, RadioStation>> call(ToggleRadioFavoriteParams params) {
    return _repository.toggleFavorite(params.stationId);
  }
}

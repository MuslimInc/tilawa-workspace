import 'package:dartz_plus/dartz_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../entities/radio_station.dart';
import '../repositories/radio_repository.dart';

class GetRadioStationsParams extends Equatable {
  const GetRadioStationsParams({required this.language});

  final String language;

  @override
  List<Object?> get props => [language];
}

@lazySingleton
class GetRadioStationsUseCase
    extends UseCase<List<RadioStation>, GetRadioStationsParams> {
  GetRadioStationsUseCase(this._repository);

  final RadioRepository _repository;

  @override
  Future<Either<Failure, List<RadioStation>>> call(
    GetRadioStationsParams params,
  ) {
    return _repository.getStations(language: params.language);
  }
}

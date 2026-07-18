import 'package:dartz_plus/dartz_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../entities/radio_station.dart';
import '../repositories/radio_repository.dart';

class RefreshRadioStationsParams extends Equatable {
  const RefreshRadioStationsParams({required this.language, this.after});

  final String language;
  final DateTime? after;

  @override
  List<Object?> get props => [language, after];
}

@lazySingleton
class RefreshRadioStationsUseCase
    extends UseCase<List<RadioStation>, RefreshRadioStationsParams> {
  RefreshRadioStationsUseCase(this._repository);

  final RadioRepository _repository;

  @override
  Future<Either<Failure, List<RadioStation>>> call(
    RefreshRadioStationsParams params,
  ) {
    return _repository.refreshStations(
      language: params.language,
      after: params.after,
    );
  }
}

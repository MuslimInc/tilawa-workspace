import 'package:dartz_plus/dartz_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../entities/radio_station.dart';
import '../repositories/radio_repository.dart';

class SearchRadioStationsParams extends Equatable {
  const SearchRadioStationsParams(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

@lazySingleton
class SearchRadioStationsUseCase
    extends UseCase<List<RadioStation>, SearchRadioStationsParams> {
  SearchRadioStationsUseCase(this._repository);

  final RadioRepository _repository;

  @override
  Future<Either<Failure, List<RadioStation>>> call(
    SearchRadioStationsParams params,
  ) {
    return _repository.searchStations(params.query);
  }
}

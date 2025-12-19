import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/entities/reciter_entity.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/reciters_repository.dart';
import 'reciter_details_loader_state.dart';

@injectable
class ReciterDetailsLoaderCubit extends Cubit<ReciterDetailsLoaderState> {
  ReciterDetailsLoaderCubit(this._repository)
    : super(const ReciterDetailsLoaderInitial());
  final RecitersRepository _repository;

  Future<void> loadReciter(String reciterId) async {
    emit(const ReciterDetailsLoaderLoading());

    final Either<Failure, ReciterEntity?> result = await _repository
        .getReciterById(reciterId);

    result.fold(
      (failure) =>
          emit(ReciterDetailsLoaderFailure(failure.message ?? 'Unknown error')),
      (reciter) {
        if (reciter != null) {
          emit(ReciterDetailsLoaderSuccess(reciter));
        } else {
          emit(const ReciterDetailsLoaderFailure('Reciter not found'));
        }
      },
    );
  }
}

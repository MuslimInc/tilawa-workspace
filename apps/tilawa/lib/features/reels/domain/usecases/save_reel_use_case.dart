import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import 'package:tilawa_core/utils/typedefs.dart';

import '../entities/reel.dart';
import '../repositories/reels_repository.dart';

class SaveReelParams extends Equatable {
  const SaveReelParams(this.reel);

  final Reel reel;

  @override
  List<Object?> get props => [reel];
}

@lazySingleton
class SaveReelUseCase extends UseCase<void, SaveReelParams> {
  SaveReelUseCase(this._repository);

  final ReelsRepository _repository;

  @override
  ResultFuture<void> call(SaveReelParams params) =>
      _repository.saveReel(params.reel);
}

class RemoveSavedReelParams extends Equatable {
  const RemoveSavedReelParams(this.reelId);

  final int reelId;

  @override
  List<Object?> get props => [reelId];
}

@lazySingleton
class RemoveSavedReelUseCase extends UseCase<void, RemoveSavedReelParams> {
  RemoveSavedReelUseCase(this._repository);

  final ReelsRepository _repository;

  @override
  ResultFuture<void> call(RemoveSavedReelParams params) =>
      _repository.removeSavedReel(params.reelId);
}

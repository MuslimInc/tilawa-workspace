import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import 'package:tilawa_core/utils/typedefs.dart';

import '../entities/reel_reaction.dart';
import '../repositories/reels_repository.dart';

class ReactToReelParams extends Equatable {
  const ReactToReelParams({
    required this.reelId,
    required this.reaction,
  });

  final int reelId;
  final ReelReaction reaction;

  @override
  List<Object?> get props => [reelId, reaction];
}

@lazySingleton
class ReactToReelUseCase extends UseCase<ReelReaction?, ReactToReelParams> {
  ReactToReelUseCase(this._repository);

  final ReelsRepository _repository;

  @override
  ResultFuture<ReelReaction?> call(ReactToReelParams params) =>
      _repository.reactToReel(params.reelId, params.reaction);
}

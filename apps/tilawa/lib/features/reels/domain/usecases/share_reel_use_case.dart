import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import 'package:tilawa_core/utils/typedefs.dart';

import '../entities/reel.dart';
import '../repositories/reels_repository.dart';

class ShareReelParams extends Equatable {
  const ShareReelParams({
    required this.reel,
    required this.mode,
  });

  final Reel reel;
  final ReelShareMode mode;

  @override
  List<Object?> get props => [reel, mode];
}

@lazySingleton
class ShareReelUseCase extends UseCase<void, ShareReelParams> {
  ShareReelUseCase(this._repository);

  final ReelsRepository _repository;

  @override
  ResultFuture<void> call(ShareReelParams params) =>
      _repository.shareReel(params.reel, mode: params.mode);
}

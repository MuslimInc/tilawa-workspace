import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import 'package:tilawa_core/utils/typedefs.dart';

import '../repositories/reels_repository.dart';

class RecordReelViewParams extends Equatable {
  const RecordReelViewParams({
    required this.reelId,
    required this.kind,
  });

  final int reelId;
  final ReelViewKind kind;

  @override
  List<Object?> get props => [reelId, kind];
}

@lazySingleton
class RecordReelViewUseCase extends UseCase<void, RecordReelViewParams> {
  RecordReelViewUseCase(this._repository);

  final ReelsRepository _repository;

  @override
  ResultFuture<void> call(RecordReelViewParams params) =>
      _repository.recordView(params.reelId, params.kind);
}

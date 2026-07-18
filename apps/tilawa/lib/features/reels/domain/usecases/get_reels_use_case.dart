import 'package:dartz_plus/dartz_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import 'package:tilawa_core/utils/typedefs.dart';

import '../entities/reel.dart';
import '../entities/reel_engagement.dart';
import '../repositories/reels_repository.dart';
import '../services/reel_ranking_service.dart';

class GetReelsParams extends Equatable {
  const GetReelsParams({
    required this.language,
    this.categoryId,
  });

  final String language;
  final int? categoryId;

  @override
  List<Object?> get props => [language, categoryId];
}

class GetReelsResult extends Equatable {
  const GetReelsResult({
    required this.reels,
    required this.engagement,
  });

  final List<Reel> reels;
  final Map<int, ReelEngagement> engagement;

  @override
  List<Object?> get props => [reels, engagement];
}

@lazySingleton
class GetReelsUseCase extends UseCase<GetReelsResult, GetReelsParams> {
  GetReelsUseCase(this._repository);

  final ReelsRepository _repository;

  @override
  ResultFuture<GetReelsResult> call(GetReelsParams params) async {
    final reelsResult = await _repository.getReels(language: params.language);
    return reelsResult.fold(
      Left.new,
      (reels) async {
        final engagementResult = await _repository.getEngagementMap();
        return engagementResult.fold(
          Left.new,
          (engagement) {
            var filtered = reels;
            if (params.categoryId != null) {
              filtered = reels
                  .where((r) => r.categoryId == params.categoryId)
                  .toList();
            }
            final ranked = ReelRankingService.sortForYou(filtered, engagement);
            return Right(GetReelsResult(reels: ranked, engagement: engagement));
          },
        );
      },
    );
  }
}

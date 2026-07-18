import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import 'package:tilawa_core/utils/typedefs.dart';

import '../entities/reel_category.dart';
import '../repositories/reels_repository.dart';

class GetReelCategoriesParams extends Equatable {
  const GetReelCategoriesParams({required this.language});

  final String language;

  @override
  List<Object?> get props => [language];
}

@lazySingleton
class GetReelCategoriesUseCase
    extends UseCase<List<ReelCategory>, GetReelCategoriesParams> {
  GetReelCategoriesUseCase(this._repository);

  final ReelsRepository _repository;

  @override
  ResultFuture<List<ReelCategory>> call(GetReelCategoriesParams params) =>
      _repository.getCategories(language: params.language);
}

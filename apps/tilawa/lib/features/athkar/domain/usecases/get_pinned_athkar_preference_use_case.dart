import 'package:injectable/injectable.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import 'package:tilawa_core/utils/typedefs.dart';

import '../entities/pinned_athkar_preference.dart';
import '../repositories/pinned_athkar_repository.dart';

@lazySingleton
class GetPinnedAthkarPreferenceUseCase
    extends UseCase<PinnedAthkarPreference, NoParams> {
  GetPinnedAthkarPreferenceUseCase(this._repository);

  final PinnedAthkarRepository _repository;

  @override
  ResultFuture<PinnedAthkarPreference> call(NoParams params) {
    return _repository.getPreference();
  }
}

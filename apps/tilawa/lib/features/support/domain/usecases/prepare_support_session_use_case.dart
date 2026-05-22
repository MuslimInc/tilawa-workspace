import 'package:injectable/injectable.dart';

import '../repositories/support_repository.dart';

/// Clears abandoned billing waiters before the support screen loads.
@lazySingleton
class PrepareSupportSessionUseCase {
  const PrepareSupportSessionUseCase(this._repository);

  final SupportRepository _repository;

  Future<void> call({bool resetWaiters = true}) =>
      _repository.prepareSupportSession(resetWaiters: resetWaiters);
}

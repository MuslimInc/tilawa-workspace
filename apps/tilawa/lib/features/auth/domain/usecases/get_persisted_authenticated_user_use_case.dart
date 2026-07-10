import 'package:injectable/injectable.dart';

import '../entities/user_entity.dart';

/// Legacy hook for splash startup routing.
///
/// [AuthBloc] no longer hydrates auth state. Firebase Auth restoration via
/// [AwaitAuthRestorationUseCase] and [GetCurrentUserUseCase] is the source of
/// truth on cold start.
@lazySingleton
class GetPersistedAuthenticatedUserUseCase {
  static const String storageKey = 'AuthBloc';

  Future<UserEntity?> call() async => null;
}

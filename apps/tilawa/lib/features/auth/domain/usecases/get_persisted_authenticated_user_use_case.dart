import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';

import '../entities/user_entity.dart';

/// Reads the last persisted authenticated user from [AuthBloc] hydration.
///
/// Used during cold start before [AuthBloc] mounts so splash routing can
/// treat offline cached sessions as signed-in when Firebase lags.
@lazySingleton
class GetPersistedAuthenticatedUserUseCase {
  static const String storageKey = 'AuthBloc';

  Future<UserEntity?> call() async {
    final dynamic raw = await HydratedBloc.storage.read(storageKey);
    if (raw is! Map<String, dynamic>) {
      return null;
    }

    try {
      final String? stateType = raw['state'] as String?;
      if (stateType != 'authenticated') {
        return null;
      }
      final Map<String, dynamic>? userJson =
          raw['user'] as Map<String, dynamic>?;
      if (userJson == null) {
        return null;
      }
      return UserEntity(
        id: userJson['id'] as String,
        email: userJson['email'] as String,
        displayName: userJson['displayName'] as String,
        photoUrl: userJson['photoUrl'] as String?,
        createdAt: DateTime.parse(userJson['createdAt'] as String),
      );
    } catch (_) {
      return null;
    }
  }
}

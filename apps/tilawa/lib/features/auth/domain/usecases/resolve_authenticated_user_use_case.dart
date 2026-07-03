import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';

import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';
import 'await_auth_restoration_use_case.dart';

/// Resolves the live Firebase session user.
///
/// After interactive sign-in, [AuthRepository.currentUser] can lag behind
/// [AuthBloc]'s authenticated state. Pass [sessionUser] from presentation
/// so server actions can wait for Firebase to catch up instead of failing
/// with a false "not signed in" error.
@injectable
class ResolveAuthenticatedUserUseCase {
  ResolveAuthenticatedUserUseCase(
    this._authRepository,
    this._awaitAuthRestoration,
  );

  /// Max wait after auth init for Firebase to expose [sessionUser].
  static const Duration postSignInSyncTimeout = Duration(seconds: 3);

  final AuthRepository _authRepository;
  final AwaitAuthRestorationUseCase _awaitAuthRestoration;

  Future<UserEntity?> call({UserEntity? sessionUser}) async {
    final UserEntity? immediate = _authRepository.currentUser;
    if (immediate != null) {
      return immediate;
    }

    await _awaitAuthRestoration();

    final UserEntity? afterRestoration = _authRepository.currentUser;
    if (afterRestoration != null) {
      return afterRestoration;
    }

    if (sessionUser == null) {
      logger.d(
        '[ResolveAuthenticatedUser] no live session and no session hint',
      );
      return null;
    }

    try {
      final UserEntity synced = await _authRepository.authStateChanges
          .where((UserEntity? user) => user?.id == sessionUser.id)
          .map((UserEntity? user) => user!)
          .timeout(postSignInSyncTimeout)
          .first;
      logger.d(
        '[ResolveAuthenticatedUser] session synced userId=${synced.id}',
      );
      return synced;
    } on TimeoutException {
      logger.d(
        '[ResolveAuthenticatedUser] session sync timed out '
        'expectedUserId=${sessionUser.id} '
        'signedIn=${_authRepository.currentUser != null}',
      );
      return _authRepository.currentUser;
    } catch (_) {
      logger.d(
        '[ResolveAuthenticatedUser] session sync ended without user '
        'expectedUserId=${sessionUser.id} '
        'signedIn=${_authRepository.currentUser != null}',
      );
      return _authRepository.currentUser;
    }
  }
}

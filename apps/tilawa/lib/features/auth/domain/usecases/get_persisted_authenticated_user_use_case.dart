import 'package:injectable/injectable.dart';

import '../entities/user_entity.dart';
import '../services/token_sync_cache.dart';

/// Cold-start hint: was a user signed in the last time this install ran?
///
/// [AuthBloc] no longer hydrates auth state. Firebase Auth restoration via
/// [AwaitAuthRestorationUseCase] and [GetCurrentUserUseCase] is the source of
/// truth once the native SDK finishes loading the persisted session. But on a
/// cold start `FirebaseAuth.currentUser` is transiently `null` and
/// `authStateChanges` can emit a premature `null` before restoration
/// completes. Startup must therefore know *whether to wait* for a restore
/// instead of reading a single `null` as a confirmed logout.
///
/// The app already persists the last signed-in user id in [TokenSyncCache]
/// (`last_synced_fcm_user_id`): written whenever the device token is synced for
/// an authenticated user (sign-in and `checkAuthStatus`), and cleared by
/// [TokenSyncCache.clearSession] during explicit sign-out. We reuse it as the
/// restoration hint — no new storage or write sites. The returned entity is an
/// id-only placeholder; the real profile comes from Firebase once restored.
@lazySingleton
class GetPersistedAuthenticatedUserUseCase {
  GetPersistedAuthenticatedUserUseCase(this._tokenSyncCache);

  static const String storageKey = 'AuthBloc';

  final TokenSyncCache _tokenSyncCache;

  Future<UserEntity?> call() async {
    final String? uid = await _tokenSyncCache.getLastSyncedUserId();
    if (uid == null || uid.isEmpty) {
      return null;
    }
    return UserEntity(
      id: uid,
      email: '',
      displayName: '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

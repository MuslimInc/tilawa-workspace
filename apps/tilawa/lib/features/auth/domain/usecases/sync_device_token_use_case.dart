import 'package:injectable/injectable.dart';
import 'package:tilawa/core/services/device_token_service.dart';

import '../repositories/user_repository.dart';
import '../services/token_sync_cache.dart';

@injectable
class SyncDeviceTokenUseCase {
  SyncDeviceTokenUseCase(
    this._userRepository,
    this._deviceTokenService,
    this._tokenSyncCache,
  );

  final UserRepository _userRepository;
  final DeviceTokenService _deviceTokenService;
  final TokenSyncCache _tokenSyncCache;

  Future<void> call(String userId) async {
    try {
      final String? token = await _deviceTokenService.getToken();
      if (token == null || token.isEmpty) {
        return;
      }

      final String? previousToken = await _tokenSyncCache.getLastSyncedToken();
      final String? previousUserId =
          await _tokenSyncCache.getLastSyncedUserId();

      if (previousToken != null &&
          previousToken.isNotEmpty &&
          previousUserId != null &&
          previousUserId.isNotEmpty &&
          (previousToken != token || previousUserId != userId)) {
        await _deleteTokenQuietly(previousUserId, previousToken);
      }

      await _userRepository.saveDeviceToken(userId, token);
      await _tokenSyncCache.saveSync(token, userId);
    } catch (e) {
      // Fail silently for token sync, don't block auth flow
    }
  }

  Future<void> removeCurrentTokenForUser(String userId) async {
    try {
      final String? currentToken = await _deviceTokenService.getToken();
      final String? previousToken = await _tokenSyncCache.getLastSyncedToken();
      final String? previousUserId =
          await _tokenSyncCache.getLastSyncedUserId();

      if (currentToken != null && currentToken.isNotEmpty) {
        await _deleteTokenQuietly(userId, currentToken);
      }

      if (previousToken != null &&
          previousToken.isNotEmpty &&
          previousUserId != null &&
          previousUserId.isNotEmpty &&
          previousToken != currentToken) {
        await _deleteTokenQuietly(previousUserId, previousToken);
      }
    } finally {
      await _tokenSyncCache.clearSync();
    }
  }

  Future<void> _deleteTokenQuietly(String userId, String token) async {
    try {
      await _userRepository.deleteDeviceToken(userId, token);
    } catch (_) {
      // Best-effort cleanup only.
    }
  }
}

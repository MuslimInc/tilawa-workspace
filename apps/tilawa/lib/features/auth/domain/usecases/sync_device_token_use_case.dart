import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/services/device_token_service.dart';

import '../repositories/user_repository.dart';

@injectable
class SyncDeviceTokenUseCase {
  SyncDeviceTokenUseCase(
    this._userRepository,
    this._deviceTokenService,
    this._prefs,
  );

  static const String _lastSyncedTokenKey = 'last_synced_fcm_token';
  static const String _lastSyncedUserIdKey = 'last_synced_fcm_user_id';

  final UserRepository _userRepository;
  final DeviceTokenService _deviceTokenService;
  final SharedPreferencesAsync _prefs;

  Future<void> call(String userId) async {
    try {
      final String? token = await _deviceTokenService.getToken();
      if (token == null || token.isEmpty) {
        return;
      }

      final String? previousToken = await _prefs.getString(_lastSyncedTokenKey);
      final String? previousUserId = await _prefs.getString(
        _lastSyncedUserIdKey,
      );

      if (previousToken != null &&
          previousToken.isNotEmpty &&
          previousUserId != null &&
          previousUserId.isNotEmpty &&
          (previousToken != token || previousUserId != userId)) {
        await _deleteTokenQuietly(previousUserId, previousToken);
      }

      await _userRepository.saveDeviceToken(userId, token);
      await _prefs.setString(_lastSyncedTokenKey, token);
      await _prefs.setString(_lastSyncedUserIdKey, userId);
    } catch (e) {
      // Fail silently for token sync, don't block auth flow
    }
  }

  Future<void> removeCurrentTokenForUser(String userId) async {
    try {
      final String? currentToken = await _deviceTokenService.getToken();
      final String? previousToken = await _prefs.getString(_lastSyncedTokenKey);
      final String? previousUserId = await _prefs.getString(
        _lastSyncedUserIdKey,
      );

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
      await _prefs.remove(_lastSyncedTokenKey);
      await _prefs.remove(_lastSyncedUserIdKey);
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

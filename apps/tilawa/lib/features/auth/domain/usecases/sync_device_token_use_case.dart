import 'package:injectable/injectable.dart';
import 'package:tilawa/core/services/device_token_service.dart';

import '../repositories/user_repository.dart';

@injectable
class SyncDeviceTokenUseCase {
  SyncDeviceTokenUseCase(this._userRepository, this._deviceTokenService);

  final UserRepository _userRepository;
  final DeviceTokenService _deviceTokenService;

  Future<void> call(String userId) async {
    try {
      final String? token = await _deviceTokenService.getToken();
      if (token != null) {
        await _userRepository.saveDeviceToken(userId, token);
      }

      // Note: In a production app, we might also want to listen to
      // _deviceTokenService.onTokenRefresh here or in a dedicated service
      // to keep the token updated if it changes during the session.
    } catch (e) {
      // Fail silently for token sync, don't block auth flow
    }
  }
}

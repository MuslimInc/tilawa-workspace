import 'package:injectable/injectable.dart';
import 'package:tilawa_core/config/language_config.dart';

import '../repositories/user_repository.dart';

/// Persists the in-app language choice on `users/{uid}.languageCode`.
@lazySingleton
class SyncUserLanguagePreferenceUseCase {
  const SyncUserLanguagePreferenceUseCase(this._userRepository);

  final UserRepository _userRepository;

  Future<void> call(String languageCode) {
    final normalized = LanguageConfig.normalizeForPushNotifications(
      languageCode,
    );
    return _userRepository.syncLanguagePreference(normalized);
  }
}

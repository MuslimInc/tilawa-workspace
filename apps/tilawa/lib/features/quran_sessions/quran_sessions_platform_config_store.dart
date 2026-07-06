import 'package:flutter/foundation.dart';

import 'domain/entities/quran_sessions_platform_config.dart';

class QuranSessionsPlatformConfigStore extends ChangeNotifier {
  QuranSessionsPlatformConfig? _config;

  QuranSessionsPlatformConfig? get config => _config;

  void setConfig(QuranSessionsPlatformConfig? config) {
    if (_config == config) {
      return;
    }
    _config = config;
    notifyListeners();
  }
}

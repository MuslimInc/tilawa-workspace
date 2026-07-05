class AppStrings {
  const AppStrings._();

  static const String _appEnvironment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: '',
  );
  static const String _distribution = String.fromEnvironment(
    'TILAWA_DISTRIBUTION',
    defaultValue: 'local',
  );

  static const String appName = 'MeMuslim';
  static const String googleClientId =
      '181575856185-2ioqgr7miir7hj7hvgcsi7qp7juo2gco.apps.googleusercontent.com';

  /// iOS OAuth client ID from Firebase (`GoogleService-Info.plist` `CLIENT_ID`).
  static String get googleIosClientId => switch (_effectiveEnvironment) {
    'development' =>
      '181575856185-v2hhlsvcr0ieia4d8cvo1d0uk71l1jej.apps.googleusercontent.com',
    'staging' =>
      '181575856185-o2k7lc3j2itugtg2b7l4kj4kauhucsiu.apps.googleusercontent.com',
    _ =>
      '181575856185-n7pkcdipps2lm920ve1qbcbo4kemn45b.apps.googleusercontent.com',
  };

  /// Reversed iOS client ID for `CFBundleURLSchemes` (`REVERSED_CLIENT_ID`).
  static String
  get googleIosReversedClientId => switch (_effectiveEnvironment) {
    'development' =>
      'com.googleusercontent.apps.181575856185-v2hhlsvcr0ieia4d8cvo1d0uk71l1jej',
    'staging' =>
      'com.googleusercontent.apps.181575856185-o2k7lc3j2itugtg2b7l4kj4kauhucsiu',
    _ =>
      'com.googleusercontent.apps.181575856185-n7pkcdipps2lm920ve1qbcbo4kemn45b',
  };

  static const String restorationScopeId = 'tilawa_app';
  static const String routerRestorationScopeId = 'tilawa_router';

  static String get _effectiveEnvironment {
    final normalized = _appEnvironment.trim().toLowerCase();
    if (normalized == 'development' || normalized == 'dev') {
      return 'development';
    }
    if (normalized == 'staging') {
      return 'staging';
    }
    if (normalized == 'production' || normalized == 'prod') {
      return 'production';
    }
    final normalizedDistribution = _distribution.trim();
    if (normalizedDistribution == 'staging') {
      return 'staging';
    }
    if (normalizedDistribution == 'play_production' ||
        normalizedDistribution == 'production') {
      return 'production';
    }
    return 'development';
  }
}

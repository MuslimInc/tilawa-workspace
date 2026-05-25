class AppStrings {
  const AppStrings._();

  static const String appName = 'Rattil';
  static const String googleClientId =
      '181575856185-2ioqgr7miir7hj7hvgcsi7qp7juo2gco.apps.googleusercontent.com';

  /// iOS OAuth client ID from Firebase (`GoogleService-Info.plist` `CLIENT_ID`).
  static const String googleIosClientId =
      '181575856185-n7pkcdipps2lm920ve1qbcbo4kemn45b.apps.googleusercontent.com';

  /// Reversed iOS client ID for `CFBundleURLSchemes` (`REVERSED_CLIENT_ID`).
  static const String googleIosReversedClientId =
      'com.googleusercontent.apps.181575856185-n7pkcdipps2lm920ve1qbcbo4kemn45b';
  static const String restorationScopeId = 'tilawa_app';
  static const String routerRestorationScopeId = 'tilawa_router';
}

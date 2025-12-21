// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router_config.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $homeRoute,
  $reciterDetailsRoute,
  $expandedPlayerRoute,
  $premiumRoute,
  $settingsRoute,
  $loginRoute,
  $downloadsRoute,
  $errorRoute,
  $favoritesRoute,
  $athkarCategoriesRoute,
  $athkarDetailsRoute,
  $qiblaRoute,
  $routeListRoute,
  $splashRoute,
];

RouteBase get $homeRoute =>
    GoRouteData.$route(path: '/', factory: $HomeRoute._fromState);

mixin $HomeRoute on GoRouteData {
  static HomeRoute _fromState(GoRouterState state) => const HomeRoute();

  @override
  String get location => GoRouteData.$location('/');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $reciterDetailsRoute => GoRouteData.$route(
  path: '/reciter/:reciterId',
  factory: $ReciterDetailsRoute._fromState,
);

mixin $ReciterDetailsRoute on GoRouteData {
  static ReciterDetailsRoute _fromState(GoRouterState state) =>
      ReciterDetailsRoute(
        reciterId: state.pathParameters['reciterId']!,
        $extra: state.extra as ReciterEntity?,
      );

  ReciterDetailsRoute get _self => this as ReciterDetailsRoute;

  @override
  String get location =>
      GoRouteData.$location('/reciter/${Uri.encodeComponent(_self.reciterId)}');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

RouteBase get $expandedPlayerRoute => GoRouteData.$route(
  path: '/expandedPlayer',
  factory: $ExpandedPlayerRoute._fromState,
);

mixin $ExpandedPlayerRoute on GoRouteData {
  static ExpandedPlayerRoute _fromState(GoRouterState state) =>
      const ExpandedPlayerRoute();

  @override
  String get location => GoRouteData.$location('/expandedPlayer');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $premiumRoute =>
    GoRouteData.$route(path: '/premium', factory: $PremiumRoute._fromState);

mixin $PremiumRoute on GoRouteData {
  static PremiumRoute _fromState(GoRouterState state) => const PremiumRoute();

  @override
  String get location => GoRouteData.$location('/premium');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $settingsRoute =>
    GoRouteData.$route(path: '/settings', factory: $SettingsRoute._fromState);

mixin $SettingsRoute on GoRouteData {
  static SettingsRoute _fromState(GoRouterState state) => const SettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $loginRoute =>
    GoRouteData.$route(path: '/login', factory: $LoginRoute._fromState);

mixin $LoginRoute on GoRouteData {
  static LoginRoute _fromState(GoRouterState state) => const LoginRoute();

  @override
  String get location => GoRouteData.$location('/login');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $downloadsRoute =>
    GoRouteData.$route(path: '/downloads', factory: $DownloadsRoute._fromState);

mixin $DownloadsRoute on GoRouteData {
  static DownloadsRoute _fromState(GoRouterState state) =>
      const DownloadsRoute();

  @override
  String get location => GoRouteData.$location('/downloads');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $errorRoute =>
    GoRouteData.$route(path: '/error', factory: $ErrorRoute._fromState);

mixin $ErrorRoute on GoRouteData {
  static ErrorRoute _fromState(GoRouterState state) =>
      ErrorRoute(error: state.uri.queryParameters['error']);

  ErrorRoute get _self => this as ErrorRoute;

  @override
  String get location => GoRouteData.$location(
    '/error',
    queryParams: {if (_self.error != null) 'error': _self.error},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $favoritesRoute =>
    GoRouteData.$route(path: '/favorites', factory: $FavoritesRoute._fromState);

mixin $FavoritesRoute on GoRouteData {
  static FavoritesRoute _fromState(GoRouterState state) =>
      const FavoritesRoute();

  @override
  String get location => GoRouteData.$location('/favorites');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $athkarCategoriesRoute => GoRouteData.$route(
  path: '/athkar',
  factory: $AthkarCategoriesRoute._fromState,
);

mixin $AthkarCategoriesRoute on GoRouteData {
  static AthkarCategoriesRoute _fromState(GoRouterState state) =>
      const AthkarCategoriesRoute();

  @override
  String get location => GoRouteData.$location('/athkar');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $athkarDetailsRoute => GoRouteData.$route(
  path: '/athkar/:categoryId',
  factory: $AthkarDetailsRoute._fromState,
);

mixin $AthkarDetailsRoute on GoRouteData {
  static AthkarDetailsRoute _fromState(GoRouterState state) =>
      AthkarDetailsRoute(
        categoryId: int.parse(state.pathParameters['categoryId']!),
        categoryName: state.uri.queryParameters['category-name']!,
      );

  AthkarDetailsRoute get _self => this as AthkarDetailsRoute;

  @override
  String get location => GoRouteData.$location(
    '/athkar/${Uri.encodeComponent(_self.categoryId.toString())}',
    queryParams: {'category-name': _self.categoryName},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $qiblaRoute =>
    GoRouteData.$route(path: '/qibla', factory: $QiblaRoute._fromState);

mixin $QiblaRoute on GoRouteData {
  static QiblaRoute _fromState(GoRouterState state) => const QiblaRoute();

  @override
  String get location => GoRouteData.$location('/qibla');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $routeListRoute =>
    GoRouteData.$route(path: '/routes', factory: $RouteListRoute._fromState);

mixin $RouteListRoute on GoRouteData {
  static RouteListRoute _fromState(GoRouterState state) =>
      const RouteListRoute();

  @override
  String get location => GoRouteData.$location('/routes');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $splashRoute =>
    GoRouteData.$route(path: '/splash', factory: $SplashRoute._fromState);

mixin $SplashRoute on GoRouteData {
  static SplashRoute _fromState(GoRouterState state) => const SplashRoute();

  @override
  String get location => GoRouteData.$location('/splash');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:tilawa/core/bootstrap/app_startup_readiness.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa/router/notification_navigation_resolver.dart';

import '../../features/auth/domain/usecases/prepare_google_sign_in_use_case.dart';
import '../../features/splash/domain/usecases/get_splash_next_route_use_case.dart';

enum StartupLaunchTarget { home, login, onboarding, notification }

const String _homeLocation = '/';
const String _loginLocation = '/login';
const String _onboardingLocation = '/language-welcome';

/// Final launch decision used by the boot gate before the router is built.
class StartupLaunchPlan {
  const StartupLaunchPlan._({
    required this.target,
    required this.location,
    this.extra,
    this.timedOut = false,
    this.recitersReady = false,
  });

  const StartupLaunchPlan.home({
    bool timedOut = false,
    bool recitersReady = false,
  }) : this._(
         target: StartupLaunchTarget.home,
         location: _homeLocation,
         timedOut: timedOut,
         recitersReady: recitersReady,
       );

  const StartupLaunchPlan.login({
    bool timedOut = false,
    bool recitersReady = false,
  }) : this._(
         target: StartupLaunchTarget.login,
         location: _loginLocation,
         timedOut: timedOut,
         recitersReady: recitersReady,
       );

  const StartupLaunchPlan.onboarding({
    bool timedOut = false,
    bool recitersReady = false,
  }) : this._(
         target: StartupLaunchTarget.onboarding,
         location: _onboardingLocation,
         timedOut: timedOut,
         recitersReady: recitersReady,
       );

  const StartupLaunchPlan.notification(
    String location, {
    Object? extra,
    bool timedOut = false,
    bool recitersReady = false,
  }) : this._(
         target: StartupLaunchTarget.notification,
         location: location,
         extra: extra,
         timedOut: timedOut,
         recitersReady: recitersReady,
       );

  final StartupLaunchTarget target;
  final String location;
  final Object? extra;
  final bool timedOut;
  final bool recitersReady;
}

/// Resolves the first in-app destination while the boot gate is still visible.
@lazySingleton
class StartupLaunchCoordinator {
  StartupLaunchCoordinator(
    this._getSplashNextRoute,
    this._prepareGoogleSignIn,
    this._readiness,
  );

  final GetSplashNextRouteUseCase _getSplashNextRoute;
  final PrepareGoogleSignInUseCase _prepareGoogleSignIn;
  final AppStartupReadiness _readiness;

  static const Duration _googlePrepareTimeout = Duration(seconds: 2);

  Future<StartupLaunchPlan> resolve() async {
    final SplashRouteResult result = await _getSplashNextRoute();
    final bool prepareShell = result.destination == SplashDestination.home;
    await _readiness.waitUntilReady(prepareShell: prepareShell);

    String? location;
    Object? extra;
    if (result.destination == SplashDestination.notificationLaunch &&
        result.notificationData != null) {
      location = NotificationNavigationResolver.resolveLocation(
        result.notificationData!,
      );
      extra = NotificationNavigationResolver.resolveExtra(
        result.notificationData!,
        location,
      );
    }

    if (result.destination == SplashDestination.login) {
      await _prepareGoogleSignIn().timeout(
        _googlePrepareTimeout,
        onTimeout: () {},
      );
    }

    final String? pendingColdStartLocation = AppRouter.pendingColdStartLocation;
    if (pendingColdStartLocation != null) {
      return StartupLaunchPlan.notification(
        pendingColdStartLocation,
        extra: AppRouter.pendingColdStartExtra,
        timedOut: _readiness.timedOut,
        recitersReady: _readiness.recitersDataReady,
      );
    }

    switch (result.destination) {
      case SplashDestination.home:
        return StartupLaunchPlan.home(
          timedOut: _readiness.timedOut,
          recitersReady: _readiness.recitersDataReady,
        );
      case SplashDestination.login:
        return StartupLaunchPlan.login(
          timedOut: _readiness.timedOut,
          recitersReady: _readiness.recitersDataReady,
        );
      case SplashDestination.onboarding:
        return StartupLaunchPlan.onboarding(
          timedOut: _readiness.timedOut,
          recitersReady: _readiness.recitersDataReady,
        );
      case SplashDestination.notificationLaunch when location != null:
        return StartupLaunchPlan.notification(
          location,
          extra: extra,
          timedOut: _readiness.timedOut,
          recitersReady: _readiness.recitersDataReady,
        );
      case SplashDestination.notificationLaunch:
        return StartupLaunchPlan.home(
          timedOut: _readiness.timedOut,
          recitersReady: _readiness.recitersDataReady,
        );
    }
  }
}

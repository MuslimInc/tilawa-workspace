import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/bootstrap/app_startup_readiness.dart';
import 'package:tilawa/core/logging/app_logger.dart';

import '../../../../router/app_router.dart';
import '../../../../router/notification_navigation_resolver.dart';
import '../../../auth/domain/usecases/prepare_google_sign_in_use_case.dart';
import '../../domain/usecases/get_splash_next_route_use_case.dart';
import 'splash_event.dart';
import 'splash_state.dart';

/// Orchestrates splash-held startup and initial navigation.
@injectable
class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc(
    this._getSplashNextRoute,
    this._prepareGoogleSignIn,
    this._readiness,
  ) : super(const SplashLoading()) {
    on<SplashStarted>(_onStarted);
  }

  final GetSplashNextRouteUseCase _getSplashNextRoute;
  final PrepareGoogleSignInUseCase _prepareGoogleSignIn;
  final AppStartupReadiness _readiness;

  static const Duration _googlePrepareTimeout = Duration(seconds: 2);

  Future<void> _onStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    try {
      final SplashRouteResult result = await _getSplashNextRoute();

      final bool prepareShell =
          result.destination == SplashDestination.home;
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

      if (isClosed) {
        return;
      }

      final String? pendingColdStartLocation =
          AppRouter.pendingColdStartLocation;
      if (pendingColdStartLocation != null) {
        emit(
          SplashNavigateToNotification(
            pendingColdStartLocation,
            extra: AppRouter.pendingColdStartExtra,
          ),
        );
        return;
      }

      switch (result.destination) {
        case SplashDestination.home:
          emit(SplashNavigateToHome(timedOut: _readiness.timedOut));
        case SplashDestination.login:
          emit(const SplashNavigateToLogin());
        case SplashDestination.onboarding:
          emit(const SplashNavigateToOnboarding());
        case SplashDestination.notificationLaunch when location != null:
          emit(SplashNavigateToNotification(location, extra: extra));
        case SplashDestination.notificationLaunch:
          emit(SplashNavigateToHome(timedOut: _readiness.timedOut));
      }
    } catch (e, stackTrace) {
      logger.e(
        'SplashBloc failed, falling back to home',
        error: e,
        stackTrace: stackTrace,
      );
      if (!isClosed) {
        emit(const SplashNavigateToHome());
      }
    }
  }
}

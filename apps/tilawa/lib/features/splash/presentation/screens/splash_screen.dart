import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/bootstrap/splash_launch_handoff.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../router/app_router_config.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/splash_bloc.dart';
import '../bloc/splash_event.dart';
import '../bloc/splash_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Color _launchBackgroundColor = AppColors.defaultPrimary;
  static const String _launchWordmarkAsset =
      'assets/images/launch_wordmark.png';
  static const double _androidSplashWordmarkBoxSize = 288;
  static const SystemUiOverlayStyle _launchOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: _launchBackgroundColor,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: _launchBackgroundColor,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: Colors.transparent,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
  );

  late final SplashBloc _splashBloc;

  @override
  void initState() {
    super.initState();
    _splashBloc = getIt<SplashBloc>()..add(const SplashStarted());
    SchedulerBinding.instance.addPostFrameCallback((_) {
      SplashLaunchHandoff.markSplashRoutePainted();
    });
  }

  @override
  void dispose() {
    _splashBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _splashBloc,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          state.when(
            initial: () {},
            loading: () {},
            authenticated: (_) {},
            unauthenticated: () {},
            error: (message) {
              ToastUtils.showErrorToast(message);
              AppRouter.disableStateRestoration = false;
              AppRouter.pendingStartupNotificationLaunch = false;
              AppRouter.router.go(const LoginRoute().location);
            },
          );
        },
        child: BlocListener<SplashBloc, SplashState>(
          listener: (context, state) {
            switch (state) {
              case SplashLoading():
                break;
              case SplashNavigateToHome():
                AppRouter.disableStateRestoration = false;
                AppRouter.pendingStartupNotificationLaunch = false;
                AppRouter.router.go(const HomeRoute().location);
              case SplashNavigateToLogin():
                AppRouter.disableStateRestoration = false;
                AppRouter.pendingStartupNotificationLaunch = false;
                AppRouter.router.go(const LoginRoute().location);
              case SplashNavigateToOnboarding():
                AppRouter.disableStateRestoration = false;
                AppRouter.pendingStartupNotificationLaunch = false;
                AppRouter.router.go(const OnboardingRoute().location);
              case SplashNavigateToNotification(:final location, :final extra):
                AppRouter.navigateFromColdStart(location, extra: extra);
              case SplashFailure():
                AppRouter.disableStateRestoration = false;
                AppRouter.pendingStartupNotificationLaunch = false;
                AppRouter.router.go(const HomeRoute().location);
            }
          },
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: _launchOverlayStyle,
            child: ColoredBox(
              color: _launchBackgroundColor,
              child: Center(
                child: SizedBox.square(
                  dimension: _androidSplashWordmarkBoxSize,
                  child: Image.asset(
                    _launchWordmarkAsset,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

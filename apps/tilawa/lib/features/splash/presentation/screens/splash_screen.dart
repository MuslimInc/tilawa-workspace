import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa_core/di/injection.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../router/app_router_config.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../cubit/splash_cubit.dart';

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

  late final SplashCubit _splashCubit;

  @override
  void initState() {
    super.initState();
    _splashCubit = getIt<SplashCubit>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_splashCubit.isClosed) {
        _splashCubit.init();
      }
    });
  }

  @override
  void dispose() {
    _splashCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _splashCubit,
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
        child: BlocListener<SplashCubit, SplashState>(
          listener: (context, state) {
            if (state is SplashNavigateToHome) {
              AppRouter.disableStateRestoration = false;
              AppRouter.pendingStartupNotificationLaunch = false;
              AppRouter.router.go(const HomeRoute().location);
            } else if (state is SplashNavigateToLogin) {
              AppRouter.disableStateRestoration = false;
              AppRouter.pendingStartupNotificationLaunch = false;
              AppRouter.router.go(const LoginRoute().location);
            } else if (state is SplashNavigateToOnboarding) {
              AppRouter.disableStateRestoration = false;
              AppRouter.pendingStartupNotificationLaunch = false;
              AppRouter.router.go(const OnboardingRoute().location);
            } else if (state is SplashNavigateToNotification) {
              AppRouter.navigateFromColdStart(
                state.location,
                extra: state.extra,
              );
            }
          },
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: _launchOverlayStyle,
            child: ColoredBox(
              color: _launchBackgroundColor,
              child: SizedBox.expand(
                child: Center(
                  child: SizedBox.square(
                    dimension: _androidSplashWordmarkBoxSize,
                    child: Image.asset(
                      _launchWordmarkAsset,
                      filterQuality: FilterQuality.high,
                      fit: BoxFit.fill,
                    ),
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

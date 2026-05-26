import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/bootstrap/splash_launch_handoff.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
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
  static const double _wordmarkBoxSize = 288;
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

  void _goAndReset(String location) {
    AppRouter.disableStateRestoration = false;
    AppRouter.pendingStartupNotificationLaunch = false;
    AppRouter.router.go(location);
  }

  Future<void> _showAuthErrorDialog(BuildContext context, String message) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.error),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ctx.l10n.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _splashBloc,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) async {
          state.when(
            initial: () {},
            loading: () {},
            authenticated: (_) {},
            unauthenticated: () {},
            error: (message) async {
              await _showAuthErrorDialog(context, message);
              if (context.mounted) _goAndReset(const LoginRoute().location);
            },
          );
        },
        child: BlocListener<SplashBloc, SplashState>(
          listener: (context, state) {
            switch (state) {
              case SplashLoading():
                break;
              case SplashNavigateToHome(:final timedOut) when timedOut:
                ToastUtils.showToast(msg: context.l10n.splashSlowLoadingNotice);
                _goAndReset(const HomeRoute().location);
              case SplashNavigateToHome():
                _goAndReset(const HomeRoute().location);
              case SplashNavigateToLogin():
                _goAndReset(const LoginRoute().location);
              case SplashNavigateToOnboarding():
                _goAndReset(const OnboardingRoute().location);
              case SplashNavigateToNotification(:final location, :final extra):
                AppRouter.navigateFromColdStart(location, extra: extra);
              case SplashFailure():
                _goAndReset(const HomeRoute().location);
            }
          },
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: _launchOverlayStyle,
            child: Semantics(
              label: context.l10n.a11ySplashLoading,
              liveRegion: true,
              child: ColoredBox(
                color: _launchBackgroundColor,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.square(
                        dimension: _wordmarkBoxSize,
                        child: Image.asset(
                          _launchWordmarkAsset,
                          filterQuality: FilterQuality.high,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 40),
                      const CircularProgressIndicator.adaptive(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ],
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

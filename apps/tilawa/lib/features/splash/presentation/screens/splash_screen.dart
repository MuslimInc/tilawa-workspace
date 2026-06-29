import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/bootstrap/first_frame_log.dart';
import 'package:tilawa/core/bootstrap/launch_splash_canvas.dart';
import 'package:tilawa/core/bootstrap/logo_height_log.dart';
import 'package:tilawa/core/bootstrap/splash_launch_handoff.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/services/app_system_chrome_style.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

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
  static final Color _launchBackground = AppColors.launchSplashBackground;
  static const Color _logoForeground = AppColors.launchSplashForeground;
  static const String _appLogoAsset = 'assets/images/app_logo.png';
  static const double _wordmarkBoxSize = AppColors.launchSplashLogoSize;
  static final SystemUiOverlayStyle _launchOverlayStyle =
      AppSystemChromeStyle.buildColoredScreenStyle(
        backgroundColor: _launchBackground,
      );

  late final SplashBloc _splashBloc;

  @override
  void initState() {
    super.initState();
    firstFrameLog('SplashScreen initState (/splash route)');
    _splashBloc = getIt<SplashBloc>()..add(const SplashStarted());
    SchedulerBinding.instance.addPostFrameCallback((_) {
      firstFrameLog('SplashScreen first post-frame → mark handoff');
      SplashLaunchHandoff.markSplashRoutePainted();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    firstFrameLog('SplashScreen didChangeDependencies');
  }

  @override
  void dispose() {
    _splashBloc.close();
    super.dispose();
  }

  void _goAndReset(String location) {
    AppRouter.consumeBootLaunchPlan();
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
        listener: (context, state) {
          state.when(
            initial: () {},
            loading: () {},
            authenticated: (_) {},
            unauthenticated: () {},
            error: (message) async {
              await _showAuthErrorDialog(context, message);
              if (context.mounted) _goAndReset(const LoginRoute().location);
            },
            noGoogleAccounts: () {},
          );
        },
        child: BlocListener<SplashBloc, SplashState>(
          listener: (context, state) {
            switch (state) {
              case SplashLoading():
                break;
              case SplashNavigateToHome(:final timedOut) when timedOut:
                TilawaFeedback.showToast(
                  context,
                  message: context.l10n.splashSlowLoadingNotice,
                  variant: TilawaFeedbackVariant.warning,
                );
                _goAndReset(const HomeRoute().location);
              case SplashNavigateToHome():
                _goAndReset(const HomeRoute().location);
              case SplashNavigateToLogin():
                _goAndReset(const LoginRoute().location);
              case SplashNavigateToOnboarding():
                _goAndReset(const LanguageWelcomeRoute().location);
              case SplashNavigateToNotification(:final location, :final extra):
                AppRouter.consumeBootLaunchPlan();
                AppRouter.navigateFromColdStart(location, extra: extra);
              case SplashFailure():
                _goAndReset(const HomeRoute().location);
            }
          },
          child: Semantics(
            label: context.l10n.a11ySplashLoading,
            liveRegion: true,
            child: LaunchSplashCanvas(
              backgroundColor: _launchBackground,
              overlayStyle: _launchOverlayStyle,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LogoHeightProbe(
                    source: 'SplashScreen',
                    boxSize: _wordmarkBoxSize,
                    asset: _appLogoAsset,
                    child: Image.asset(
                      _appLogoAsset,
                      filterQuality: FilterQuality.high,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const CircularProgressIndicator(
                    color: _logoForeground,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

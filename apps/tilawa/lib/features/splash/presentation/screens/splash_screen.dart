import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa_core/di/injection.dart';
import 'package:tilawa_ui/theme/color_scheme.dart';

import '../../../../router/app_router_config.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../cubit/splash_cubit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
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
              AppRouter.navigateFromNotificationLaunch(state.location);
            }
          },
          child: Scaffold(
            backgroundColor: context.colorScheme.primary,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.l10n.appTitle,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: context.colorScheme.onPrimary,
                    ),
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

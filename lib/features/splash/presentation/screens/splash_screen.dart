import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions.dart';
import '../../../../core/theme/color_scheme.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../router/app_router_config.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../cubit/splash_cubit.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SplashCubit>()..init(),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          state.when(
            initial: () {},
            loading: () {},
            authenticated: (_) {},
            unauthenticated: () {},
            error: (message) {
              ToastUtils.showErrorToast(message);
              const LoginRoute().go(context);
            },
          );
        },
        child: BlocListener<SplashCubit, SplashState>(
          listener: (context, state) {
            if (state is SplashNavigateToHome) {
              const HomeRoute().go(context);
            } else if (state is SplashNavigateToLogin) {
              const LoginRoute().go(context);
            } else if (state is SplashNavigateToOnboarding) {
              const OnboardingRoute().go(context);
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
                      fontSize: 48.sp,
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

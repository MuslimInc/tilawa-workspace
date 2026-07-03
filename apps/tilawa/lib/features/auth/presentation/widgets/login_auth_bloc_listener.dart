import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/firebase/app_check_failure.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/user_entity.dart';
import '../bloc/auth_bloc.dart';
import '../cubit/login_google_sign_in_cubit.dart';
import '../services/auth_error_messages.dart';
import '../services/login_auth_bloc_listener_policy.dart';
import '../services/auth_post_sign_in_navigation.dart';
import '../services/login_auth_bloc_transition_handler.dart';

void _logGoogleSignInButton(String message) {
  logger.d('[GoogleSignInButton] $message');
}

/// Listens for terminal login [AuthState] transitions and updates launch cubit.
class LoginAuthBlocListener extends StatelessWidget {
  const LoginAuthBlocListener({
    super.key,
    required this.child,
    required this.shouldSkipAutoSignIn,
    required this.navigateAfterAuth,
    required this.routeLocation,
  });

  final Widget child;
  final bool Function() shouldSkipAutoSignIn;
  final void Function(String location) navigateAfterAuth;
  final String Function() routeLocation;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (AuthState previous, AuthState current) {
        return shouldLoginAuthBlocListen(
          previous,
          current,
          routeLocation: routeLocation(),
        );
      },
      listener: (BuildContext context, AuthState state) {
        handleLoginAuthBlocTransition(
          state: state,
          launchCubit: context.read<LoginGoogleSignInCubit>(),
          shouldSkipAutoSignIn: shouldSkipAutoSignIn(),
          messages: LoginAuthBlocTransitionMessages(
            authErrorFallback: context.l10n.unableToSignInWithThirdPartyAccount,
            deviceRegistrationFailed: context.l10n.authDeviceRegistrationFailed,
            appCheckFailed: AppCheckUxMessages.authSignIn(context.l10n),
            serverActionOffline: context.l10n.serverActionOfflineMessage,
            noGoogleAccounts: context.l10n.googleSignInNoAccountsOnDevice,
            localizeAuthError: (String key) =>
                localizedAuthBlocErrorMessage(key, context.l10n),
          ),
          onNavigateAfterAuth: (UserEntity user) {
            unawaited(
              schedulePostAuthNavigation(
                isMounted: () => context.mounted,
                userId: user.id,
                navigate: navigateAfterAuth,
              ),
            );
          },
          showToast: (String message, TilawaFeedbackVariant variant) {
            TilawaFeedback.showToast(
              context,
              message: message,
              variant: variant,
            );
          },
          log: _logGoogleSignInButton,
        );
      },
      child: child,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../bloc/auth_bloc.dart';
import '../cubit/login_google_sign_in_cubit.dart';
import '../services/login_auth_bloc_listener_policy.dart';
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
    required this.onNavigateToHome,
  });

  final Widget child;
  final bool Function() shouldSkipAutoSignIn;
  final VoidCallback onNavigateToHome;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: shouldLoginAuthBlocListen,
      listener: (BuildContext context, AuthState state) {
        handleLoginAuthBlocTransition(
          state: state,
          launchCubit: context.read<LoginGoogleSignInCubit>(),
          shouldSkipAutoSignIn: shouldSkipAutoSignIn(),
          messages: LoginAuthBlocTransitionMessages(
            authErrorFallback: context.l10n.unableToSignInWithThirdPartyAccount,
            deviceRegistrationFailed: context.l10n.authDeviceRegistrationFailed,
            noGoogleAccounts: context.l10n.googleSignInNoAccountsOnDevice,
          ),
          onNavigateToHome: onNavigateToHome,
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

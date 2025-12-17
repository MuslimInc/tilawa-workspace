import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../router/app_router_config.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../bloc/auth_bloc.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.signIn)),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          state.when(
            initial: () {},
            loading: () {},
            authenticated: (user) {
              // Navigate to home screen on successful login
              const HomeRoute().go(context);
            },
            unauthenticated: () {},
            error: (message) {
              final AppLocalizations l10n = context.l10n;
              AppToast.show(
                context,
                message: l10n.unableToSignInWithThirdPartyAccount,
              );
            },
          );
        },
        builder: (context, state) {
          return Padding(
            padding: const .all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.welcomeToMuzakri,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.signInWithGoogleDescription,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: state is AuthLoading
                      ? null
                      : () => context.read<AuthBloc>().add(
                          const SignInWithGoogleEvent(),
                        ),
                  icon: state is AuthLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: state is AuthLoading
                      ? Text(context.l10n.signingIn)
                      : Text(context.l10n.continueWithGoogle),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Colors.black12),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

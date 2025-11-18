import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muzakri/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:muzakri/features/auth/presentation/bloc/auth_event.dart';
import 'package:muzakri/features/auth/presentation/bloc/auth_state.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';
import 'package:muzakri/router/app_router_config.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.signIn)),
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
              String displayMessage = message;
              if (message.contains('clientConfigurationError')) {
                displayMessage = AppLocalizations.of(
                  context,
                )!.googleSignInNotConfigured;
              } else if (message.contains('network_error')) {
                displayMessage = AppLocalizations.of(context)!.networkError;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(displayMessage),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            },
          );
        },
        builder: (context, state) {
          return Padding(
            padding: .all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppLocalizations.of(context)!.welcomeToMuzakri,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.signInWithGoogleDescription,
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
                      ? Text(AppLocalizations.of(context)!.signingIn)
                      : Text(AppLocalizations.of(context)!.continueWithGoogle),
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

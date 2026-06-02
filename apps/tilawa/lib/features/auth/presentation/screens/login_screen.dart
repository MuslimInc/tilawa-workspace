import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:tilawa/core/app_legal_urls.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/legal_url_launcher.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import '../../../../features/localization/presentation/bloc/localization_bloc.dart';

import '../../../../router/app_router.dart';
import '../../../../router/app_router_config.dart';
import '../bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    // Automatically trigger sign in when screen opens to improve UX
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authBloc = context.read<AuthBloc>();
        if (authBloc.state is AuthInitial ||
            authBloc.state is AuthUnauthenticated ||
            authBloc.state is AuthError) {
          authBloc.add(const SignInWithGoogleEvent());
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Stack(
        children: [
          // Language Switcher
          Positioned(
            top: context.systemTopSafeArea + context.tokens.spaceSmall,
            right: 16,
            child: const _AppLanguageSwitcher(),
          ),

          SafeArea(
            child: BlocConsumer<AuthBloc, AuthState>(
              listenWhen: (AuthState previous, AuthState current) {
                if (current is AuthAuthenticated &&
                    previous is! AuthAuthenticated) {
                  return true;
                }
                return current is AuthError && previous is! AuthError;
              },
              listener: (context, state) {
                state.when(
                  initial: () {},
                  loading: () {},
                  authenticated: (_) => _navigateToHome(context),
                  unauthenticated: () {},
                  error: (_) {
                    ToastUtils.showToast(
                      msg: context.l10n.unableToSignInWithThirdPartyAccount,
                    );
                  },
                );
              },
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      // Brand Icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_stories_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const Gap(32),

                      // Welcome Text
                      Text(
                        context.l10n.welcomeToApp,
                        style: context.textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Gap(14),

                      // Subtitle
                      Text(
                        context.l10n.signInWithGoogleDescription,
                        style: context.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),

                      // Action Button
                      _GoogleSignInButton(
                        isLoading: state is AuthLoading,
                        onPressed: () => context.read<AuthBloc>().add(
                          const SignInWithGoogleEvent(),
                        ),
                      ),
                      Gap(16),
                      _LoginLegalFooter(),
                      const Gap(48),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        return;
      }
      AppRouter.disableStateRestoration = false;
      AppRouter.router.go(const HomeRoute().location);
    });
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Theme.of(context).colorScheme.primary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: TilawaLoadingIndicator(
                  centered: false,
                  strokeWidth: 2.5,
                ),
              )
            else ...[
              SvgPicture.asset(
                'assets/icons/google_icon.svg',
                width: 24,
                height: 24,
              ),
              const Gap(12),
              Text(context.l10n.continueWithGoogle),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoginLegalFooter extends StatelessWidget {
  const _LoginLegalFooter();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => openLegalUrl(AppLegalUrls.privacyPolicy),
      child: Text(
        context.l10n.privacyPolicy,
        style: context.textTheme.bodyMedium?.copyWith(
          color: Colors.white.withValues(alpha: 0.92),
          decoration: TextDecoration.underline,
          decorationColor: Colors.white.withValues(alpha: 0.92),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _AppLanguageSwitcher extends StatelessWidget {
  const _AppLanguageSwitcher();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalizationBloc, LocalizationState>(
      builder: (context, state) {
        return TilawaLanguageSwitcher(
          currentLanguage: state.locale.languageCode,
          languages: const ['ar', 'en'],
          getLanguageName: (code) => code == 'ar' ? 'العربية' : 'English',
          onLanguageChanged: (code) {
            context.read<LocalizationBloc>().add(ChangeLanguage(Locale(code)));
          },
        );
      },
    );
  }
}

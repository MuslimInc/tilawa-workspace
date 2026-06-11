import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tilawa/core/app_legal_urls.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/legal_url_launcher.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa_core/services/app_system_chrome_style.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../router/app_router.dart';
import '../../../../router/app_router_config.dart';
import '../bloc/auth_bloc.dart';

/// Warm brown login canvas — distinct from the runtime sage primary.
const Color _kLoginAccent = AppColors.primaryBrown;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
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
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final ColorScheme loginScheme = colorScheme.copyWith(
      primary: _kLoginAccent,
      onPrimary: AppTheme.getLightTheme(
        primaryColor: _kLoginAccent,
      ).colorScheme.onPrimary,
    );
    final SystemUiOverlayStyle overlayStyle =
        AppSystemChromeStyle.buildDefaultAppStyle(
          theme,
          statusBarBackgroundColor: theme.scaffoldBackgroundColor,
          navigationBarColor: theme.scaffoldBackgroundColor,
        );

    return Theme(
      data: theme.copyWith(colorScheme: loginScheme),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: Scaffold(
          body: BlocConsumer<AuthBloc, AuthState>(
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
              return TilawaThumbReachLayout(
                useSafeArea: true,
                content: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.spaceLarge,
                  ),
                  child: TilawaContentBounds(
                    kind: TilawaContentKind.form,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Center(
                          child: Container(
                            width:
                                tokens.minInteractiveDimension * 2 +
                                tokens.spaceExtraSmall,
                            height:
                                tokens.minInteractiveDimension * 2 +
                                tokens.spaceExtraSmall,
                            decoration: BoxDecoration(
                              color: loginScheme.primary.withValues(
                                alpha: tokens.opacitySubtle,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.auto_stories_rounded,
                              size: tokens.minInteractiveDimension,
                              color: loginScheme.primary,
                            ),
                          ),
                        ),
                        SizedBox(height: tokens.spaceExtraLarge),
                        Text(
                          context.l10n.welcomeToApp,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: tokens.spaceMedium),
                        Text(
                          context.l10n.signInWithGoogleDescription,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                actions: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: tokens.spaceLarge,
                  children: <Widget>[
                    _GoogleSignInButton(
                      isLoading: state is AuthLoading,
                      onPressed: () => context.read<AuthBloc>().add(
                        const SignInWithGoogleEvent(),
                      ),
                    ),
                    const _LoginLegalFooter(),
                  ],
                ),
              );
            },
          ),
        ),
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return TilawaButton(
      text: context.l10n.continueWithGoogle,
      semanticLabel: context.l10n.continueWithGoogle,
      size: TilawaButtonSize.large,
      isFullWidth: true,
      isLoading: isLoading,
      onPressed: onPressed,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      leadingIcon: const _GoogleMark(),
    );
  }
}

/// Multicolor Google “G” — kept outside [IconTheme] tinting.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    final double size =
        IconTheme.of(context).size ?? Theme.of(context).tokens.iconSizeMedium;

    return SvgPicture.asset(
      'assets/icons/google_icon.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

class _LoginLegalFooter extends StatelessWidget {
  const _LoginLegalFooter();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;

    final ColorScheme colorScheme = theme.colorScheme;

    return TextButton(
      onPressed: () => openLegalUrl(AppLegalUrls.privacyPolicy),
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
      ),
      child: Text(
        context.l10n.privacyPolicy,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.primary,
          decoration: TextDecoration.underline,
          decorationColor: colorScheme.primary.withValues(
            alpha: tokens.opacityEmphasis,
          ),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

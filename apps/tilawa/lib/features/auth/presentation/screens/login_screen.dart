import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tilawa/core/app_legal_urls.dart';
import 'package:tilawa/core/bootstrap/splash_launch_handoff.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/core/utils/legal_url_launcher.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa_core/services/app_system_chrome_style.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../router/app_router.dart';
import '../../../../router/app_router_config.dart';
import '../../data/services/android_sign_in_platform_policy.dart';
import '../bloc/auth_bloc.dart';
import '../services/google_sign_in_interactive_launcher.dart';
import '../services/login_auto_sign_in_scheduler.dart';
import '../widgets/login_sign_in_fallback_panel.dart';

/// Warm brown login canvas — distinct from the runtime sage primary.
const Color _kLoginAccent = AppColors.primaryBrown;

void _logGoogleSignInButton(String message) {
  logger.d('[GoogleSignInButton] $message');
}

String _authStateLabel(AuthState state) {
  return state.when(
    initial: () => 'initial',
    loading: () => 'loading',
    authenticated: (_) => 'authenticated',
    unauthenticated: () => 'unauthenticated',
    error: (message) => 'error($message)',
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final LoginAutoSignInScheduler _autoSignInScheduler =
      LoginAutoSignInScheduler();
  bool _showFallbackFields = false;
  bool _signInLaunchPending = false;
  bool _awaitingManualSignInResult = false;
  String? _lastLoggedAuthStateLabel;
  bool? _lastLoggedButtonEnabled;

  @override
  void initState() {
    super.initState();
    _logGoogleSignInButton('LoginScreen initState');
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_recoverLoginSurface(reason: 'initState'));
    });
    _scheduleAutoSignInWhenReady();
  }

  @override
  void dispose() {
    _logGoogleSignInButton('LoginScreen dispose');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _logGoogleSignInButton('lifecycle=$state');
    if (state == AppLifecycleState.resumed) {
      unawaited(_recoverLoginSurface(reason: 'lifecycleResumed'));
      _recoverStalledSignIn();
      _scheduleAutoSignInWhenReady();
    }
  }

  void _revealSignInFallback() {
    if (!mounted) {
      return;
    }
    setState(() => _showFallbackFields = true);
  }

  bool _isManualSignInReason(String reason) {
    return reason == 'manualTap' || reason == 'fallbackRetry';
  }

  void _recoverStalledSignIn() {
    if (_shouldSkipAutoSignIn()) {
      // Credential Manager launches HiddenActivity; AuthLoading across
      // inactive/paused/resumed is normal. Resetting here would emit
      // unauthenticated before sign-in completes and looks like a restart.
      return;
    }
    if (!mounted) {
      return;
    }
    final AuthBloc authBloc = context.read<AuthBloc>();
    if (authBloc.state is! AuthLoading) {
      return;
    }
    _logGoogleSignInButton(
      'recoverStalledSignIn: still loading after resume → CheckAuthStatus',
    );
    authBloc.add(const CheckAuthStatusEvent());
  }

  Future<void> _recoverLoginSurface({required String reason}) async {
    final bool splashPainted = SplashLaunchHandoff.splashRouteHasPainted.value;
    _logGoogleSignInButton(
      'recoverLoginSurface reason=$reason '
      'splashRouteHasPainted=$splashPainted '
      'lifecycle=${WidgetsBinding.instance.lifecycleState}',
    );
    if (!splashPainted) {
      _logGoogleSignInButton(
        'recoverLoginSurface forcing splashRouteHasPainted=true '
        '(BootGate overlay may have blocked touches)',
      );
      SplashLaunchHandoff.markSplashRoutePainted();
    }
  }

  void _scheduleAutoSignInWhenReady() {
    _autoSignInScheduler.scheduleWhenReady(
      warmUpPolicy: _warmUpSignInPolicy,
      shouldSkipAutoSignIn: _shouldSkipAutoSignIn,
      isMounted: () => mounted,
      isRouteCurrent: () => ModalRoute.of(context)?.isCurrent ?? false,
      lifecycleState: () => WidgetsBinding.instance.lifecycleState,
      onAutoSignIn: _maybeAutoSignIn,
      log: _logGoogleSignInButton,
    );
  }

  Future<void> _warmUpSignInPolicy() {
    if (!getIt.isRegistered<AndroidSignInPlatformPolicy>()) {
      return Future<void>.value();
    }
    return getIt<AndroidSignInPlatformPolicy>().warmUp();
  }

  bool _shouldSkipAutoSignIn() {
    if (!getIt.isRegistered<AndroidSignInPlatformPolicy>()) {
      return false;
    }
    return getIt<AndroidSignInPlatformPolicy>().skipAutomaticSignIn;
  }

  void _maybeAutoSignIn() {
    final AuthBloc authBloc = context.read<AuthBloc>();
    final AuthState authState = authBloc.state;
    final String stateLabel = _authStateLabel(authState);
    final bool willDispatch =
        authState is AuthInitial ||
        authState is AuthUnauthenticated ||
        authState is AuthError;
    _logGoogleSignInButton(
      'maybeAutoSignIn authState=$stateLabel willDispatch=$willDispatch',
    );
    if (willDispatch) {
      unawaited(_launchInteractiveSignIn(reason: 'auto'));
    }
  }

  Future<void> _onGoogleSignInPressed() async {
    final AuthBloc authBloc = context.read<AuthBloc>();
    _logGoogleSignInButton(
      'manual tap authState=${_authStateLabel(authBloc.state)}',
    );
    await _launchInteractiveSignIn(reason: 'manualTap');
  }

  /// Defers sign-in until frames settle; checks [supportsAuthenticate] first.
  Future<void> _launchInteractiveSignIn({required String reason}) async {
    if (_signInLaunchPending) {
      _logGoogleSignInButton(
        'launchInteractiveSignIn skipped: already pending',
      );
      return;
    }
    if (!getIt.isRegistered<GoogleSignInInteractiveLauncher>()) {
      _dispatchSignInWithGoogle(reason: reason);
      return;
    }

    _signInLaunchPending = true;
    if (mounted) {
      setState(() => _showFallbackFields = false);
    }

    final GoogleSignInInteractiveLauncher launcher =
        getIt<GoogleSignInInteractiveLauncher>();

    try {
      await launcher.runAfterUiSettled(() async {
        if (!mounted) {
          return;
        }
        final GoogleSignInLaunchReadiness readiness = await launcher
            .checkReadiness();
        if (!mounted) {
          return;
        }
        switch (readiness) {
          case GoogleSignInLaunchReady():
            _dispatchSignInWithGoogle(reason: reason);
          case GoogleSignInLaunchUiUnavailable():
            _logGoogleSignInButton(
              'launchInteractiveSignIn uiUnavailable reason=$reason',
            );
            setState(() => _showFallbackFields = true);
          case GoogleSignInLaunchPlatformError(:final exception):
            _logGoogleSignInButton(
              'launchInteractiveSignIn platformError=${exception.code} '
              'reason=$reason',
            );
            setState(() => _showFallbackFields = true);
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _signInLaunchPending = false;
        });
      } else {
        _signInLaunchPending = false;
      }
    }
  }

  void _dispatchSignInWithGoogle({required String reason}) {
    if (_isManualSignInReason(reason)) {
      _awaitingManualSignInResult = true;
    }
    context.read<AuthBloc>().add(const SignInWithGoogleEvent());
    _logGoogleSignInButton(
      'dispatched SignInWithGoogleEvent reason=$reason',
    );
  }

  void _onFallbackRetry() {
    _logGoogleSignInButton('fallback retry tapped');
    unawaited(_launchInteractiveSignIn(reason: 'fallbackRetry'));
  }

  bool _shouldRevealFallbackPanel(AuthState state) {
    return state is AuthError;
  }

  void _logButtonStateIfChanged(bool isLoading) {
    final bool enabled = !isLoading;
    if (_lastLoggedButtonEnabled == enabled) {
      return;
    }
    _lastLoggedButtonEnabled = enabled;
    _logGoogleSignInButton('button isLoading=$isLoading enabled=$enabled');
  }

  void _logAuthStateIfChanged(AuthState state) {
    final String label = _authStateLabel(state);
    if (_lastLoggedAuthStateLabel == label) {
      return;
    }
    _lastLoggedAuthStateLabel = label;
    _logGoogleSignInButton(
      'authState=$label buttonEnabled=${state is! AuthLoading}',
    );
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
              if (current is AuthError && previous is! AuthError) {
                return true;
              }
              return current is AuthUnauthenticated && previous is AuthLoading;
            },
            listener: (context, state) {
              _logGoogleSignInButton(
                'listener transition authState=${_authStateLabel(state)}',
              );
              state.when(
                initial: () {},
                loading: () {},
                authenticated: (_) {
                  _awaitingManualSignInResult = false;
                  _navigateToHome(context);
                },
                unauthenticated: () {
                  if (_awaitingManualSignInResult && _shouldSkipAutoSignIn()) {
                    _logGoogleSignInButton(
                      'manual sign-in cancelled (invisible picker / back)',
                    );
                    _awaitingManualSignInResult = false;
                    _revealSignInFallback();
                  }
                },
                error: (message) {
                  _awaitingManualSignInResult = false;
                  if (_shouldRevealFallbackPanel(state)) {
                    _revealSignInFallback();
                  }
                  ToastUtils.showToast(
                    msg: message.isNotEmpty
                        ? message
                        : context.l10n.unableToSignInWithThirdPartyAccount,
                  );
                },
              );
            },
            builder: (context, state) {
              _logAuthStateIfChanged(state);
              final bool isLoading = state is AuthLoading;
              _logButtonStateIfChanged(isLoading);
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
                actions: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: tokens.spaceMedium,
                    children: <Widget>[
                      if (_showFallbackFields)
                        LoginSignInFallbackPanel(onRetry: _onFallbackRetry)
                      else
                        Listener(
                          onPointerDown: (_) {
                            _logGoogleSignInButton(
                              'pointerDown on button (isLoading=$isLoading)',
                            );
                          },
                          child: _GoogleSignInButton(
                            isLoading: isLoading || _signInLaunchPending,
                            onPressed: isLoading || _signInLaunchPending
                                ? null
                                : () => unawaited(_onGoogleSignInPressed()),
                          ),
                        ),
                      const _LoginLegalFooter(),
                    ],
                  ),
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
  const _GoogleSignInButton({required this.isLoading, this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return TilawaButton(
      text: context.l10n.continueWithGoogle,
      semanticLabel: context.l10n.continueWithGoogle,
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

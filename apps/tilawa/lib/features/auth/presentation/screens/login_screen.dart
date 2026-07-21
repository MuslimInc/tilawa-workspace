import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/bootstrap/splash_launch_handoff.dart';
import 'package:tilawa/core/widgets/deferred_after_first_frame.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/services/app_system_chrome_style.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'package:go_router/go_router.dart';
import '../../../../router/app_router.dart';
import '../../../../router/app_router_config.dart';
import '../../../localization/presentation/widgets/app_language_switcher.dart';
import '../../data/services/android_sign_in_platform_policy.dart';
import '../../data/services/google_sign_in_session_tracker.dart';
import '../../domain/entities/google_sign_in_launch_readiness.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/gateways/google_sign_in_launch_gateway.dart';
import '../../domain/usecases/resolve_google_sign_in_launch_use_case.dart';
import '../bloc/auth_bloc.dart';
import '../cubit/login_google_sign_in_cubit.dart';
import '../services/auth_post_sign_in_navigation.dart';
import '../services/login_auth_bloc_transition_handler.dart';
import '../services/login_auth_state_diagnostics.dart';
import '../services/login_navigate_to_home_scheduler.dart';
import '../widgets/login_auth_bloc_listener.dart';

/// Reference teal login canvas aligned with the brand-locked primary.
void _logGoogleSignInButton(String message) {
  logger.d('[GoogleSignInButton] $message');
}

GoogleSignInLaunchGateway? _resolveGoogleSignInLaunchGateway() {
  if (!getIt.isRegistered<GoogleSignInLaunchGateway>()) {
    return null;
  }
  return getIt<GoogleSignInLaunchGateway>();
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LoginGoogleSignInCubit>(
      create: (_) =>
          getIt<LoginGoogleSignInCubit>()
            ..prewarm(gateway: _resolveGoogleSignInLaunchGateway()),
      child: const _LoginScreenBody(),
    );
  }
}

class _LoginScreenBody extends StatefulWidget {
  const _LoginScreenBody();

  @override
  State<_LoginScreenBody> createState() => _LoginScreenBodyState();
}

class _LoginScreenBodyState extends State<_LoginScreenBody>
    with WidgetsBindingObserver {
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
      _maybeNavigateIfAlreadyAuthenticated();
    });
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
    }
  }

  void _recoverStalledSignIn() {
    if (_isGoogleSignInSessionInFlight()) {
      _logGoogleSignInButton(
        'recoverStalledSignIn skipped: interactive sign-in in flight',
      );
      return;
    }
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

  void _maybeNavigateIfAlreadyAuthenticated() {
    final GoRouter? router = GoRouter.maybeOf(context);
    handleExistingAuthenticatedLoginSession(
      state: context.read<AuthBloc>().state,
      routeLocation: router?.state.uri.path ?? const LoginRoute().location,
      onNavigateAfterAuth: (UserEntity user) {
        unawaited(
          schedulePostAuthNavigation(
            isMounted: () => mounted,
            userId: user.id,
            navigate: _navigateAfterAuth,
          ),
        );
      },
    );
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

  bool _shouldSkipAutoSignIn() {
    if (!getIt.isRegistered<AndroidSignInPlatformPolicy>()) {
      return false;
    }
    return getIt<AndroidSignInPlatformPolicy>().skipAutomaticSignIn;
  }

  bool _isGoogleSignInSessionInFlight() {
    if (!getIt.isRegistered<GoogleSignInSessionTracker>()) {
      return false;
    }
    return getIt<GoogleSignInSessionTracker>().inFlight;
  }

  Future<void> _onGoogleSignInPressed() async {
    final AuthBloc authBloc = context.read<AuthBloc>();
    _logGoogleSignInButton(
      'manual tap authState=${loginAuthStateLabel(authBloc.state)}',
    );
    await _launchInteractiveSignIn(trigger: GoogleSignInLaunchTrigger.manual);
  }

  void _onAppleSignInPressed() {
    _logGoogleSignInButton('manual Apple sign-in tap');
    context.read<AuthBloc>().add(const SignInWithAppleEvent());
  }

  Future<void> _launchInteractiveSignIn({
    required GoogleSignInLaunchTrigger trigger,
  }) async {
    final LoginGoogleSignInCubit launchCubit = context
        .read<LoginGoogleSignInCubit>();
    await launchCubit.attemptLaunch(
      trigger: trigger,
      gateway: _resolveGoogleSignInLaunchGateway(),
    );

    if (!mounted) {
      return;
    }

    final LoginGoogleSignInAttempt? attempt = launchCubit.state.launchAttempt;
    if (attempt == null) {
      return;
    }

    switch (attempt) {
      case LoginGoogleSignInAllowed(:final manual):
        _dispatchSignInWithGoogle(manual: manual, trigger: trigger);
      case LoginGoogleSignInRejected(:final readiness):
        _showLaunchBlockedFeedback(readiness, trigger: trigger);
      case LoginGoogleSignInBlocked(:final failure):
        _showServerActionBlockedFeedback(failure, trigger: trigger);
    }
    launchCubit.clearLaunchAttempt();
  }

  void _showServerActionBlockedFeedback(
    Failure failure, {
    required GoogleSignInLaunchTrigger trigger,
  }) {
    _logGoogleSignInButton(
      'launchInteractiveSignIn serverActionBlocked reason=$trigger',
    );
    if (trigger != GoogleSignInLaunchTrigger.manual) {
      return;
    }
    TilawaFeedback.showToast(
      context,
      message:
          failure.localizedMessage(context) ??
          context.l10n.serverActionOfflineMessage,
      variant: TilawaFeedbackVariant.error,
    );
  }

  void _showLaunchBlockedFeedback(
    GoogleSignInLaunchReadiness readiness, {
    required GoogleSignInLaunchTrigger trigger,
  }) {
    switch (readiness) {
      case GoogleSignInLaunchReady():
        return;
      case GoogleSignInLaunchUiUnavailable():
        _logGoogleSignInButton(
          'launchInteractiveSignIn uiUnavailable reason=$trigger',
        );
        TilawaFeedback.showToast(
          context,
          message: context.l10n.googleSignInFallbackBody,
          variant: TilawaFeedbackVariant.error,
        );
      case GoogleSignInLaunchPlatformError(:final code, :final message):
        _logGoogleSignInButton(
          'launchInteractiveSignIn platformError reason=$trigger '
          'code=$code detail=$message',
        );
        TilawaFeedback.showToast(
          context,
          message: context.l10n.authErrorGenericMessage,
          variant: TilawaFeedbackVariant.error,
        );
    }
  }

  void _dispatchSignInWithGoogle({
    required bool manual,
    required GoogleSignInLaunchTrigger trigger,
  }) {
    context.read<AuthBloc>().add(const SignInWithGoogleEvent());
    _logGoogleSignInButton(
      'dispatched SignInWithGoogleEvent reason=$trigger manual=$manual',
    );
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
    final String label = loginAuthStateLabel(state);
    if (_lastLoggedAuthStateLabel == label) {
      return;
    }
    _lastLoggedAuthStateLabel = label;
    _logGoogleSignInButton(
      'authState=$label buttonEnabled=${loginAuthButtonEnabled(state)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final MeMuslimProductColors product = theme.productColors;
    final ColorScheme loginScheme = colorScheme.copyWith(
      primary: product.brandLockedPrimary,
      onPrimary: product.brandLockedOnPrimary,
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
          body: Stack(
            children: <Widget>[
              LoginAuthBlocListener(
                shouldSkipAutoSignIn: _shouldSkipAutoSignIn,
                navigateAfterAuth: _navigateAfterAuth,
                routeLocation: () {
                  final GoRouter? router = GoRouter.maybeOf(context);
                  return router?.state.uri.path ?? const LoginRoute().location;
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: SafeArea(
                        bottom: false,
                        child: RepaintBoundary(
                          child: _LoginHeroContent(loginScheme: loginScheme),
                        ),
                      ),
                    ),
                    TilawaBottomActionInset(
                      top: tokens.spaceLarge,
                      maxWidthKind: TilawaContentKind.form,
                      child: DeferredAfterFirstFrame(
                        perfEvent: 'login_actions',
                        child: _LoginGoogleSignInActions(
                          onPressed: _onGoogleSignInPressed,
                          onApplePressed: _onAppleSignInPressed,
                          logButtonStateIfChanged: _logButtonStateIfChanged,
                          logAuthStateIfChanged: _logAuthStateIfChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const _LoginLanguageSwitcherBar(),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateAfterAuth(String location) {
    scheduleLoginNavigateToHome(
      isMounted: () => mounted,
      navigate: () {
        AppRouter.disableStateRestoration = false;
        AppRouter.router.go(location);
      },
    );
  }
}

class _LoginHeroContent extends StatelessWidget {
  const _LoginHeroContent({required this.loginScheme});

  final ColorScheme loginScheme;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spaceLarge),
      child: TilawaContentBounds(
        kind: TilawaContentKind.form,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: tokens.spaceMedium,
          children: <Widget>[
            Center(
              child: TilawaAppBrandBadge(accentColor: loginScheme.primary),
            ),
            Text(
              context.l10n.welcomeToApp,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              Platform.isIOS
                  ? context.l10n.signInWithAppleDescription
                  : context.l10n.signInWithGoogleDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Top-trailing locale control for returning unauthenticated users.
class _LoginLanguageSwitcherBar extends StatelessWidget {
  const _LoginLanguageSwitcherBar();

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;
    final EdgeInsets viewPadding = MediaQuery.paddingOf(context);

    return Positioned.directional(
      textDirection: Directionality.of(context),
      top: viewPadding.top + tokens.spaceSmall,
      end: tokens.spaceLarge,
      child: const AppLanguageSwitcher(compact: true),
    );
  }
}

class _LoginGoogleSignInActions extends StatefulWidget {
  const _LoginGoogleSignInActions({
    required this.onPressed,
    required this.onApplePressed,
    required this.logButtonStateIfChanged,
    required this.logAuthStateIfChanged,
  });

  final Future<void> Function() onPressed;
  final VoidCallback onApplePressed;
  final void Function(bool isLoading) logButtonStateIfChanged;
  final void Function(AuthState state) logAuthStateIfChanged;

  @override
  State<_LoginGoogleSignInActions> createState() =>
      _LoginGoogleSignInActionsState();
}

class _LoginGoogleSignInActionsState extends State<_LoginGoogleSignInActions>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-read [GoogleSignInSessionTracker.inFlight] after native sheets.
      setState(() {});
    }
  }

  bool _isGoogleSignInSessionInFlight() {
    if (!getIt.isRegistered<GoogleSignInSessionTracker>()) {
      return false;
    }
    return getIt<GoogleSignInSessionTracker>().inFlight;
  }

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // OAuth cluster — tight proximity; Apple stays first on iOS.
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: tokens.spaceSmall,
          children: <Widget>[
            if (Platform.isIOS)
              RepaintBoundary(
                child: BlocBuilder<AuthBloc, AuthState>(
                  buildWhen: loginAuthAffectsGoogleSignInButtonLoading,
                  builder: (BuildContext context, AuthState authState) {
                    return BlocBuilder<
                      LoginGoogleSignInCubit,
                      LoginGoogleSignInState
                    >(
                      buildWhen: loginLaunchAffectsGoogleSignInButtonLoading,
                      builder:
                          (
                            BuildContext context,
                            LoginGoogleSignInState launchState,
                          ) {
                            final bool isLoading = loginSignInButtonsLoading(
                              authState: authState,
                              isLaunchPending: launchState.isLaunchPending,
                              sessionInFlight: _isGoogleSignInSessionInFlight(),
                            );
                            return TilawaAppleSignInButton(
                              label: context.l10n.continueWithApple,
                              semanticLabel: context.l10n.continueWithApple,
                              appearance: AppleSignInButtonAppearance.black,
                              isLoading: isLoading,
                              onPressed: isLoading
                                  ? null
                                  : widget.onApplePressed,
                            );
                          },
                    );
                  },
                ),
              ),
            RepaintBoundary(
              child: BlocBuilder<AuthBloc, AuthState>(
                buildWhen: loginAuthAffectsGoogleSignInButtonLoading,
                builder: (BuildContext context, AuthState authState) {
                  widget.logAuthStateIfChanged(authState);
                  return BlocBuilder<
                    LoginGoogleSignInCubit,
                    LoginGoogleSignInState
                  >(
                    buildWhen: loginLaunchAffectsGoogleSignInButtonLoading,
                    builder:
                        (
                          BuildContext context,
                          LoginGoogleSignInState launchState,
                        ) {
                          final bool isLoading = loginSignInButtonsLoading(
                            authState: authState,
                            isLaunchPending: launchState.isLaunchPending,
                            sessionInFlight: _isGoogleSignInSessionInFlight(),
                          );
                          widget.logButtonStateIfChanged(isLoading);
                          return Listener(
                            onPointerDown: (_) {
                              _logGoogleSignInButton(
                                'pointerDown on button (isLoading=$isLoading)',
                              );
                            },
                            child: TilawaGoogleSignInButton(
                              label: context.l10n.continueWithGoogle,
                              semanticLabel: context.l10n.continueWithGoogle,
                              appearance: GoogleSignInButtonAppearance.dark,
                              isLoading: isLoading,
                              onPressed: isLoading
                                  ? null
                                  : () => unawaited(widget.onPressed()),
                            ),
                          );
                        },
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.spaceLarge),
        _LoginEmailAuthLinks(
          sessionInFlight: _isGoogleSignInSessionInFlight(),
        ),
      ],
    );
  }
}

class _LoginEmailAuthLinks extends StatelessWidget {
  const _LoginEmailAuthLinks({required this.sessionInFlight});

  final bool sessionInFlight;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (BuildContext context, AuthState authState) {
        final bool isLoading = loginSignInButtonsLoading(
          authState: authState,
          isLaunchPending: false,
          sessionInFlight: sessionInFlight,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: tokens.spaceSmall,
          children: <Widget>[
            // Email cluster — secondary path under OAuth.
            Row(
              children: <Widget>[
                Expanded(child: Divider(color: theme.dividerColor)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: tokens.spaceSmall),
                  child: Text(
                    context.l10n.orContinueWith,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: theme.dividerColor)),
              ],
            ),
            TilawaButton(
              text: context.l10n.signInWithEmail,
              variant: TilawaButtonVariant.outline,
              isFullWidth: true,
              onPressed: isLoading
                  ? null
                  : () => context.push(const EmailLoginRoute().location),
            ),
            TilawaButton(
              text: context.l10n.noAccountYet,
              variant: TilawaButtonVariant.ghost,
              isFullWidth: true,
              onPressed: isLoading
                  ? null
                  : () => context.push(const RegisterRoute().location),
            ),
          ],
        );
      },
    );
  }
}

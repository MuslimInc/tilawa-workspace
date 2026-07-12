import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../router/app_router.dart';
import '../../../../router/app_router_config.dart';
import '../../domain/entities/email_auth_failure_key.dart';
import '../../domain/entities/email_registration_step.dart';
import '../bloc/auth_bloc.dart';
import '../cubit/email_auth_form_cubit.dart';
import '../cubit/email_registration_cubit.dart';
import '../cubit/email_registration_state.dart';
import '../cubit/forgot_password_cubit.dart';
import '../services/auth_error_messages.dart';
import '../services/auth_post_sign_in_navigation.dart';
import '../services/email_auth_error_messages.dart';
import '../services/login_navigate_to_home_scheduler.dart';
import '../widgets/email_auth_fields.dart';
import '../widgets/email_registration_step_indicator.dart';
import '../widgets/email_registration_steps.dart';

class EmailLoginScreen extends StatelessWidget {
  const EmailLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EmailAuthFormCubit>(
      create: (_) => getIt<EmailAuthFormCubit>(),
      child: const _EmailLoginBody(),
    );
  }
}

class _EmailLoginBody extends StatelessWidget {
  const _EmailLoginBody();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (AuthState previous, AuthState current) {
        return previous != current &&
            (current is AuthAuthenticated || current is AuthError);
      },
      listener: (BuildContext context, AuthState state) {
        if (state is AuthAuthenticated) {
          unawaited(
            schedulePostAuthNavigation(
              isMounted: () => context.mounted,
              userId: state.user.id,
              navigate: (String location) {
                scheduleLoginNavigateToHome(
                  isMounted: () => context.mounted,
                  navigate: () {
                    AppRouter.disableStateRestoration = false;
                    AppRouter.router.go(location);
                  },
                );
              },
            ),
          );
          return;
        }
        if (state is AuthError) {
          TilawaFeedback.showToast(
            context,
            message: localizedAuthBlocErrorMessage(
              state.message,
              context.l10n,
            ),
            variant: TilawaFeedbackVariant.error,
          );
        }
      },
      child: Scaffold(
        appBar: TilawaAppBar(title: context.l10n.signInWithEmail),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: tokens.spaceLarge),
                  child: TilawaContentBounds(
                    kind: TilawaContentKind.form,
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.only(
                        top: tokens.spaceLarge,
                        bottom: tokens.spaceMedium,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: tokens.spaceMedium,
                        children: <Widget>[
                          Text(
                            context.l10n.signInWithEmailDescription,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const EmailAuthFields(
                            showConfirmPassword: false,
                            enabled: true,
                          ),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton(
                              onPressed: () => context.push(
                                const ForgotPasswordRoute().location,
                              ),
                              child: Text(context.l10n.forgotPassword),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            TilawaBottomActionInset(
              top: tokens.spaceLarge,
              maxWidthKind: TilawaContentKind.form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: tokens.spaceSmall,
                children: <Widget>[
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (BuildContext context, AuthState authState) {
                      final bool isLoading = authState is AuthLoading;
                      return TilawaButton(
                        text: context.l10n.signIn,
                        isLoading: isLoading,
                        isFullWidth: true,
                        onPressed: isLoading ? null : () => _submit(context),
                      );
                    },
                  ),
                  TextButton(
                    onPressed: () => context.push(
                      const RegisterRoute().location,
                    ),
                    child: Text(context.l10n.noAccountYet),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    final EmailAuthFormCubit formCubit = context.read<EmailAuthFormCubit>();
    formCubit.validateForLogin();
    final EmailAuthFormState form = formCubit.state;
    if (!form.isLoginValid) {
      return;
    }
    context.read<AuthBloc>().add(
      AuthEvent.signInWithEmail(
        email: form.email.trim(),
        password: form.password,
      ),
    );
  }
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<EmailRegistrationCubit>(
          create: (_) => getIt<EmailRegistrationCubit>(),
        ),
      ],
      child: const _RegisterBody(),
    );
  }
}

class _RegisterBody extends StatefulWidget {
  const _RegisterBody();

  @override
  State<_RegisterBody> createState() => _RegisterBodyState();
}

class _RegisterBodyState extends State<_RegisterBody> {
  bool _registrationSubmitInFlight = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;

    return MultiBlocListener(
      listeners: <BlocListener<dynamic, dynamic>>[
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (AuthState previous, AuthState current) {
            if (!_registrationSubmitInFlight) {
              return false;
            }
            return previous != current &&
                (current is AuthAuthenticated || current is AuthError);
          },
          listener: (BuildContext context, AuthState state) async {
            if (state is AuthAuthenticated) {
              _registrationSubmitInFlight = false;
              final EmailRegistrationCubit cubit = context
                  .read<EmailRegistrationCubit>();
              if (cubit.state.status ==
                  EmailRegistrationStatus.profilePersistenceFailed) {
                return;
              }
              if (!context.mounted) {
                return;
              }
              unawaited(
                schedulePostAuthNavigation(
                  isMounted: () => context.mounted,
                  userId: state.user.id,
                  navigate: (String location) {
                    scheduleLoginNavigateToHome(
                      isMounted: () => context.mounted,
                      navigate: () {
                        AppRouter.disableStateRestoration = false;
                        AppRouter.router.go(location);
                      },
                    );
                  },
                ),
              );
              return;
            }
            if (state is AuthError) {
              _registrationSubmitInFlight = false;
              final EmailRegistrationCubit cubit = context
                  .read<EmailRegistrationCubit>();
              final bool isDuplicateEmail =
                  state.message == EmailAuthFailureKey.emailAlreadyInUse ||
                  state.message ==
                      EmailAuthFailureKey.emailAlreadyInUseWithGoogle;
              cubit.onRegistrationAuthFailed(
                emailErrorKey: isDuplicateEmail ? state.message : null,
              );
              if (!context.mounted) {
                return;
              }
              TilawaFeedback.showToast(
                context,
                message: localizedAuthBlocErrorMessage(
                  state.message,
                  context.l10n,
                ),
                variant: TilawaFeedbackVariant.error,
              );
            }
          },
        ),
      ],
      child: BlocBuilder<EmailRegistrationCubit, EmailRegistrationState>(
        builder: (BuildContext context, EmailRegistrationState regState) {
          return Scaffold(
            appBar: TilawaAppBar(
              title: context.l10n.createAccount,
              leading: regState.canGoBack
                  ? BackButton(
                      onPressed: regState.isSubmitting
                          ? null
                          : () =>
                                context.read<EmailRegistrationCubit>().goBack(),
                    )
                  : null,
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: tokens.spaceLarge,
                      ),
                      child: TilawaContentBounds(
                        kind: TilawaContentKind.form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: tokens.spaceLarge,
                          children: <Widget>[
                            EmailRegistrationStepIndicator(
                              currentStep: regState.currentStepDisplayIndex,
                              totalSteps: regState.visibleStepCount,
                              stepLabel: context.l10n.registrationStepProgress(
                                regState.currentStepDisplayIndex,
                                regState.visibleStepCount,
                                registrationStepLabel(
                                  context,
                                  regState.currentStep,
                                ),
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding: EdgeInsets.only(
                                  bottom: tokens.spaceMedium,
                                ),
                                child: _RegistrationStepBody(
                                  step: regState.currentStep,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                TilawaBottomActionInset(
                  top: tokens.spaceLarge,
                  maxWidthKind: TilawaContentKind.form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: tokens.spaceSmall,
                    children: <Widget>[
                      if (regState.status ==
                          EmailRegistrationStatus.profilePersistenceFailed)
                        Text(
                          context.l10n.registrationProfilePersistenceFailed,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (BuildContext context, AuthState authState) {
                          final bool isLoading =
                              authState is AuthLoading || regState.isSubmitting;
                          final bool isReview =
                              regState.currentStep ==
                              EmailRegistrationStep.review;
                          final bool isRetry =
                              regState.status ==
                              EmailRegistrationStatus.profilePersistenceFailed;

                          return TilawaButton(
                            text: isRetry
                                ? context.l10n.registrationRetryProfileSave
                                : isReview
                                ? context.l10n.createAccount
                                : context.l10n.continueButton,
                            isLoading: isLoading,
                            isFullWidth: true,
                            onPressed: isLoading
                                ? null
                                : () => _onPrimaryAction(context, regState),
                          );
                        },
                      ),
                      TextButton(
                        onPressed: () => context.push(
                          const EmailLoginRoute().location,
                        ),
                        child: Text(context.l10n.alreadyHaveAccount),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _onPrimaryAction(
    BuildContext context,
    EmailRegistrationState regState,
  ) async {
    final EmailRegistrationCubit cubit = context.read<EmailRegistrationCubit>();

    if (regState.status == EmailRegistrationStatus.profilePersistenceFailed) {
      await cubit.retryProfilePersistence();
      if (!context.mounted) {
        return;
      }
      final EmailRegistrationState retried = cubit.state;
      // Completed retries emit editing and clear the authenticated user;
      // persistence failures keep the failed status.
      if (retried.status == EmailRegistrationStatus.editing &&
          retried.authenticatedUser == null) {
        context.read<AuthBloc>().add(const AuthEvent.checkAuthStatus());
      }
      if (retried.status == EmailRegistrationStatus.profilePersistenceFailed) {
        TilawaFeedback.showToast(
          context,
          message: context.l10n.registrationProfilePersistenceFailed,
          variant: TilawaFeedbackVariant.error,
        );
      }
      return;
    }

    if (regState.currentStep == EmailRegistrationStep.review) {
      cubit.validateCurrentStep();
      if (!cubit.state.isCurrentStepValid) {
        return;
      }
      _registrationSubmitInFlight = true;
      context.read<AuthBloc>().add(
        AuthEvent.registerWithEmail(draft: cubit.state.draft),
      );
      return;
    }

    cubit.goNext();
  }
}

class _RegistrationStepBody extends StatelessWidget {
  const _RegistrationStepBody({required this.step});

  final EmailRegistrationStep step;

  @override
  Widget build(BuildContext context) {
    return switch (step) {
      EmailRegistrationStep.account => const EmailRegistrationAccountStep(),
      EmailRegistrationStep.personal => const EmailRegistrationPersonalStep(),
      EmailRegistrationStep.review => const EmailRegistrationReviewStep(),
    };
  }
}

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ForgotPasswordCubit>(
      create: (_) => getIt<ForgotPasswordCubit>(),
      child: BlocProvider<EmailAuthFormCubit>(
        create: (_) => getIt<EmailAuthFormCubit>(),
        child: const _ForgotPasswordBody(),
      ),
    );
  }
}

class _ForgotPasswordBody extends StatelessWidget {
  const _ForgotPasswordBody();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;

    return MultiBlocListener(
      listeners: <BlocListener<dynamic, dynamic>>[
        BlocListener<ForgotPasswordCubit, ForgotPasswordState>(
          listener: (BuildContext context, ForgotPasswordState state) {
            if (state is ForgotPasswordSuccess) {
              TilawaFeedback.showToast(
                context,
                message: context.l10n.authResetEmailSent,
                variant: TilawaFeedbackVariant.success,
              );
              context.pop();
            }
            if (state is ForgotPasswordFailure) {
              TilawaFeedback.showToast(
                context,
                message: localizedAuthBlocErrorMessage(
                  state.messageKey,
                  context.l10n,
                ),
                variant: TilawaFeedbackVariant.error,
              );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: TilawaAppBar(title: context.l10n.forgotPassword),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: tokens.spaceLarge),
                  child: TilawaContentBounds(
                    kind: TilawaContentKind.form,
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.only(
                        top: tokens.spaceLarge,
                        bottom: tokens.spaceMedium,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: tokens.spaceLarge,
                        children: <Widget>[
                          Text(
                            context.l10n.forgotPasswordDescription,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          BlocBuilder<EmailAuthFormCubit, EmailAuthFormState>(
                            builder:
                                (
                                  BuildContext context,
                                  EmailAuthFormState state,
                                ) {
                                  return TilawaTextField(
                                    label: context.l10n.emailAddress,
                                    keyboardType: TextInputType.emailAddress,
                                    enabled:
                                        context
                                                .watch<ForgotPasswordCubit>()
                                                .state
                                            is! ForgotPasswordSubmitting,
                                    onChanged: context
                                        .read<EmailAuthFormCubit>()
                                        .emailChanged,
                                    errorText: localizedEmailAuthFieldError(
                                      state.emailErrorKey,
                                      context.l10n,
                                    ),
                                  );
                                },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            TilawaBottomActionInset(
              top: tokens.spaceLarge,
              maxWidthKind: TilawaContentKind.form,
              child: BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
                builder: (BuildContext context, ForgotPasswordState state) {
                  final bool isLoading = state is ForgotPasswordSubmitting;
                  return TilawaButton(
                    text: context.l10n.sendResetLink,
                    isLoading: isLoading,
                    isFullWidth: true,
                    onPressed: isLoading ? null : () => _submit(context),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    final EmailAuthFormCubit formCubit = context.read<EmailAuthFormCubit>();
    formCubit.validateEmailOnly();
    if (formCubit.state.emailErrorKey != null) {
      return;
    }
    context.read<ForgotPasswordCubit>().submit(
      email: formCubit.state.email.trim(),
    );
  }
}

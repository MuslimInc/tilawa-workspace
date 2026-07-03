import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../router/app_router.dart';
import '../../../../router/app_router_config.dart';
import '../bloc/auth_bloc.dart';
import '../cubit/email_auth_form_cubit.dart';
import '../cubit/forgot_password_cubit.dart';
import '../services/auth_error_messages.dart';
import '../services/email_auth_error_messages.dart';
import '../services/auth_post_sign_in_navigation.dart';
import '../services/login_navigate_to_home_scheduler.dart';
import '../../domain/entities/email_registration_step.dart';
import '../../domain/entities/register_with_email_result.dart';
import '../cubit/email_registration_cubit.dart';
import '../cubit/email_registration_state.dart';
import '../widgets/email_registration_step_indicator.dart';
import '../widgets/email_registration_steps.dart';
import '../widgets/email_auth_fields.dart';

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
        appBar: AppBar(title: Text(context.l10n.signInWithEmail)),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(tokens.spaceLarge),
            child: TilawaContentBounds(
              kind: TilawaContentKind.form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    context.l10n.signInWithEmailDescription,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: tokens.spaceLarge),
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
                  SizedBox(height: tokens.spaceMedium),
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
                  SizedBox(height: tokens.spaceMedium),
                  TextButton(
                    onPressed: () => context.push(
                      const RegisterRoute().location,
                    ),
                    child: Text(context.l10n.noAccountYet),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    final EmailAuthFormCubit formCubit = context.read<EmailAuthFormCubit>();
    if (!formCubit.validateForLogin()) {
      return;
    }
    final EmailAuthFormState form = formCubit.state;
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
          create: (_) => getIt<EmailRegistrationCubit>()..initialize(),
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
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;

    return MultiBlocListener(
      listeners: <BlocListener<dynamic, dynamic>>[
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (AuthState previous, AuthState current) {
            return previous != current &&
                (current is AuthAuthenticated || current is AuthError);
          },
          listener: (BuildContext context, AuthState state) async {
            if (state is AuthAuthenticated) {
              final EmailRegistrationCubit cubit = context
                  .read<EmailRegistrationCubit>();
              if (cubit.state.status ==
                  EmailRegistrationStatus.profilePersistenceFailed) {
                return;
              }
              if (cubit.state.currentStep == EmailRegistrationStep.review &&
                  getIt.isRegistered<GetUserProfileUseCase>()) {
                final profileResult = await getIt<GetUserProfileUseCase>()(
                  state.user.id,
                );
                final bool profileIncomplete = profileResult.fold(
                  (_) => true,
                  (UserProfile profile) => !profile.isComplete,
                );
                if (profileIncomplete && context.mounted) {
                  cubit.markProfilePersistenceFailed(state.user);
                  TilawaFeedback.showToast(
                    context,
                    message: context.l10n.registrationProfilePersistenceFailed,
                    variant: TilawaFeedbackVariant.error,
                  );
                  return;
                }
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
          if (regState.isLoadingMarketData) {
            return Scaffold(
              appBar: AppBar(title: Text(context.l10n.createAccount)),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (regState.marketDataErrorKey != null) {
            return Scaffold(
              appBar: AppBar(title: Text(context.l10n.createAccount)),
              body: Center(
                child: TilawaButton(
                  text: context.l10n.retry,
                  onPressed: () =>
                      context.read<EmailRegistrationCubit>().initialize(),
                ),
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(context.l10n.createAccount),
              leading: regState.canGoBack
                  ? BackButton(
                      onPressed: regState.isSubmitting
                          ? null
                          : () =>
                                context.read<EmailRegistrationCubit>().goBack(),
                    )
                  : null,
            ),
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(tokens.spaceLarge),
                child: TilawaContentBounds(
                  kind: TilawaContentKind.form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      EmailRegistrationStepIndicator(
                        currentStep: regState.currentStepDisplayIndex,
                        totalSteps: regState.visibleStepCount,
                        stepLabel: context.l10n.registrationStepProgress(
                          regState.currentStepDisplayIndex,
                          regState.visibleStepCount,
                          registrationStepLabel(context, regState.currentStep),
                        ),
                      ),
                      SizedBox(height: tokens.spaceLarge),
                      Expanded(
                        child: SingleChildScrollView(
                          child: _RegistrationStepBody(
                            step: regState.currentStep,
                          ),
                        ),
                      ),
                      if (regState.status ==
                          EmailRegistrationStatus.profilePersistenceFailed)
                        Padding(
                          padding: EdgeInsets.only(bottom: tokens.spaceMedium),
                          child: Text(
                            context.l10n.registrationProfilePersistenceFailed,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      SizedBox(height: tokens.spaceMedium),
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
                      SizedBox(height: tokens.spaceMedium),
                      TextButton(
                        onPressed: () => context.push(
                          const EmailLoginRoute().location,
                        ),
                        child: Text(context.l10n.alreadyHaveAccount),
                      ),
                    ],
                  ),
                ),
              ),
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
      final RegisterWithEmailResult? result = await cubit
          .retryProfilePersistence();
      if (!context.mounted || result == null) {
        return;
      }
      if (result is RegisterWithEmailCompleted) {
        cubit.clearProfilePersistenceFailure();
        context.read<AuthBloc>().add(const AuthEvent.checkAuthStatus());
      }
      if (result is RegisterWithEmailProfilePersistenceFailed) {
        TilawaFeedback.showToast(
          context,
          message: context.l10n.registrationProfilePersistenceFailed,
          variant: TilawaFeedbackVariant.error,
        );
      }
      return;
    }

    if (regState.currentStep == EmailRegistrationStep.review) {
      if (!cubit.validateCurrentStep()) {
        return;
      }
      context.read<AuthBloc>().add(
        AuthEvent.registerWithEmail(draft: cubit.buildSubmissionDraft()),
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
      EmailRegistrationStep.quranLearning =>
        const EmailRegistrationLearningStep(),
      EmailRegistrationStep.guardian => const EmailRegistrationGuardianStep(),
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
        appBar: AppBar(title: Text(context.l10n.forgotPassword)),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(tokens.spaceLarge),
            child: TilawaContentBounds(
              kind: TilawaContentKind.form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    context.l10n.forgotPasswordDescription,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: tokens.spaceLarge),
                  BlocBuilder<EmailAuthFormCubit, EmailAuthFormState>(
                    builder: (BuildContext context, EmailAuthFormState state) {
                      return TilawaTextField(
                        label: context.l10n.emailAddress,
                        keyboardType: TextInputType.emailAddress,
                        enabled:
                            context.watch<ForgotPasswordCubit>().state
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
                  SizedBox(height: tokens.spaceLarge),
                  BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    final EmailAuthFormCubit formCubit = context.read<EmailAuthFormCubit>();
    if (!formCubit.validateEmailOnly()) {
      return;
    }
    context.read<ForgotPasswordCubit>().submit(
      email: formCubit.state.email.trim(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:tilawa/features/auth/domain/entities/email_registration_step.dart';
import 'package:tilawa/features/auth/domain/entities/register_with_email_result.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/auth/presentation/cubit/email_registration_cubit.dart';
import 'package:tilawa/features/auth/presentation/cubit/email_registration_state.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/auth_widget_test_harness.dart';
import '../bloc/auth_bloc_test.mocks.dart';

/// Footer-only harness mirroring register retry UI without review step deps.
class _RegisterRetryFooterHarness extends StatelessWidget {
  const _RegisterRetryFooterHarness();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;

    return BlocBuilder<EmailRegistrationCubit, EmailRegistrationState>(
      builder: (BuildContext context, EmailRegistrationState regState) {
        return Scaffold(
          body: TilawaBottomActionInset(
            top: tokens.spaceLarge,
            maxWidthKind: TilawaContentKind.form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: tokens.spaceSmall,
              children: <Widget>[
                if (regState.status ==
                    EmailRegistrationStatus.profilePersistenceFailed)
                  Text(
                    AppLocalizations.of(
                      context,
                    ).registrationProfilePersistenceFailed,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (BuildContext context, AuthState authState) {
                    final bool isLoading =
                        authState is AuthLoading || regState.isSubmitting;
                    final bool isRetry =
                        regState.status ==
                        EmailRegistrationStatus.profilePersistenceFailed;

                    return TilawaButton(
                      text: isRetry
                          ? AppLocalizations.of(
                              context,
                            ).registrationRetryProfileSave
                          : AppLocalizations.of(context).continueButton,
                      isLoading: isLoading,
                      isFullWidth: true,
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (isRetry) {
                                final EmailRegistrationCubit cubit = context
                                    .read<EmailRegistrationCubit>();
                                await cubit.retryProfilePersistence();
                                if (context.mounted &&
                                    cubit.state.status ==
                                        EmailRegistrationStatus.editing &&
                                    cubit.state.authenticatedUser == null) {
                                  context.read<AuthBloc>().add(
                                    const CheckAuthStatusEvent(),
                                  );
                                }
                              }
                            },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  provideAuthBlocDummies();

  late AuthWidgetTestHarness authHarness;
  late MockRegisterWithEmailUseCase mockRegisterWithEmail;
  late EmailRegistrationCubit registrationCubit;

  final UserEntity user = UserEntity(
    id: 'reg-user',
    email: 'new@example.com',
    displayName: 'New User',
    createdAt: DateTime.utc(2024),
  );

  setUp(() async {
    TilawaInteractionFeedback.enabled = false;
    authHarness = AuthWidgetTestHarness();
    mockRegisterWithEmail = authHarness.mockRegisterWithEmail;
    registrationCubit = EmailRegistrationCubit(mockRegisterWithEmail);
    registrationCubit.emit(
      EmailRegistrationState(
        currentStep: EmailRegistrationStep.review,
        status: EmailRegistrationStatus.profilePersistenceFailed,
        authenticatedUser: user,
        draft: registrationCubit.state.draft.copyWith(
          email: 'new@example.com',
          displayName: 'New User',
        ),
      ),
    );
  });

  tearDown(() async {
    await registrationCubit.close();
    authHarness.dispose();
  });

  group('profile persistence retry', () {
    blocTest<EmailRegistrationCubit, EmailRegistrationState>(
      'retry succeeds and clears failure state',
      build: () => EmailRegistrationCubit(mockRegisterWithEmail),
      seed: () => EmailRegistrationState(
        currentStep: EmailRegistrationStep.review,
        status: EmailRegistrationStatus.profilePersistenceFailed,
        authenticatedUser: user,
      ),
      setUp: () {
        when(
          mockRegisterWithEmail.retryProfilePersistence(
            user: anyNamed('user'),
            draft: anyNamed('draft'),
          ),
        ).thenAnswer(
          (_) async => RegisterWithEmailResult.completed(user: user),
        );
      },
      act: (EmailRegistrationCubit c) => c.retryProfilePersistence(),
      verify: (EmailRegistrationCubit c) {
        expect(c.state.status, EmailRegistrationStatus.editing);
        expect(c.state.authenticatedUser, isNull);
      },
    );

    blocTest<EmailRegistrationCubit, EmailRegistrationState>(
      'retry keeps failure state when persistence still fails',
      build: () => EmailRegistrationCubit(mockRegisterWithEmail),
      seed: () => EmailRegistrationState(
        currentStep: EmailRegistrationStep.review,
        status: EmailRegistrationStatus.profilePersistenceFailed,
        authenticatedUser: user,
      ),
      setUp: () {
        when(
          mockRegisterWithEmail.retryProfilePersistence(
            user: anyNamed('user'),
            draft: anyNamed('draft'),
          ),
        ).thenAnswer(
          (_) async => RegisterWithEmailResult.profilePersistenceFailed(
            user: user,
          ),
        );
      },
      act: (EmailRegistrationCubit c) => c.retryProfilePersistence(),
      verify: (EmailRegistrationCubit c) {
        expect(
          c.state.status,
          EmailRegistrationStatus.profilePersistenceFailed,
        );
        expect(c.state.authenticatedUser, user);
      },
    );

    testWidgets(
      'retry button dispatches retry and CheckAuthStatus on success',
      (
        WidgetTester tester,
      ) async {
        when(
          mockRegisterWithEmail.retryProfilePersistence(
            user: anyNamed('user'),
            draft: anyNamed('draft'),
          ),
        ).thenAnswer(
          (_) async => RegisterWithEmailResult.completed(user: user),
        );
        when(authHarness.mockGetCurrentUser()).thenReturn(user);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.getLightTheme(
              primaryColor: PrimaryColorPreset.defaultPreset.value,
            ),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            locale: const Locale('en'),
            builder: (context, child) => TilawaFeedbackHost(child: child!),
            home: MultiBlocProvider(
              providers: <BlocProvider<dynamic>>[
                BlocProvider<AuthBloc>.value(value: authHarness.authBloc),
                BlocProvider<EmailRegistrationCubit>.value(
                  value: registrationCubit,
                ),
              ],
              child: const _RegisterRetryFooterHarness(),
            ),
          ),
        );
        await tester.pump();

        expect(
          find.text(
            'Account created but saving your profile failed. Tap retry or '
            'complete your profile after sign-in.',
          ),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(TilawaButton, 'Retry saving profile'),
          findsOneWidget,
        );

        await tester.tap(
          find.widgetWithText(TilawaButton, 'Retry saving profile'),
        );
        await tester.pump();
        await tester.pump();

        verify(
          mockRegisterWithEmail.retryProfilePersistence(
            user: user,
            draft: anyNamed('draft'),
          ),
        ).called(1);

        await tester.runAsync(() async {
          await authHarness.authBloc.stream.firstWhere(
            (AuthState state) => state is AuthAuthenticated,
          );
        });
        await tester.pump();

        expect(authHarness.authBloc.state, isA<AuthAuthenticated>());
      },
    );
  });
}

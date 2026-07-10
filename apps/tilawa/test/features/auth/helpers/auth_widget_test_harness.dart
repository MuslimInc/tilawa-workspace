import 'package:dartz_plus/dartz_plus.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/auth/application/account_deletion_flow_tracker.dart';
import 'package:tilawa/features/auth/data/services/google_sign_in_session_tracker.dart';
import 'package:tilawa/features/auth/data/services/pending_session_revoke_store.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa_core/config/language_config.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../../support/map_backed_shared_preferences_async.dart';
import '../presentation/bloc/auth_bloc_test.mocks.dart';

/// Shared AuthBloc + mocks for auth widget/integration tests.
class AuthWidgetTestHarness {
  AuthWidgetTestHarness() {
    PendingSessionRevokeStore.setPrefsFactoryForTesting(
      () => MapBackedSharedPreferencesAsync().prefs,
    );
    signInSessionTracker = GoogleSignInSessionTracker();
    signInSessionTracker.markFinished();
    accountDeletionFlowTracker = AccountDeletionFlowTracker();

    mockSignInWithGoogle = MockSignInWithGoogleUseCase();
    mockSignInWithEmail = MockSignInWithEmailUseCase();
    mockRegisterWithEmail = MockRegisterWithEmailUseCase();
    mockSignOut = MockSignOut();
    mockDeleteAccount = MockDeleteAccount();
    mockGetCurrentUser = MockGetCurrentUserUseCase();
    mockSyncDeviceToken = MockSyncDeviceTokenUseCase();
    mockGetCurrentLanguage = MockGetCurrentLanguageUseCase();
    mockSyncUserLanguagePreference = MockSyncUserLanguagePreferenceUseCase();

    when(
      mockGetCurrentLanguage(),
    ).thenAnswer((_) async => Right(LanguageConfig.defaultLanguageCode));
    when(mockSyncUserLanguagePreference(any)).thenAnswer((_) async {});
    when(mockSyncDeviceToken(any)).thenAnswer(
      (_) async => const Right(null),
    );
    when(mockSyncDeviceToken.registerExplicitSignIn(any)).thenAnswer(
      (_) async => const Right(null),
    );
    when(mockGetCurrentUser()).thenReturn(null);

    authBloc = AuthBloc(
      mockSignInWithGoogle,
      mockSignInWithEmail,
      mockRegisterWithEmail,
      mockSignOut,
      mockDeleteAccount,
      mockGetCurrentUser,
      mockSyncDeviceToken,
      mockGetCurrentLanguage,
      mockSyncUserLanguagePreference,
      accountDeletionFlowTracker,
      signInSessionTracker,
    );
  }

  late AuthBloc authBloc;
  late MockSignInWithGoogleUseCase mockSignInWithGoogle;
  late MockSignInWithEmailUseCase mockSignInWithEmail;
  late MockRegisterWithEmailUseCase mockRegisterWithEmail;
  late MockSignOut mockSignOut;
  late MockDeleteAccount mockDeleteAccount;
  late MockGetCurrentUserUseCase mockGetCurrentUser;
  late MockSyncDeviceTokenUseCase mockSyncDeviceToken;
  late MockGetCurrentLanguageUseCase mockGetCurrentLanguage;
  late MockSyncUserLanguagePreferenceUseCase mockSyncUserLanguagePreference;
  late AccountDeletionFlowTracker accountDeletionFlowTracker;
  late GoogleSignInSessionTracker signInSessionTracker;

  static final UserEntity defaultUser = UserEntity(
    id: 'user-1',
    email: 'user@example.com',
    displayName: 'Signed In User',
    createdAt: DateTime.utc(2024),
  );

  void dispose() {
    PendingSessionRevokeStore.setPrefsFactoryForTesting(null);
    signInSessionTracker.markFinished();
    authBloc.close();
  }
}

void provideAuthBlocDummies() {
  provideDummy<Either<Failure, void>>(const Right(null));
  provideDummy<Either<Failure, String>>(
    Right(LanguageConfig.defaultLanguageCode),
  );
}

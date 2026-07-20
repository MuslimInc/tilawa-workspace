import 'dart:async';
import 'dart:developer' as developer;

import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../../localization/domain/usecases/get_current_language_use_case.dart';
import '../../application/account_deletion_flow_tracker.dart';
import '../../data/services/google_sign_in_session_tracker.dart';
import '../../data/services/pending_session_revoke_store.dart';
import '../../device_registry_feature_flags.dart';
import '../../domain/entities/auth_error_key.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/email_auth_failure_key.dart';
import '../../domain/entities/email_registration_draft.dart';
import '../../domain/entities/register_with_email_result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/await_auth_restoration_use_case.dart';
import '../../domain/usecases/delete_account.dart';
import '../../domain/usecases/get_persisted_authenticated_user_use_case.dart';
import '../../domain/usecases/get_current_user_use_case.dart';
import '../../domain/usecases/register_with_email_use_case.dart';
import '../../domain/usecases/sign_in_with_apple_use_case.dart';
import '../../domain/usecases/sign_in_with_email_use_case.dart';
import '../../domain/usecases/sign_in_with_google_use_case.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sync_device_token_use_case.dart';
import '../../domain/usecases/sync_user_language_preference_use_case.dart';

part 'auth_bloc.freezed.dart';
part 'auth_event.dart';
part 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(
    this._signInWithGoogle,
    this._signInWithApple,
    this._signInWithEmail,
    this._registerWithEmail,
    this._signOut,
    this._deleteAccount,
    this._getCurrentUser,
    this._syncDeviceToken,
    this._getCurrentLanguage,
    this._syncUserLanguagePreference,
    this._accountDeletionFlow,
    this._signInSessionTracker,
    this._awaitAuthRestoration,
    this._getPersistedAuthenticatedUser, {
    this._multiDeviceLoginEnabled = isMultiDeviceLoginEnabled,
  }) : super(const AuthState.initial()) {
    on<SignInWithGoogleEvent>(_onSignInWithGoogle);
    on<SignInWithAppleEvent>(_onSignInWithApple);
    on<SignInWithEmailEvent>(_onSignInWithEmail);
    on<RegisterWithEmailEvent>(_onRegisterWithEmail);
    on<SignOutEvent>(_onSignOut);
    on<DeleteAccountEvent>(_onDeleteAccount);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<SessionInvalidatedEvent>(_onSessionInvalidated);
    on<AbortInteractiveSignInEvent>(_onAbortInteractiveSignIn);
    on<AccountProfileUpdatedEvent>(_onAccountProfileUpdated);
  }

  int _interactiveSignInGeneration = 0;

  final SignInWithGoogleUseCase _signInWithGoogle;
  final SignInWithAppleUseCase _signInWithApple;
  final SignInWithEmailUseCase _signInWithEmail;
  final RegisterWithEmailUseCase _registerWithEmail;
  final SignOut _signOut;
  final DeleteAccount _deleteAccount;
  final GetCurrentUserUseCase _getCurrentUser;
  final SyncDeviceTokenUseCase _syncDeviceToken;
  final GetCurrentLanguageUseCase _getCurrentLanguage;
  final SyncUserLanguagePreferenceUseCase _syncUserLanguagePreference;
  final AccountDeletionFlowTracker _accountDeletionFlow;
  final GoogleSignInSessionTracker _signInSessionTracker;
  final AwaitAuthRestorationUseCase _awaitAuthRestoration;
  final GetPersistedAuthenticatedUserUseCase _getPersistedAuthenticatedUser;
  final MultiDeviceLoginEnabledPredicate _multiDeviceLoginEnabled;

  Future<void> _onSignInWithGoogle(
    SignInWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    final int generation = ++_interactiveSignInGeneration;
    final AuthState? authenticatedBeforeSignIn = switch (state) {
      AuthAuthenticated() => state,
      _ => null,
    };

    try {
      _signInSessionTracker.markStarted();
      await PendingSessionRevokeStore.clear();
      emit(const AuthState.loading());

      final AuthResult result = await _signInWithGoogle();

      if (generation != _interactiveSignInGeneration) {
        return;
      }

      switch (result) {
        case AuthSuccess(:final user):
          await _handleSignInSuccess(
            user: user,
            generation: generation,
            emit: emit,
          );
        case AuthFailure(
          :final message,
          :final code,
          :final details,
        ):
          final String detail = code == null
              ? 'Google sign-in failed: $message'
              : 'Google sign-in failed: $message (code: $code)';
          logger.w(
            detail,
            stackTrace: details == null ? null : StackTrace.fromString(details),
          );
          _signInSessionTracker.markFinished();
          emit(AuthState.error(message: message));
        case AuthCancelled():
          logger.d('[GoogleSignIn] cancelled by user');
          _signInSessionTracker.markFinished();
          if (authenticatedBeforeSignIn != null) {
            emit(authenticatedBeforeSignIn);
          } else {
            emit(const AuthState.unauthenticated());
          }
        case AuthResultNoGoogleAccounts():
          logger.d('[GoogleSignIn] no Google accounts on device');
          _signInSessionTracker.markFinished();
          emit(const AuthState.noGoogleAccounts());
      }
    } catch (error, stackTrace) {
      if (generation != _interactiveSignInGeneration) {
        return;
      }
      logger.e(
        'Google sign-in failed',
        error: error,
        stackTrace: stackTrace,
      );
      _signInSessionTracker.markFinished();
      emit(
        const AuthState.error(message: EmailAuthFailureKey.generic),
      );
    } finally {
      _signInSessionTracker.markFinished();
    }
  }

  Future<void> _onSignInWithApple(
    SignInWithAppleEvent event,
    Emitter<AuthState> emit,
  ) async {
    final int generation = ++_interactiveSignInGeneration;
    final AuthState? authenticatedBeforeSignIn = switch (state) {
      AuthAuthenticated() => state,
      _ => null,
    };

    try {
      _signInSessionTracker.markStarted();
      await PendingSessionRevokeStore.clear();
      emit(const AuthState.loading());

      final AuthResult result = await _signInWithApple();

      if (generation != _interactiveSignInGeneration) {
        return;
      }

      switch (result) {
        case AuthSuccess(:final user):
          await _handleSignInSuccess(
            user: user,
            generation: generation,
            emit: emit,
          );
        case AuthFailure(
          :final message,
          :final code,
          :final details,
        ):
          final String detail = code == null
              ? 'Apple sign-in failed: $message'
              : 'Apple sign-in failed: $message (code: $code)';
          logger.w(
            detail,
            stackTrace: details == null ? null : StackTrace.fromString(details),
          );
          _signInSessionTracker.markFinished();
          emit(AuthState.error(message: message));
        case AuthCancelled():
          logger.d('[AppleSignIn] cancelled by user');
          _signInSessionTracker.markFinished();
          if (authenticatedBeforeSignIn != null) {
            emit(authenticatedBeforeSignIn);
          } else {
            emit(const AuthState.unauthenticated());
          }
        case AuthResultNoGoogleAccounts():
          _signInSessionTracker.markFinished();
          emit(const AuthState.unauthenticated());
      }
    } catch (error, stackTrace) {
      if (generation != _interactiveSignInGeneration) {
        return;
      }
      logger.e(
        'Apple sign-in failed',
        error: error,
        stackTrace: stackTrace,
      );
      _signInSessionTracker.markFinished();
      emit(
        const AuthState.error(message: EmailAuthFailureKey.generic),
      );
    } finally {
      _signInSessionTracker.markFinished();
    }
  }

  Future<void> _onSignInWithEmail(
    SignInWithEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    final int generation = ++_interactiveSignInGeneration;
    try {
      _signInSessionTracker.markStarted();
      await PendingSessionRevokeStore.clear();
      emit(const AuthState.loading());

      final AuthResult result = await _signInWithEmail(
        email: event.email,
        password: event.password,
      );

      if (generation != _interactiveSignInGeneration) {
        return;
      }

      switch (result) {
        case AuthSuccess(:final user):
          await _handleSignInSuccess(
            user: user,
            generation: generation,
            emit: emit,
          );
        case AuthFailure(:final message, :final code, :final details):
          logger.w(
            code == null
                ? 'Email sign-in failed: $message'
                : 'Email sign-in failed: $message (code: $code)',
            stackTrace: details == null ? null : StackTrace.fromString(details),
          );
          _signInSessionTracker.markFinished();
          emit(AuthState.error(message: message));
        case AuthCancelled():
          _signInSessionTracker.markFinished();
          emit(const AuthState.unauthenticated());
        case AuthResultNoGoogleAccounts():
          _signInSessionTracker.markFinished();
          emit(const AuthState.unauthenticated());
      }
    } catch (error, stackTrace) {
      if (generation != _interactiveSignInGeneration) {
        return;
      }
      logger.e('Email sign-in failed', error: error, stackTrace: stackTrace);
      _signInSessionTracker.markFinished();
      emit(
        const AuthState.error(message: EmailAuthFailureKey.generic),
      );
    } finally {
      _signInSessionTracker.markFinished();
    }
  }

  Future<void> _onRegisterWithEmail(
    RegisterWithEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    final int generation = ++_interactiveSignInGeneration;
    try {
      _signInSessionTracker.markStarted();
      await PendingSessionRevokeStore.clear();
      emit(const AuthState.loading());

      final RegisterWithEmailResult result = await _registerWithEmail(
        draft: event.draft,
      );

      if (generation != _interactiveSignInGeneration) {
        return;
      }

      switch (result) {
        case RegisterWithEmailCompleted(:final user):
          await _handleSignInSuccess(
            user: user,
            generation: generation,
            emit: emit,
          );
        case RegisterWithEmailProfilePersistenceFailed(:final user):
          await _handleSignInSuccess(
            user: user,
            generation: generation,
            emit: emit,
          );
        case RegisterWithEmailAuthFailed(
          :final message,
          :final code,
          :final details,
        ):
          logger.w(
            code == null
                ? 'Email registration failed: $message'
                : 'Email registration failed: $message (code: $code)',
            stackTrace: details == null ? null : StackTrace.fromString(details),
          );
          _signInSessionTracker.markFinished();
          emit(AuthState.error(message: message));
      }
    } catch (error, stackTrace) {
      if (generation != _interactiveSignInGeneration) {
        return;
      }
      logger.e(
        'Email registration failed',
        error: error,
        stackTrace: stackTrace,
      );
      _signInSessionTracker.markFinished();
      emit(const AuthState.error(message: 'Authentication failed'));
    } finally {
      _signInSessionTracker.markFinished();
    }
  }

  Future<void> _handleSignInSuccess({
    required UserEntity user,
    required int generation,
    required Emitter<AuthState> emit,
  }) async {
    _accountDeletionFlow.clearLoginAutoSignInSuppression();
    if (generation != _interactiveSignInGeneration) {
      return;
    }

    unawaited(_syncLanguagePreferenceAfterAuth());
    emit(AuthState.authenticated(user: user));
    // Keep [GoogleSignInSessionTracker.inFlight] true until registration
    // finishes so resume/session checks do not treat the fresh login as stale.
    await _registerDeviceAfterSignIn(user.id, generation);
  }

  Future<void> _registerDeviceAfterSignIn(
    String userId,
    int generation,
  ) async {
    try {
      final Either<Failure, void> registration = await _syncDeviceToken
          .registerExplicitSignIn(userId);
      if (generation != _interactiveSignInGeneration) {
        return;
      }
      registration.fold(
        (Failure failure) {
          logger.w(
            'Background device registration after sign-in failed: '
            '${failure.message ?? failure.runtimeType}',
          );
        },
        (_) {},
      );
    } catch (error, stackTrace) {
      logger.e(
        'Background device registration after sign-in threw',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {
    logger.d(
      '[DebugNotificationAuthFlow] AUTH_SIGN_OUT_REQUESTED '
      'caller=AuthBloc._onSignOut reason=user-action',
    );
    _interactiveSignInGeneration++;
    try {
      final result = await _signOut();
      result.fold(
        (Failure failure) {
          emit(AuthState.error(message: _messageForFailure(failure)));
        },
        (_) {
          emit(const AuthState.unauthenticated());
        },
      );
    } catch (error, stackTrace) {
      logger.e('Sign out failed', error: error, stackTrace: stackTrace);
      emit(const AuthState.unauthenticated());
    }
  }

  UserEntity? _liveOrInMemoryUser() {
    final UserEntity? liveUser = _getCurrentUser();
    if (liveUser != null) {
      return liveUser;
    }
    return switch (state) {
      AuthAuthenticated(:final user) => user,
      _ => null,
    };
  }

  Future<void> _onDeleteAccount(
    DeleteAccountEvent event,
    Emitter<AuthState> emit,
  ) async {
    final UserEntity? userBeforeDelete = _liveOrInMemoryUser();
    logger.d(
      '[DeleteFirebaseUser] Bloc: delete requested '
      'signedIn=${userBeforeDelete != null}',
    );
    _interactiveSignInGeneration++;
    _accountDeletionFlow.markDeletionStarted();

    final result = await _deleteAccount(sessionUser: userBeforeDelete);

    await result.fold(
      (failure) async {
        logger.d(
          '[DeleteFirebaseUser] Bloc: failed with ${failure.runtimeType} '
          'message=${failure.message}',
        );
        if (failure is UserCancelledFailure) {
          _restoreSessionAfterFailedDeletion(
            emit: emit,
            userBeforeDelete: userBeforeDelete,
          );
          return;
        }

        final String message = failure.message ?? DeleteAccountErrorKey.failed;
        logger.w(
          'Delete account failed: $message',
          error: failure,
        );
        emit(AuthState.error(message: message));
        _restoreSessionAfterFailedDeletion(
          emit: emit,
          userBeforeDelete: userBeforeDelete,
        );
      },
      (_) async {
        _accountDeletionFlow.markDeletionSucceeded();
        logger.d('[DeleteFirebaseUser] Bloc: account deleted, signing out');
        emit(const AuthState.unauthenticated());
      },
    );
  }

  void _onAccountProfileUpdated(
    AccountProfileUpdatedEvent event,
    Emitter<AuthState> emit,
  ) {
    emit(AuthState.authenticated(user: event.user));
  }

  void _onAbortInteractiveSignIn(
    AbortInteractiveSignInEvent event,
    Emitter<AuthState> emit,
  ) {
    _interactiveSignInGeneration++;
    if (state is AuthLoading) {
      emit(const AuthState.unauthenticated());
    }
  }

  void _onSessionInvalidated(
    SessionInvalidatedEvent event,
    Emitter<AuthState> emit,
  ) {
    if (_multiDeviceLoginEnabled()) {
      return;
    }
    _interactiveSignInGeneration++;
    emit(const AuthState.unauthenticated());
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthLoading || _signInSessionTracker.inFlight) {
      return;
    }

    // Firebase Auth restores the persisted session asynchronously on cold
    // start; `currentUser` is transiently null until it finishes. Wait for
    // restoration (gated by a persisted hint) before reading it, so a startup
    // race is never mis-emitted as `unauthenticated`. Both steps are
    // best-effort: a storage or stream failure must never strand the bloc in
    // `initial` or fabricate a logout.
    UserEntity? hint;
    try {
      hint = await _getPersistedAuthenticatedUser();
    } catch (error, stackTrace) {
      logger.w(
        'Reading persisted auth hint failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
    try {
      await _awaitAuthRestoration(sessionUser: hint);
    } catch (error, stackTrace) {
      logger.w(
        'Awaiting auth restoration failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    final UserEntity? user = _liveOrInMemoryUser() ?? hint;
    if (user == null) {
      emit(const AuthState.unauthenticated());
      return;
    }

    // Local-first session: trust the restored session immediately so startup
    // never blocks on the network (a dead or captive connection can hang the
    // device-registration callable for minutes). Verification runs in the
    // background and demotes only on a definitive stale-device rejection.
    unawaited(_syncLanguagePreferenceAfterAuth());
    emit(AuthState.authenticated(user: user));
    unawaited(
      _verifyDeviceRegistrationInBackground(
        user.id,
        _interactiveSignInGeneration,
      ),
    );
  }

  Future<void> _verifyDeviceRegistrationInBackground(
    String userId,
    int generation,
  ) async {
    try {
      final Either<Failure, void> registration = await _syncDeviceToken(
        userId,
      );
      // The session changed while the sync was in flight (interactive
      // sign-in, sign-out, deletion): a late stale verdict belongs to the
      // old session and must not demote the new one.
      if (generation != _interactiveSignInGeneration) {
        return;
      }
      final bool staleDevice = registration.fold(
        _isStaleDeviceFailure,
        (_) => false,
      );
      if (staleDevice && !_multiDeviceLoginEnabled()) {
        await _signOut(skipServerTokenClear: true);
        if (!isClosed) {
          add(const SessionInvalidatedEvent());
        }
      }
    } catch (error, stackTrace) {
      logger.e(
        'Background device sync after auth restore threw',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  bool _isStaleDeviceFailure(Failure failure) {
    return failure.message == AuthErrorKey.staleDeviceRejected;
  }

  String _messageForFailure(Failure failure) {
    return failure.message ?? 'Authentication failed';
  }

  void _restoreSessionAfterFailedDeletion({
    required Emitter<AuthState> emit,
    required UserEntity? userBeforeDelete,
  }) {
    final UserEntity? currentUser =
        _getCurrentUser() ?? userBeforeDelete ?? _liveOrInMemoryUser();
    if (currentUser != null) {
      emit(AuthState.authenticated(user: currentUser));
    } else {
      emit(const AuthState.unauthenticated());
    }
    _accountDeletionFlow.markDeletionEndedWithoutSuccess();
  }

  Future<void> _syncLanguagePreferenceAfterAuth() async {
    final Either<Failure, String> result = await _getCurrentLanguage();
    await result.fold(
      (_) async {},
      (languageCode) async {
        try {
          await _syncUserLanguagePreference(languageCode);
        } catch (error, stackTrace) {
          developer.log(
            'Failed to sync language preference',
            name: 'AuthBloc',
            error: error,
            stackTrace: stackTrace,
          );
        }
      },
    );
  }
}

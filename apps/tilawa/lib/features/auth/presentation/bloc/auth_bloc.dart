import 'dart:async';
import 'dart:developer' as developer;

import 'package:dartz_plus/dartz_plus.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../application/account_deletion_flow_tracker.dart';
import '../../data/services/google_sign_in_session_tracker.dart';
import '../../data/services/pending_session_revoke_store.dart';
import '../../domain/entities/auth_error_key.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/delete_account.dart';
import '../../domain/usecases/get_current_user_use_case.dart';
import '../../domain/usecases/sign_in_with_google_use_case.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sync_device_token_use_case.dart';
import '../../domain/usecases/sync_user_language_preference_use_case.dart';
import '../../../localization/domain/usecases/get_current_language_use_case.dart';
import '../../debug/tilawa_gsignin_debug_log.dart';

part 'auth_bloc.freezed.dart';
part 'auth_event.dart';
part 'auth_state.dart';

@injectable
class AuthBloc extends HydratedBloc<AuthEvent, AuthState> {
  AuthBloc(
    this._signInWithGoogle,
    this._signOut,
    this._deleteAccount,
    this._getCurrentUser,
    this._syncDeviceToken,
    this._getCurrentLanguage,
    this._syncUserLanguagePreference,
    this._accountDeletionFlow,
    this._signInSessionTracker,
  ) : super(const AuthState.initial()) {
    on<SignInWithGoogleEvent>(_onSignInWithGoogle);
    on<SignOutEvent>(_onSignOut);
    on<DeleteAccountEvent>(_onDeleteAccount);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<AbortInteractiveSignInEvent>(_onAbortInteractiveSignIn);
  }

  int _interactiveSignInGeneration = 0;

  final SignInWithGoogleUseCase _signInWithGoogle;
  final SignOut _signOut;
  final DeleteAccount _deleteAccount;
  final GetCurrentUserUseCase _getCurrentUser;
  final SyncDeviceTokenUseCase _syncDeviceToken;
  final GetCurrentLanguageUseCase _getCurrentLanguage;
  final SyncUserLanguagePreferenceUseCase _syncUserLanguagePreference;
  final AccountDeletionFlowTracker _accountDeletionFlow;
  final GoogleSignInSessionTracker _signInSessionTracker;

  Future<void> _onSignInWithGoogle(
    SignInWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    final int generation = ++_interactiveSignInGeneration;

    try {
      _signInSessionTracker.markStarted();
      await PendingSessionRevokeStore.clear();
      emit(const AuthState.loading());

      final AuthResult result = await _signInWithGoogle();

      if (generation != _interactiveSignInGeneration) {
        // #region agent log
        tilawaGSignInDebug(
          'signIn result ignored (aborted)',
          hypothesisId: 'H3',
          data: <String, Object?>{'generation': generation},
        );
        // #endregion
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
          emit(AuthState.error(message: message));
        case AuthCancelled():
          logger.d('[GoogleSignIn] cancelled by user');
          emit(const AuthState.unauthenticated());
        case AuthResultNoGoogleAccounts():
          logger.d('[GoogleSignIn] no Google accounts on device');
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

    final Either<Failure, void> registration = await _syncDeviceToken
        .registerExplicitSignIn(user.id);
    if (generation != _interactiveSignInGeneration) {
      return;
    }

    final bool registered = registration.fold((_) => false, (_) => true);
    if (!registered) {
      await _signOut(skipServerTokenClear: true);
      if (generation != _interactiveSignInGeneration) {
        return;
      }
      emit(
        AuthState.error(
          message: registration.fold(
            (failure) =>
                failure.message ?? AuthErrorKey.deviceRegistrationFailed,
            (_) => 'Sign-in could not be completed.',
          ),
        ),
      );
      return;
    }

    unawaited(_syncLanguagePreferenceAfterAuth());
    emit(AuthState.authenticated(user: user));
  }

  Future<void> _onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {
    try {
      await _signOut();
      emit(const AuthState.unauthenticated());
    } catch (error, stackTrace) {
      logger.e('Sign out failed', error: error, stackTrace: stackTrace);
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onDeleteAccount(
    DeleteAccountEvent event,
    Emitter<AuthState> emit,
  ) async {
    final UserEntity? userBeforeDelete = _getCurrentUser();
    logger.d(
      '[DeleteFirebaseUser] Bloc: delete requested '
      'signedIn=${userBeforeDelete != null}',
    );
    _interactiveSignInGeneration++;
    _accountDeletionFlow.markDeletionStarted();
    emit(const AuthState.loading());

    final result = await _deleteAccount();

    await result.fold(
      (failure) async {
        _accountDeletionFlow.markDeletionEndedWithoutSuccess();
        logger.d(
          '[DeleteFirebaseUser] Bloc: failed with ${failure.runtimeType} '
          'message=${failure.message}',
        );
        if (failure is UserCancelledFailure) {
          if (userBeforeDelete != null) {
            emit(AuthState.authenticated(user: userBeforeDelete));
          } else {
            emit(const AuthState.unauthenticated());
          }
          return;
        }

        final String message = failure.message ?? 'Unable to delete account';
        logger.w(
          'Delete account failed: $message',
          error: failure,
        );
        emit(AuthState.error(message: message));

        final UserEntity? currentUser = _getCurrentUser();
        if (currentUser != null) {
          emit(AuthState.authenticated(user: currentUser));
        } else {
          emit(const AuthState.unauthenticated());
        }
      },
      (_) async {
        _accountDeletionFlow.markDeletionSucceeded();
        logger.d('[DeleteFirebaseUser] Bloc: account deleted, signing out');
        emit(const AuthState.unauthenticated());
      },
    );
  }

  void _onAbortInteractiveSignIn(
    AbortInteractiveSignInEvent event,
    Emitter<AuthState> emit,
  ) {
    _interactiveSignInGeneration++;
    if (state is AuthLoading) {
      // #region agent log
      tilawaGSignInDebug('abortInteractiveSignIn emitted', hypothesisId: 'H2');
      // #endregion
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthLoading || _signInSessionTracker.inFlight) {
      return;
    }

    final UserEntity? user = _getCurrentUser();
    if (user != null) {
      final Either<Failure, void> registration = await _syncDeviceToken(
        user.id,
      );
      final bool staleDevice = registration.fold(
        _isStaleDeviceFailure,
        (_) => false,
      );
      if (staleDevice) {
        await _signOut(skipServerTokenClear: true);
        emit(const AuthState.unauthenticated());
        return;
      }
      unawaited(_syncLanguagePreferenceAfterAuth());
      emit(AuthState.authenticated(user: user));
      return;
    }
    emit(const AuthState.unauthenticated());
  }

  bool _isStaleDeviceFailure(Failure failure) {
    return failure.message == AuthErrorKey.staleDeviceRejected;
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

  @override
  AuthState? fromJson(Map<String, dynamic> json) {
    try {
      final stateType = json['state'] as String?;
      if (stateType == 'authenticated' && json['user'] != null) {
        final userJson = json['user'] as Map<String, dynamic>;
        final user = UserEntity(
          id: userJson['id'] as String,
          email: userJson['email'] as String,
          displayName: userJson['displayName'] as String,
          photoUrl: userJson['photoUrl'] as String?,
          createdAt: DateTime.parse(userJson['createdAt'] as String),
        );
        return AuthState.authenticated(user: user);
      }
      return const AuthState.initial();
    } catch (e) {
      return const AuthState.initial();
    }
  }

  @override
  Map<String, dynamic>? toJson(AuthState state) {
    // Only persist if authenticated to maintain session
    if (state is AuthAuthenticated) {
      return {
        'state': 'authenticated',
        'user': {
          'id': state.user.id,
          'email': state.user.email,
          'displayName': state.user.displayName,
          'photoUrl': state.user.photoUrl,
          'createdAt': state.user.createdAt.toIso8601String(),
        },
      };
    }
    // Don't persist other states - will check auth status on startup
    return null;
  }
}

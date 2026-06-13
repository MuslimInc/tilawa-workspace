import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/delete_account.dart';
import '../../domain/usecases/get_current_user_use_case.dart';
import '../../domain/usecases/sign_in_with_google_use_case.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sync_device_token_use_case.dart';
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

  Future<void> _onSignInWithGoogle(
    SignInWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    final int generation = ++_interactiveSignInGeneration;
    emit(const AuthState.loading());

    try {
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

      result.when(
        success: (user) {
          unawaited(_syncDeviceToken(user.id).catchError((_) {}));
          emit(AuthState.authenticated(user: user));
        },
        failure: (message, code, details) {
          final String detail = code == null
              ? 'Google sign-in failed: $message'
              : 'Google sign-in failed: $message (code: $code)';
          // Provider details are a native stack trace; passing them as the
          // log stack trace gets them truncated and attached by Sentry.
          logger.w(
            detail,
            stackTrace: details == null ? null : StackTrace.fromString(details),
          );
          emit(AuthState.error(message: message));
        },
        cancelled: () {
          logger.d('[GoogleSignIn] cancelled by user');
          emit(const AuthState.unauthenticated());
        },
      );
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
    }
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
    emit(const AuthState.loading());

    final result = await _deleteAccount();

    await result.fold(
      (failure) async {
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
    final UserEntity? user = _getCurrentUser();
    if (user != null) {
      unawaited(_syncDeviceToken(user.id).catchError((_) {}));
      emit(AuthState.authenticated(user: user));
    } else {
      emit(const AuthState.unauthenticated());
    }
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

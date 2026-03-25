import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_current_user_use_case.dart';
import '../../domain/usecases/sign_in_with_google_use_case.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sync_device_token_use_case.dart';

part 'auth_bloc.freezed.dart';
part 'auth_event.dart';
part 'auth_state.dart';

@injectable
class AuthBloc extends HydratedBloc<AuthEvent, AuthState> {
  AuthBloc(
    this._signInWithGoogle,
    this._signOut,
    this._getCurrentUser,
    this._syncDeviceToken,
  ) : super(const AuthState.initial()) {
    on<SignInWithGoogleEvent>(_onSignInWithGoogle);
    on<SignOutEvent>(_onSignOut);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
  }
  final SignInWithGoogleUseCase _signInWithGoogle;
  final SignOut _signOut;
  final GetCurrentUserUseCase _getCurrentUser;
  final SyncDeviceTokenUseCase _syncDeviceToken;

  Future<void> _onSignInWithGoogle(
    SignInWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    final AuthResult result = await _signInWithGoogle();

    result.when(
      success: (user) {
        unawaited(_syncDeviceToken(user.id).catchError((_) {}));
        emit(AuthState.authenticated(user: user));
      },
      failure: (message, code) => emit(AuthState.error(message: message)),
      cancelled: () => emit(const AuthState.unauthenticated()),
    );
  }

  Future<void> _onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {
    await _signOut();
    emit(const AuthState.unauthenticated());
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

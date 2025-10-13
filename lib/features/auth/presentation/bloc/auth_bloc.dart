import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:muzakri/features/auth/domain/entities/auth_result.dart';
import 'package:muzakri/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:muzakri/features/auth/domain/usecases/sign_in_with_google_use_case.dart';
import 'package:muzakri/features/auth/domain/usecases/sign_out.dart';
import 'package:muzakri/features/auth/presentation/bloc/auth_event.dart';
import 'package:muzakri/features/auth/presentation/bloc/auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInWithGoogleUseCase _signInWithGoogle;
  final SignOut _signOut;
  final GetCurrentUserUseCase _getCurrentUser;

  AuthBloc(this._signInWithGoogle, this._signOut, this._getCurrentUser)
    : super(const AuthState.initial()) {
    on<SignInWithGoogleEvent>(_onSignInWithGoogle);
    on<SignOutEvent>(_onSignOut);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
  }

  Future<void> _onSignInWithGoogle(
    SignInWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    final result = await _signInWithGoogle();

    result.when(
      success: (user) => emit(AuthState.authenticated(user: user)),
      failure: (message, code) => emit(AuthState.error(message: message)),
      cancelled: () => emit(const AuthState.unauthenticated()),
    );
  }

  Future<void> _onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {
    await _signOut();
    emit(const AuthState.unauthenticated());
  }

  void _onCheckAuthStatus(CheckAuthStatusEvent event, Emitter<AuthState> emit) {
    final user = _getCurrentUser();
    if (user != null) {
      emit(AuthState.authenticated(user: user));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }
}

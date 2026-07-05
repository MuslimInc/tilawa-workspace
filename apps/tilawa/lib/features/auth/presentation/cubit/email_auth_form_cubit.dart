import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/policies/email_auth_form_policy.dart';

/// Form field validation state for email/password auth screens.
class EmailAuthFormState extends Equatable {
  const EmailAuthFormState({
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.emailErrorKey,
    this.passwordErrorKey,
    this.confirmPasswordErrorKey,
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
  });

  final String email;
  final String password;
  final String confirmPassword;
  final String? emailErrorKey;
  final String? passwordErrorKey;
  final String? confirmPasswordErrorKey;
  final bool obscurePassword;
  final bool obscureConfirmPassword;

  bool get isLoginValid =>
      emailErrorKey == null &&
      passwordErrorKey == null &&
      email.trim().isNotEmpty &&
      password.isNotEmpty;

  bool get isRegisterValid =>
      isLoginValid &&
      confirmPasswordErrorKey == null &&
      confirmPassword.isNotEmpty;

  EmailAuthFormState copyWith({
    String? email,
    String? password,
    String? confirmPassword,
    String? emailErrorKey,
    String? passwordErrorKey,
    String? confirmPasswordErrorKey,
    bool? obscurePassword,
    bool? obscureConfirmPassword,
    bool clearEmailError = false,
    bool clearPasswordError = false,
    bool clearConfirmPasswordError = false,
  }) {
    return EmailAuthFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      emailErrorKey: clearEmailError
          ? null
          : emailErrorKey ?? this.emailErrorKey,
      passwordErrorKey: clearPasswordError
          ? null
          : passwordErrorKey ?? this.passwordErrorKey,
      confirmPasswordErrorKey: clearConfirmPasswordError
          ? null
          : confirmPasswordErrorKey ?? this.confirmPasswordErrorKey,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirmPassword:
          obscureConfirmPassword ?? this.obscureConfirmPassword,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    email,
    password,
    confirmPassword,
    emailErrorKey,
    passwordErrorKey,
    confirmPasswordErrorKey,
    obscurePassword,
    obscureConfirmPassword,
  ];
}

@injectable
class EmailAuthFormCubit extends Cubit<EmailAuthFormState> {
  EmailAuthFormCubit() : super(const EmailAuthFormState());

  void emailChanged(String value) {
    emit(
      state.copyWith(
        email: value,
        clearEmailError: true,
      ),
    );
  }

  void passwordChanged(String value) {
    emit(
      state.copyWith(
        password: value,
        clearPasswordError: true,
        clearConfirmPasswordError: true,
      ),
    );
  }

  void confirmPasswordChanged(String value) {
    emit(
      state.copyWith(
        confirmPassword: value,
        clearConfirmPasswordError: true,
      ),
    );
  }

  void togglePasswordVisibility() {
    emit(state.copyWith(obscurePassword: !state.obscurePassword));
  }

  void toggleConfirmPasswordVisibility() {
    emit(
      state.copyWith(obscureConfirmPassword: !state.obscureConfirmPassword),
    );
  }

  /// Validates email and password; callers read [EmailAuthFormState.isLoginValid].
  void validateForLogin() {
    final String? emailError = EmailAuthFormPolicy.validateEmail(state.email);
    final String? passwordError = EmailAuthFormPolicy.validatePassword(
      state.password,
    );
    emit(
      state.copyWith(
        emailErrorKey: emailError,
        passwordErrorKey: passwordError,
        clearEmailError: emailError == null,
        clearPasswordError: passwordError == null,
      ),
    );
  }

  /// Validates all fields; callers read [EmailAuthFormState.isRegisterValid].
  void validateForRegister() {
    validateForLogin();
    final String? confirmError = EmailAuthFormPolicy.validateConfirmPassword(
      password: state.password,
      confirmPassword: state.confirmPassword,
    );
    emit(
      state.copyWith(
        confirmPasswordErrorKey: confirmError,
        clearConfirmPasswordError: confirmError == null,
      ),
    );
  }

  /// Validates email only; callers check [EmailAuthFormState.emailErrorKey].
  void validateEmailOnly() {
    final String? emailError = EmailAuthFormPolicy.validateEmail(state.email);
    emit(
      state.copyWith(
        emailErrorKey: emailError,
        clearEmailError: emailError == null,
      ),
    );
  }
}

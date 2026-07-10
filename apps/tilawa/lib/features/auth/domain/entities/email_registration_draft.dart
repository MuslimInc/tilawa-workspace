import 'package:equatable/equatable.dart';

/// In-memory registration payload collected before Firebase Auth user creation.
class EmailRegistrationDraft extends Equatable {
  const EmailRegistrationDraft({
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.displayName = '',
    this.preferredLanguageCode,
  });

  final String email;
  final String password;
  final String confirmPassword;
  final String displayName;
  final String? preferredLanguageCode;

  bool get hasAccountFields =>
      email.trim().isNotEmpty &&
      password.isNotEmpty &&
      confirmPassword.isNotEmpty;

  bool get hasBasicProfileFields =>
      displayName.trim().isNotEmpty && preferredLanguageCode != null;

  EmailRegistrationDraft copyWith({
    String? email,
    String? password,
    String? confirmPassword,
    String? displayName,
    String? preferredLanguageCode,
  }) {
    return EmailRegistrationDraft(
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      displayName: displayName ?? this.displayName,
      preferredLanguageCode:
          preferredLanguageCode ?? this.preferredLanguageCode,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    email,
    password,
    confirmPassword,
    displayName,
    preferredLanguageCode,
  ];
}

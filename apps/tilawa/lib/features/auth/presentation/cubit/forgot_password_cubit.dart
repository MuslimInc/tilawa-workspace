import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/entities/email_auth_failure_key.dart';
import '../../domain/usecases/send_password_reset_email_use_case.dart';

sealed class ForgotPasswordState extends Equatable {
  const ForgotPasswordState();

  @override
  List<Object?> get props => <Object?>[];
}

final class ForgotPasswordInitial extends ForgotPasswordState {
  const ForgotPasswordInitial();
}

final class ForgotPasswordSubmitting extends ForgotPasswordState {
  const ForgotPasswordSubmitting();
}

final class ForgotPasswordSuccess extends ForgotPasswordState {
  const ForgotPasswordSuccess();
}

final class ForgotPasswordFailure extends ForgotPasswordState {
  const ForgotPasswordFailure(this.messageKey);

  final String messageKey;

  @override
  List<Object?> get props => <Object?>[messageKey];
}

@injectable
class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit(this._sendPasswordResetEmail)
    : super(const ForgotPasswordInitial());

  final SendPasswordResetEmailUseCase _sendPasswordResetEmail;

  Future<void> submit({required String email}) async {
    emit(const ForgotPasswordSubmitting());
    final result = await _sendPasswordResetEmail(email: email);
    result.fold(
      (Failure failure) {
        emit(
          ForgotPasswordFailure(
            failure.message ?? EmailAuthFailureKey.generic,
          ),
        );
      },
      (_) => emit(const ForgotPasswordSuccess()),
    );
  }

  void reset() {
    emit(const ForgotPasswordInitial());
  }
}

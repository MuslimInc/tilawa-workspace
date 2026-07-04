import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tilawa/core/network/network_error_message.dart';

import '../../domain/entities/google_sign_in_failure_key.dart';

/// Maps Google sign-in provider failures to stable message keys for UI.
abstract final class GoogleSignInFailureMapper {
  static String messageKeyForException(GoogleSignInException exception) {
    final String? description = exception.description;
    if (description != null && isNetworkConnectivityErrorMessage(description)) {
      return GoogleSignInFailureKey.offline;
    }

    return switch (exception.code) {
      GoogleSignInExceptionCode.uiUnavailable =>
        GoogleSignInFailureKey.uiUnavailable,
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError =>
        GoogleSignInFailureKey.notConfigured,
      GoogleSignInExceptionCode.userMismatch =>
        GoogleSignInFailureKey.userMismatch,
      GoogleSignInExceptionCode.unknownError ||
      GoogleSignInExceptionCode.canceled ||
      GoogleSignInExceptionCode.interrupted => GoogleSignInFailureKey.generic,
    };
  }

  static String messageKeyForPlatformException(PlatformException exception) {
    final String message = exception.message ?? '';
    if (isNetworkConnectivityErrorMessage(message)) {
      return GoogleSignInFailureKey.offline;
    }
    return GoogleSignInFailureKey.generic;
  }

  static String messageKeyForTimeout({required bool uiHiddenProbeFailed}) {
    return uiHiddenProbeFailed
        ? GoogleSignInFailureKey.timeoutUiHidden
        : GoogleSignInFailureKey.timeout;
  }

  static String messageKeyForUnknownError() => GoogleSignInFailureKey.generic;
}

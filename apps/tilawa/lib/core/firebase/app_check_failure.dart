import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

/// Sentinel [Failure.message] / [AuthState.error] values for App Check UX.
abstract final class AppCheckFailureKey {
  static const String auth = 'authAppCheckFailed';
  static const String purchase = 'purchaseAppCheckFailed';
}

/// Detects Firebase callable failures caused by missing/invalid App Check.
bool isAppCheckCallableFailure({
  required String code,
  String? message,
}) {
  final String normalizedMessage = (message ?? '').toLowerCase();
  if (normalizedMessage.contains('app check')) {
    return true;
  }
  if (code == 'failed-precondition' &&
      (normalizedMessage.contains('invalid app check token') ||
          normalizedMessage.contains('app attestation'))) {
    return true;
  }
  return false;
}

bool isAppCheckCallableFailureFromException(FirebaseFunctionsException error) {
  return isAppCheckCallableFailure(
    code: error.code,
    message: error.message,
  );
}

bool isAppCheckAuthErrorMessage(String message) {
  return message == AppCheckFailureKey.auth ||
      isAppCheckCallableFailure(code: 'unknown', message: message);
}

bool isAppCheckPurchaseErrorMessage(String? message) {
  return message == AppCheckFailureKey.purchase ||
      isAppCheckCallableFailure(code: 'unknown', message: message);
}

/// User-facing App Check copy; debug/profile builds include setup hints.
abstract final class AppCheckUxMessages {
  static bool get showDebugSetupHint => kDebugMode || kProfileMode;

  static String authSignIn(AppLocalizations l10n) => showDebugSetupHint
      ? l10n.authAppCheckFailedDebug
      : l10n.authAppCheckFailedRelease;

  static String supportPurchase(AppLocalizations l10n) => showDebugSetupHint
      ? l10n.purchaseAppCheckFailedDebug
      : l10n.purchaseAppCheckFailedRelease;
}

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Coordinates account-deletion UX: suppress login auto sign-in (Credential
/// Manager) while deletion runs and after a successful delete.
@lazySingleton
class AccountDeletionFlowTracker extends ChangeNotifier {
  bool _deletionInProgress = false;
  bool _suppressLoginAutoSignIn = false;
  bool _pendingLoginNavigationAfterDeletion = false;

  /// Whether [DeleteAccount] is currently running.
  bool get deletionInProgress => _deletionInProgress;

  /// When true, [LoginScreen] must not launch automatic Google sign-in.
  bool get suppressLoginAutoSignIn => _suppressLoginAutoSignIn;

  /// Set after a successful delete; consumed by
  /// [AccountDeletionNavigationListener].
  bool get pendingLoginNavigationAfterDeletion =>
      _pendingLoginNavigationAfterDeletion;

  void markDeletionStarted() {
    _deletionInProgress = true;
    _suppressLoginAutoSignIn = true;
    _pendingLoginNavigationAfterDeletion = false;
    notifyListeners();
  }

  void markDeletionSucceeded() {
    _deletionInProgress = false;
    _pendingLoginNavigationAfterDeletion = true;
    notifyListeners();
  }

  void markDeletionEndedWithoutSuccess() {
    _deletionInProgress = false;
    _suppressLoginAutoSignIn = false;
    _pendingLoginNavigationAfterDeletion = false;
    notifyListeners();
  }

  void clearPendingLoginNavigation() {
    _pendingLoginNavigationAfterDeletion = false;
    notifyListeners();
  }

  void clearLoginAutoSignInSuppression() {
    _suppressLoginAutoSignIn = false;
    notifyListeners();
  }
}

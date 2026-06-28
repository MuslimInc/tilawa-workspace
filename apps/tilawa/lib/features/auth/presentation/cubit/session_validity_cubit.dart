import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/features/auth/data/services/pending_session_revoke_store.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';
import 'package:tilawa/features/auth/domain/services/session_revoked_notifier.dart';
import 'package:tilawa/features/auth/domain/usecases/check_session_validity_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/sign_out.dart';

class SessionValidityState extends Equatable {
  const SessionValidityState({
    this.isChecking = false,
    this.revoked = false,
  });

  final bool isChecking;
  final bool revoked;

  SessionValidityState copyWith({bool? isChecking, bool? revoked}) {
    return SessionValidityState(
      isChecking: isChecking ?? this.isChecking,
      revoked: revoked ?? this.revoked,
    );
  }

  @override
  List<Object?> get props => [isChecking, revoked];
}

/// Lightweight session epoch checks on resume and FCM `session_revoked`.
@injectable
class SessionValidityCubit extends Cubit<SessionValidityState> {
  SessionValidityCubit(
    this._authRepository,
    this._checkSessionValidity,
    this._signOut,
    this._sessionRevokedNotifier,
  ) : super(const SessionValidityState()) {
    _revokedSubscription = _sessionRevokedNotifier.onSessionRevoked.listen(
      (_) => _handleRevoked(trigger: 'fcm'),
    );
  }

  final AuthRepository _authRepository;
  final CheckSessionValidityUseCase _checkSessionValidity;
  final SignOut _signOut;
  final SessionRevokedNotifier _sessionRevokedNotifier;
  late final StreamSubscription<void> _revokedSubscription;
  bool _handlingRevocation = false;

  Future<void> checkOnResume() async {
    final user = _authRepository.currentUser;
    if (user == null || state.revoked || _handlingRevocation) {
      return;
    }

    if (await PendingSessionRevokeStore.consume()) {
      _sessionRevokedNotifier.notifySessionRevoked();
      return;
    }

    emit(state.copyWith(isChecking: true));
    final result = await _checkSessionValidity(user.id);
    final isValid = result.fold((_) => true, (valid) => valid);
    emit(state.copyWith(isChecking: false));

    if (!isValid) {
      await _handleRevoked(trigger: 'resume');
    }
  }

  Future<void> _handleRevoked({required String trigger}) async {
    if (_handlingRevocation || state.revoked) {
      return;
    }
    _handlingRevocation = true;
    emit(state.copyWith(revoked: true, isChecking: false));
    try {
      await _signOut(skipServerTokenClear: true);
    } finally {
      _handlingRevocation = false;
    }
  }

  /// Clears the revoked latch so a freshly re-authenticated user can access
  /// protected routes again. Called when [AuthBloc] transitions to
  /// [AuthAuthenticated] — safe to call when already cleared (no-op).
  void resetRevocation() {
    if (state.revoked || state.isChecking) {
      emit(const SessionValidityState());
    }
  }

  @override
  Future<void> close() {
    _revokedSubscription.cancel();
    return super.close();
  }
}

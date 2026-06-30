import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/features/auth/data/services/google_sign_in_session_tracker.dart';
import 'package:tilawa/features/auth/data/services/pending_session_revoke_store.dart';
import 'package:tilawa/features/auth/domain/entities/session_validity_result.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';
import 'package:tilawa/features/auth/domain/services/session_revoked_notifier.dart';
import 'package:tilawa/features/auth/domain/usecases/check_session_validity_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/sign_out.dart';

class SessionValidityState extends Equatable {
  const SessionValidityState({
    this.isChecking = false,
    this.revoked = false,
    this.verificationUnknown = false,
  });

  final bool isChecking;
  final bool revoked;
  final bool verificationUnknown;

  SessionValidityState copyWith({
    bool? isChecking,
    bool? revoked,
    bool? verificationUnknown,
  }) {
    return SessionValidityState(
      isChecking: isChecking ?? this.isChecking,
      revoked: revoked ?? this.revoked,
      verificationUnknown: verificationUnknown ?? this.verificationUnknown,
    );
  }

  @override
  List<Object?> get props => [isChecking, revoked, verificationUnknown];
}

/// Lightweight session epoch checks on resume and FCM `session_revoked`.
@injectable
class SessionValidityCubit extends Cubit<SessionValidityState> {
  SessionValidityCubit(
    this._authRepository,
    this._checkSessionValidity,
    this._signOut,
    this._sessionRevokedNotifier,
    this._signInSessionTracker,
  ) : super(const SessionValidityState()) {
    _revokedSubscription = _sessionRevokedNotifier.onSessionRevoked.listen(
      (_) => unawaited(_onSessionRevokedFromFcm()),
    );
  }

  static const int _maxUnknownRetries = 2;
  static const List<Duration> _unknownRetryDelays = <Duration>[
    Duration(seconds: 2),
    Duration(seconds: 5),
  ];

  final AuthRepository _authRepository;
  final CheckSessionValidityUseCase _checkSessionValidity;
  final SignOut _signOut;
  final SessionRevokedNotifier _sessionRevokedNotifier;
  final GoogleSignInSessionTracker _signInSessionTracker;
  late final StreamSubscription<void> _revokedSubscription;
  Timer? _unknownRetryTimer;
  int _unknownRetryCount = 0;
  bool _handlingRevocation = false;

  Future<void> checkOnResume() async {
    if (_signInSessionTracker.inFlight) {
      return;
    }

    final user = _authRepository.currentUser;
    if (user == null || state.revoked || _handlingRevocation) {
      return;
    }

    if (await PendingSessionRevokeStore.consume()) {
      await _handleRevoked(trigger: 'resume');
      return;
    }

    emit(
      state.copyWith(
        isChecking: true,
        verificationUnknown: false,
      ),
    );
    final result = await _checkSessionValidity(user.id);
    final validity = result.fold(
      (_) => SessionValidityResult.verificationUnknown,
      (value) => value,
    );

    switch (validity) {
      case SessionValidityResult.valid:
        _clearUnknownRetry();
        emit(
          state.copyWith(
            isChecking: false,
            verificationUnknown: false,
          ),
        );
      case SessionValidityResult.stale:
        _clearUnknownRetry();
        emit(state.copyWith(isChecking: false));
        await _handleRevoked(trigger: 'resume');
      case SessionValidityResult.verificationUnknown:
        emit(
          state.copyWith(
            isChecking: false,
            verificationUnknown: true,
          ),
        );
        _scheduleUnknownRetry();
    }
  }

  Future<void> _onSessionRevokedFromFcm() async {
    if (_signInSessionTracker.inFlight) {
      await PendingSessionRevokeStore.mark();
      return;
    }
    await _handleRevoked(trigger: 'fcm');
  }

  Future<void> _handleRevoked({required String trigger}) async {
    if (_handlingRevocation || state.revoked) {
      return;
    }
    _clearUnknownRetry();
    _handlingRevocation = true;
    emit(
      state.copyWith(
        revoked: true,
        isChecking: false,
        verificationUnknown: false,
      ),
    );
    try {
      await _signOut(skipServerTokenClear: true);
    } finally {
      _handlingRevocation = false;
    }
  }

  void _scheduleUnknownRetry() {
    if (_unknownRetryCount >= _maxUnknownRetries) {
      return;
    }
    final retryDelay = _unknownRetryDelays[_unknownRetryCount];
    _unknownRetryCount += 1;
    _unknownRetryTimer?.cancel();
    _unknownRetryTimer = Timer(retryDelay, () {
      unawaited(checkOnResume());
    });
  }

  void _clearUnknownRetry() {
    _unknownRetryTimer?.cancel();
    _unknownRetryTimer = null;
    _unknownRetryCount = 0;
  }

  /// Clears the revoked latch so a freshly re-authenticated user can access
  /// protected routes again. Called when [AuthBloc] transitions to
  /// [AuthAuthenticated] — safe to call when already cleared (no-op).
  void resetRevocation() {
    if (state.revoked || state.isChecking || state.verificationUnknown) {
      _clearUnknownRetry();
      emit(const SessionValidityState());
    }
  }

  @override
  Future<void> close() async {
    _clearUnknownRetry();
    await _revokedSubscription.cancel();
    return super.close();
  }
}

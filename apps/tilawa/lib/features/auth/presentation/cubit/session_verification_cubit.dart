import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/features/auth/device_registry_feature_flags.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';

/// Whether the app is confident the current session is live, or is temporarily
/// re-verifying it after a transient Firebase sign-out signal.
enum SessionVerificationStatus {
  /// Session confirmed / normal.
  verified,

  /// A transient verification hiccup (App Check attestation, token-refresh
  /// blip) briefly dropped the Firebase user. We keep the user in place and
  /// wait for it to recover — no logout, no redirect.
  verifying,
}

class SessionVerificationState extends Equatable {
  const SessionVerificationState({
    this.status = SessionVerificationStatus.verified,
    this.showBanner = false,
  });

  final SessionVerificationStatus status;

  /// True only once verifying has lasted past the "slow" threshold, so quick
  /// self-healing blips never flash a banner.
  final bool showBanner;

  bool get isVerifying => status == SessionVerificationStatus.verifying;

  SessionVerificationState copyWith({
    SessionVerificationStatus? status,
    bool? showBanner,
  }) {
    return SessionVerificationState(
      status: status ?? this.status,
      showBanner: showBanner ?? this.showBanner,
    );
  }

  @override
  List<Object?> get props => [status, showBanner];
}

/// Surfaces a **non-blocking** "verifying your session" state when Firebase
/// transiently drops the signed-in user (e.g. an App Check attestation or
/// token-refresh failure), instead of a destructive logout.
///
/// Additive and non-destructive by design: this cubit never signs the user out
/// and never redirects. It only reflects whether we are momentarily
/// re-verifying. Definitive invalidation (revoked/expired token, disabled or
/// deleted account) is still owned by the existing event-driven channels
/// (`SessionValidityCubit` / FCM / failed authenticated operations).
///
/// Gated behind [isAuthLifecycleHardeningEnabled]; inert when off.
@injectable
class SessionVerificationCubit extends Cubit<SessionVerificationState> {
  SessionVerificationCubit(
    this._authRepository, {
    AuthLifecycleHardeningEnabledPredicate hardeningEnabled =
        isAuthLifecycleHardeningEnabled,
    @ignoreParam Duration bannerThreshold = const Duration(seconds: 4),
    @ignoreParam Duration verifyingCap = const Duration(seconds: 45),
  }) : super(const SessionVerificationState()) {
    _hardeningEnabled = hardeningEnabled;
    _bannerThreshold = bannerThreshold;
    _verifyingCap = verifyingCap;
    _authSubscription = _authRepository.authStateChanges.listen(_onAuthUser);
  }

  final AuthRepository _authRepository;
  late final AuthLifecycleHardeningEnabledPredicate _hardeningEnabled;
  late final Duration _bannerThreshold;
  late final Duration _verifyingCap;

  late final StreamSubscription<UserEntity?> _authSubscription;
  Timer? _bannerTimer;
  Timer? _capTimer;
  bool _hadUser = false;

  void _onAuthUser(UserEntity? user) {
    if (user != null) {
      // Recovered (or first sign-in): confirm and clear any verifying state.
      _hadUser = true;
      _cancelTimers();
      if (state != const SessionVerificationState()) {
        emit(const SessionVerificationState());
      }
      return;
    }

    // Null user. Only a *previously* signed-in user under the hardening flag is
    // a candidate for transient verifying; a plain logged-out state is not.
    if (!_hadUser || !_hardeningEnabled()) {
      return;
    }
    if (state.isVerifying) {
      return;
    }

    emit(
      state.copyWith(
        status: SessionVerificationStatus.verifying,
      ),
    );
    _bannerTimer = Timer(_bannerThreshold, () {
      if (!isClosed && state.isVerifying) {
        emit(state.copyWith(showBanner: true));
      }
    });
    // Give up quietly after the cap: either it recovered (handled above) or a
    // definitive channel has taken over. Never force a logout here.
    _capTimer = Timer(_verifyingCap, () {
      if (!isClosed) {
        _hadUser = false;
        emit(const SessionVerificationState());
      }
    });
  }

  /// Called by intentional sign-out / confirmed-revocation paths so the null
  /// that follows is not mistaken for a transient blip (no verifying banner).
  void noteSessionEnded() {
    _hadUser = false;
    _cancelTimers();
    if (state != const SessionVerificationState()) {
      emit(const SessionVerificationState());
    }
  }

  void _cancelTimers() {
    _bannerTimer?.cancel();
    _bannerTimer = null;
    _capTimer?.cancel();
    _capTimer = null;
  }

  @override
  Future<void> close() {
    _cancelTimers();
    unawaited(_authSubscription.cancel());
    return super.close();
  }
}

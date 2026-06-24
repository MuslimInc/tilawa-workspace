import 'package:equatable/equatable.dart';

/// Decides whether a participant counts as *late*.
///
/// A participant is late when they first connect after
/// `scheduledStartAt + gracePeriod`. The grace period is configurable so it can
/// be tuned per market without touching the calculator or any UI/Firebase code.
class CallLatePolicy extends Equatable {
  const CallLatePolicy({this.gracePeriod = const Duration(minutes: 5)});

  /// Default tolerance before a join is considered late.
  static const Duration defaultGracePeriod = Duration(minutes: 5);

  final Duration gracePeriod;

  /// True when [joinedAt] is strictly after the grace window.
  bool isLate({
    required DateTime scheduledStartAt,
    required DateTime joinedAt,
  }) {
    final deadline = scheduledStartAt.add(gracePeriod);
    return joinedAt.isAfter(deadline);
  }

  @override
  List<Object?> get props => [gracePeriod];
}

/// Decides whether a participant counts as a *no-show*.
///
/// A participant is a no-show when they never connect within
/// `scheduledStartAt + noShowWindow` — evaluated against a reference time
/// (call end, or "now"). Before the window expires, absence is *pending*, not a
/// no-show.
class CallNoShowPolicy extends Equatable {
  const CallNoShowPolicy({this.noShowWindow = const Duration(minutes: 15)});

  /// Default window after which a never-joined participant is a no-show.
  static const Duration defaultNoShowWindow = Duration(minutes: 15);

  final Duration noShowWindow;

  /// Whether [evaluatedAt] is past the no-show deadline for the session.
  bool windowExpired({
    required DateTime scheduledStartAt,
    required DateTime evaluatedAt,
  }) {
    final deadline = scheduledStartAt.add(noShowWindow);
    return evaluatedAt.isAfter(deadline);
  }

  /// A participant is a no-show when they never joined AND the window expired.
  bool isNoShow({
    required DateTime scheduledStartAt,
    required DateTime evaluatedAt,
    required bool everJoined,
  }) {
    if (everJoined) {
      return false;
    }
    return windowExpired(
      scheduledStartAt: scheduledStartAt,
      evaluatedAt: evaluatedAt,
    );
  }

  @override
  List<Object?> get props => [noShowWindow];
}

/// Decides what counts as a *reconnect*.
///
/// The first time a participant connects is never a reconnect. A reconnect is
/// any subsequent connect that follows a drop/leave. A repeated `joined` event
/// while the participant is *still connected* is idempotent noise, never a
/// reconnect.
class CallReconnectPolicy extends Equatable {
  const CallReconnectPolicy();

  /// Given the participant's current state, whether a `joined` transition
  /// should be counted as a reconnect.
  bool isReconnect({
    required bool hasEverConnected,
    required bool isConnected,
  }) {
    if (isConnected) {
      return false; // duplicate join while connected — idempotent.
    }
    return hasEverConnected; // rejoin after a prior drop/leave.
  }

  @override
  List<Object?> get props => [];
}

/// Bundles the three policies the calculator consults. Inject a custom instance
/// to change grace/no-show behaviour for a market or an experiment.
class CallTrackingPolicy extends Equatable {
  const CallTrackingPolicy({
    this.late = const CallLatePolicy(),
    this.noShow = const CallNoShowPolicy(),
    this.reconnect = const CallReconnectPolicy(),
  });

  /// Production defaults: 5-minute grace, 15-minute no-show window.
  static const CallTrackingPolicy production = CallTrackingPolicy();

  final CallLatePolicy late;
  final CallNoShowPolicy noShow;
  final CallReconnectPolicy reconnect;

  CallTrackingPolicy copyWith({
    CallLatePolicy? late,
    CallNoShowPolicy? noShow,
    CallReconnectPolicy? reconnect,
  }) {
    return CallTrackingPolicy(
      late: late ?? this.late,
      noShow: noShow ?? this.noShow,
      reconnect: reconnect ?? this.reconnect,
    );
  }

  @override
  List<Object?> get props => [late, noShow, reconnect];
}

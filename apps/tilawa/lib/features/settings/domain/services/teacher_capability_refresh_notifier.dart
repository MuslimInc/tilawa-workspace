import 'dart:async';

import 'package:injectable/injectable.dart';

/// Broadcasts teacher-application moderation events from FCM (one shot per push).
///
/// [TeacherCapabilityCubit] subscribes while Settings is mounted so a single
/// Firestore read runs per admin action — no continuous snapshot listener.
@lazySingleton
class TeacherCapabilityRefreshNotifier {
  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  String? _lastNotifiedStatus;

  /// Emits [status] when admin reviews the application (approve/reject/etc.).
  Stream<String> get onApplicationReviewed => _controller.stream;

  /// Notifies listeners once per distinct [status] value (dedupes FCM retries).
  void notifyApplicationReviewed(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized.isEmpty || _lastNotifiedStatus == normalized) {
      return;
    }
    _lastNotifiedStatus = normalized;
    if (!_controller.isClosed) {
      _controller.add(normalized);
    }
  }

  void resetDedupeForTest() {
    _lastNotifiedStatus = null;
  }
}

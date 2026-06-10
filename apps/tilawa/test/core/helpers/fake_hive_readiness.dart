import 'dart:async';

import 'package:tilawa/core/services/hive_readiness.dart';

/// Test double that blocks [ensureReady] until [release] is called.
class FakeHiveReadiness implements HiveReadiness {
  int ensureReadyCallCount = 0;
  final Completer<void> _gate = Completer<void>();

  @override
  Future<void> ensureReady() async {
    ensureReadyCallCount++;
    await _gate.future;
  }

  void release() {
    if (!_gate.isCompleted) {
      _gate.complete();
    }
  }
}

/// Test double that completes immediately and tracks calls.
class ImmediateHiveReadiness implements HiveReadiness {
  int ensureReadyCallCount = 0;

  @override
  Future<void> ensureReady() async {
    ensureReadyCallCount++;
  }
}

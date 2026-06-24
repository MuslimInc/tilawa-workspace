import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/session_call_provider_event.dart';

/// Broadcast hub for provider-agnostic in-call events.
class SessionCallProviderEventHub {
  final _controller = StreamController<SessionCallProviderEvent>.broadcast(
    sync: true,
  );

  Stream<SessionCallProviderEvent> streamFor(String sessionId) {
    return _controller.stream.where((event) => event.sessionId == sessionId);
  }

  void emit(SessionCallProviderEvent event) {
    if (_controller.isClosed) {
      return;
    }
    _controller.add(event);
  }

  @visibleForTesting
  void dispose() {
    unawaited(_controller.close());
  }
}

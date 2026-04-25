import 'dart:async';

/// Coordinates the critical initialization lifecycle during bootstrap.
/// Holds the completer and callbacks needed to bridge widget-side and
/// bootstrap-side initialization triggers.
class CriticalInitCoordinator {
  const CriticalInitCoordinator({
    required this.kickOff,
    required this.initAction,
    required this.completer,
  });

  final void Function() kickOff;
  final Future<void> Function() initAction;
  final Completer<Future<void>> completer;
}

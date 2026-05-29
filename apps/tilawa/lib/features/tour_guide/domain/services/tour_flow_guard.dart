import 'package:injectable/injectable.dart';

/// Blocks product tours during worship-first or immersive flows.
///
/// Wrap sensitive routes with [TourSacredFlowScope] (presentation) which
/// calls [enter] / [exit] on this guard.
@lazySingleton
class TourFlowGuard {
  final Set<String> _activeFlows = <String>{};

  void enter(String flowId) => _activeFlows.add(flowId);

  void exit(String flowId) => _activeFlows.remove(flowId);

  bool get isBlocked => _activeFlows.isNotEmpty;
}

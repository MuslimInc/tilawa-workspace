import 'package:flutter/material.dart';
import 'package:tilawa/core/di/injection.dart';

import '../../domain/services/tour_flow_guard.dart';

/// Marks a subtree where product tours must not appear (e.g. Quran reader).
class TourSacredFlowScope extends StatefulWidget {
  const TourSacredFlowScope({
    super.key,
    required this.flowId,
    required this.child,
  });

  final String flowId;
  final Widget child;

  @override
  State<TourSacredFlowScope> createState() => _TourSacredFlowScopeState();
}

class _TourSacredFlowScopeState extends State<TourSacredFlowScope> {
  @override
  void initState() {
    super.initState();
    getIt<TourFlowGuard>().enter(widget.flowId);
  }

  @override
  void dispose() {
    getIt<TourFlowGuard>().exit(widget.flowId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

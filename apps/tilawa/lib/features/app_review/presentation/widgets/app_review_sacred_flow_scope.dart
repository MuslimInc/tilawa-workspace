import 'package:flutter/material.dart';
import 'package:tilawa/core/di/injection.dart';

import '../../domain/entities/app_review_blocked_flow.dart';
import '../../domain/services/app_review_flow_guard.dart';

/// Marks a subtree as a worship-first flow where review prompts are blocked.
class AppReviewSacredFlowScope extends StatefulWidget {
  const AppReviewSacredFlowScope({
    super.key,
    required this.flow,
    required this.child,
  });

  final AppReviewBlockedFlow flow;
  final Widget child;

  @override
  State<AppReviewSacredFlowScope> createState() =>
      _AppReviewSacredFlowScopeState();
}

class _AppReviewSacredFlowScopeState extends State<AppReviewSacredFlowScope> {
  @override
  void initState() {
    super.initState();
    getIt<AppReviewFlowGuard>().enter(widget.flow);
  }

  @override
  void dispose() {
    getIt<AppReviewFlowGuard>().exit(widget.flow);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

import 'package:injectable/injectable.dart';

import '../entities/app_review_blocked_flow.dart';

/// Tracks worship-focused surfaces where review prompts must never appear.
///
/// Uses a small stack so nested flows (e.g. Athkar tab + details) compose safely.
@lazySingleton
class AppReviewFlowGuard {
  final Set<AppReviewBlockedFlow> _activeFlows = <AppReviewBlockedFlow>{};

  bool get isSacredFlowActive => _activeFlows.isNotEmpty;

  Iterable<AppReviewBlockedFlow> get activeFlows =>
      List<AppReviewBlockedFlow>.unmodifiable(_activeFlows);

  void enter(AppReviewBlockedFlow flow) {
    _activeFlows.add(flow);
  }

  void exit(AppReviewBlockedFlow flow) {
    _activeFlows.remove(flow);
  }

  void clear() {
    _activeFlows.clear();
  }

  /// Keeps tab-owned sacred flows aligned with [MainScreen] index.
  void syncMainShellTab(int tabIndex) {
    exit(AppReviewBlockedFlow.prayer);
    exit(AppReviewBlockedFlow.athkar);
    return switch (tabIndex) {
      1 => enter(AppReviewBlockedFlow.prayer),
      2 => enter(AppReviewBlockedFlow.athkar),
      _ => null,
    };
  }
}

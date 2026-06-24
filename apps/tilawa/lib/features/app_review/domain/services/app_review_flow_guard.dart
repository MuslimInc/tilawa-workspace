import 'package:injectable/injectable.dart';

import '../entities/app_review_blocked_flow.dart';

/// Tracks worship-focused surfaces where review prompts must never appear.
///
/// Tab selection and nested scopes (e.g. Athkar tab + details) use separate
/// ref counts so one [exit] does not clear blocking while the user remains
/// in the same sacred flow.
@lazySingleton
class AppReviewFlowGuard {
  final Map<AppReviewBlockedFlow, int> _scopeRefCounts =
      <AppReviewBlockedFlow, int>{};
  final Set<AppReviewBlockedFlow> _tabFlows = <AppReviewBlockedFlow>{};

  bool get isSacredFlowActive =>
      _tabFlows.isNotEmpty || _scopeRefCounts.isNotEmpty;

  Iterable<AppReviewBlockedFlow> get activeFlows => <AppReviewBlockedFlow>{
    ..._tabFlows,
    ..._scopeRefCounts.keys,
  };

  void enter(AppReviewBlockedFlow flow) {
    _scopeRefCounts[flow] = (_scopeRefCounts[flow] ?? 0) + 1;
  }

  void exit(AppReviewBlockedFlow flow) {
    final int? count = _scopeRefCounts[flow];
    if (count == null) {
      return;
    }
    if (count <= 1) {
      _scopeRefCounts.remove(flow);
    } else {
      _scopeRefCounts[flow] = count - 1;
    }
  }

  void clear() {
    _scopeRefCounts.clear();
    _tabFlows.clear();
  }

  /// Keeps tab-owned sacred flows aligned with [MainScreen] viewport index.
  void syncMainShellTab(int tabIndex) {
    _tabFlows.remove(AppReviewBlockedFlow.athkar);
  }
}

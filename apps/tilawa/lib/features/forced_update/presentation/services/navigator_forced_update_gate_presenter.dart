import 'dart:async';

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/router/app_router.dart';

import '../widgets/forced_update_gate_page.dart';
import 'forced_update_gate_presenter.dart';

@LazySingleton(as: ForcedUpdateGatePresenter)
class NavigatorForcedUpdateGatePresenter implements ForcedUpdateGatePresenter {
  bool _isShowing = false;
  Future<void> Function()? _onUpdate;

  @override
  bool get isShowing => _isShowing;

  @override
  void showGate({required Future<void> Function() onUpdate}) {
    _onUpdate = onUpdate;
    if (_isShowing) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_presentGate());
    });
  }

  Future<void> _presentGate() async {
    if (_isShowing) {
      return;
    }

    final BuildContext? context = AppRouter.navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      logger.d('[ForcedUpdateGate] No navigator context — skip present.');
      return;
    }

    _isShowing = true;
    try {
      await showGeneralDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        barrierLabel: 'forced-update-gate',
        transitionDuration: Duration.zero,
        pageBuilder:
            (
              BuildContext dialogContext,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) {
              return ForcedUpdateGatePage(
                onUpdatePressed: () {
                  final Future<void> Function()? action = _onUpdate;
                  if (action != null) {
                    unawaited(action());
                  }
                },
              );
            },
      );
    } finally {
      _isShowing = false;
    }
  }

  @override
  void dismissGate() {
    if (!_isShowing) {
      return;
    }

    final NavigatorState? navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null || !navigator.canPop()) {
      return;
    }

    navigator.pop();
  }

  /// Test seam that presents against an explicit [context].
  @visibleForTesting
  Future<void> showGateForContext(
    BuildContext context, {
    required Future<void> Function() onUpdate,
  }) async {
    _onUpdate = onUpdate;
    if (_isShowing) {
      return;
    }
    _isShowing = true;
    try {
      await showGeneralDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        barrierLabel: 'forced-update-gate',
        transitionDuration: Duration.zero,
        pageBuilder:
            (
              BuildContext dialogContext,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) {
              return ForcedUpdateGatePage(
                onUpdatePressed: () {
                  final Future<void> Function()? action = _onUpdate;
                  if (action != null) {
                    unawaited(action());
                  }
                },
              );
            },
      );
    } finally {
      _isShowing = false;
    }
  }
}

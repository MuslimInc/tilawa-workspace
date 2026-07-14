import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/features/app_review/domain/usecases/open_app_store_listing_use_case.dart';

import '../../domain/entities/forced_update_decision.dart';
import '../../domain/usecases/evaluate_forced_update_use_case.dart';
import '../services/forced_update_gate_presenter.dart';

/// Orchestrates forced-update checks on startup / resume.
@singleton
class ForcedUpdateCoordinator {
  ForcedUpdateCoordinator(
    this._evaluateUpdate,
    this._openStoreListing,
    this._gatePresenter,
  );

  final EvaluateForcedUpdateUseCase _evaluateUpdate;
  final OpenAppStoreListingUseCase _openStoreListing;
  final ForcedUpdateGatePresenter _gatePresenter;

  Future<void>? _inFlightCheck;

  /// Evaluates remote min build vs install; shows or dismisses the gate.
  Future<void> checkForUpdate() async {
    if (_inFlightCheck != null) {
      await _inFlightCheck;
      return;
    }

    final Future<void> checkFuture = _checkForUpdateInternal();
    _inFlightCheck = checkFuture;
    try {
      await checkFuture;
    } finally {
      if (identical(_inFlightCheck, checkFuture)) {
        _inFlightCheck = null;
      }
    }
  }

  Future<void> _checkForUpdateInternal() async {
    try {
      final ForcedUpdateDecision decision = await _evaluateUpdate();
      if (decision == ForcedUpdateDecision.required) {
        _gatePresenter.showGate(onUpdate: _openStore);
        return;
      }

      _gatePresenter.dismissGate();
    } on Object catch (e) {
      logger.d('[ForcedUpdateCoordinator] Check failed (fail open): $e');
      _gatePresenter.dismissGate();
    }
  }

  /// Debug-only: shows the gate without evaluating remote policy.
  ///
  /// No-op in release / profile when [kDebugMode] is false.
  void debugPreviewGate() {
    if (!kDebugMode) {
      return;
    }
    _gatePresenter.showGate(onUpdate: _openStore);
  }

  Future<void> _openStore() async {
    final result = await _openStoreListing();
    result.fold(
      (failure) => logger.e(
        '[ForcedUpdateCoordinator] Open store failed: $failure',
      ),
      (_) {},
    );
  }
}

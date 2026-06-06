import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';

import '../../domain/entities/in_app_update_check_result.dart';
import '../../domain/entities/in_app_update_presentation_event.dart';
import '../../domain/usecases/check_for_in_app_update_use_case.dart';
import '../../domain/usecases/complete_flexible_in_app_update_use_case.dart';
import '../../domain/usecases/perform_immediate_in_app_update_use_case.dart';
import '../services/in_app_update_prompt_presenter.dart';

/// Orchestrates throttled update checks and routes UI prompts.
@singleton
class InAppUpdateCoordinator {
  InAppUpdateCoordinator(
    this._checkForUpdate,
    this._performImmediateUpdate,
    this._completeFlexibleUpdate,
    this._promptPresenter,
  );

  static const Duration minCheckInterval = Duration(hours: 6);

  final CheckForInAppUpdateUseCase _checkForUpdate;
  final PerformImmediateInAppUpdateUseCase _performImmediateUpdate;
  final CompleteFlexibleInAppUpdateUseCase _completeFlexibleUpdate;
  final InAppUpdatePromptPresenter _promptPresenter;

  DateTime? _lastCheckTime;
  Future<void>? _inFlightCheck;

  /// Checks for an update and performs it if available.
  ///
  /// Throttled to at most once per [minCheckInterval] to avoid repeatedly
  /// prompting the user on every resume.
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
    final DateTime now = DateTime.now();
    if (_lastCheckTime != null &&
        now.difference(_lastCheckTime!) < minCheckInterval) {
      return;
    }
    _lastCheckTime = now;

    try {
      final InAppUpdateCheckResult result = await _checkForUpdate();
      if (!result.hasPresentationEvent) {
        return;
      }

      _promptPresenter.showPrompt(
        result.presentationEvent,
        onConfirm: () => _handlePromptConfirmation(result.presentationEvent),
      );
    } catch (e) {
      logger.e('[InAppUpdateCoordinator] Failed to check for update: $e');
    }
  }

  Future<void> _handlePromptConfirmation(
    InAppUpdatePresentationEvent event,
  ) async {
    switch (event) {
      case InAppUpdatePresentationEvent.promptFlexibleRestart:
        await _completeFlexibleUpdate();
      case InAppUpdatePresentationEvent.promptOptionalImmediate:
        await _performImmediateUpdate();
      case InAppUpdatePresentationEvent.none:
        return;
    }
  }
}

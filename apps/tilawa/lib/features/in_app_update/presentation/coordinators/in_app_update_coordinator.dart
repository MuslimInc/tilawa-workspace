import 'dart:async';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/entities/in_app_update_action.dart';
import '../../domain/usecases/complete_flexible_in_app_update_use_case.dart';
import '../../domain/usecases/evaluate_in_app_update_use_case.dart';
import '../../domain/usecases/execute_in_app_update_action_use_case.dart';
import '../../domain/usecases/open_play_store_for_update_use_case.dart';
import '../../domain/repositories/in_app_update_repository.dart';
import '../services/in_app_update_prompt_presenter.dart';

/// Orchestrates throttled update checks and routes UI prompts.
@singleton
class InAppUpdateCoordinator {
  InAppUpdateCoordinator(
    this._evaluateUpdate,
    this._executeAction,
    this._openPlayStoreForUpdate,
    this._completeFlexibleUpdate,
    this._promptPresenter,
    InAppUpdateRepository repository,
  ) {
    repository.onFlexibleUpdateDownloaded.listen(
      (_) => unawaited(_showFlexibleRestartPrompt()),
    );
  }

  static const Duration minCheckInterval = Duration(hours: 6);

  final EvaluateInAppUpdateUseCase _evaluateUpdate;
  final ExecuteInAppUpdateActionUseCase _executeAction;
  final OpenPlayStoreForUpdateUseCase _openPlayStoreForUpdate;
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

    try {
      final evaluateResult = await _evaluateUpdate();
      await evaluateResult.fold(
        (failure) async {
          logger.e(
            '[InAppUpdateCoordinator] Failed to evaluate update: $failure',
          );
        },
        (action) async {
          if (action == InAppUpdateAction.none) {
            return;
          }

          final bool throttled =
              _lastCheckTime != null &&
              now.difference(_lastCheckTime!) < minCheckInterval;
          if (throttled && action.isOptionalUserPrompt) {
            return;
          }

          _lastCheckTime = now;

          final executeResult = await _executeAction(action);
          await executeResult.fold(
            (failure) async {
              logger.e(
                '[InAppUpdateCoordinator] Failed to execute update: $failure',
              );
            },
            (presentationAction) async {
              if (!presentationAction.requiresUserPrompt) {
                return;
              }

              _promptPresenter.showPrompt(
                presentationAction,
                onConfirm: () => _handlePromptConfirmation(presentationAction),
              );
            },
          );
        },
      );
    } catch (e) {
      logger.e('[InAppUpdateCoordinator] Failed to check for update: $e');
    }
  }

  Future<void> _handlePromptConfirmation(InAppUpdateAction action) async {
    final Either<Failure, void> result = switch (action) {
      InAppUpdateAction.promptFlexibleRestart =>
        await _completeFlexibleUpdate(),
      InAppUpdateAction.offerOptionalImmediate ||
      InAppUpdateAction.offerRequiredStoreUpdate =>
        await _openPlayStoreForUpdate(),
      _ => const Right(null),
    };

    result.fold(
      (failure) => logger.e(
        '[InAppUpdateCoordinator] Prompt action failed: $failure',
      ),
      (_) {},
    );
  }

  Future<void> _showFlexibleRestartPrompt() async {
    _promptPresenter.showPrompt(
      InAppUpdateAction.promptFlexibleRestart,
      onConfirm: () => _handlePromptConfirmation(
        InAppUpdateAction.promptFlexibleRestart,
      ),
    );
  }
}

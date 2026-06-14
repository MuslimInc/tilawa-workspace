import 'dart:async';

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/router/app_router.dart';

import '../../domain/entities/in_app_update_action.dart';
import 'in_app_update_prompt_presenter.dart';

@LazySingleton(as: InAppUpdatePromptPresenter)
class InAppUpdateSnackBarPresenter implements InAppUpdatePromptPresenter {
  @override
  void showPrompt(
    InAppUpdateAction action, {
    required Future<void> Function() onConfirm,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? context = AppRouter.navigatorKey.currentContext;
      if (context == null) {
        return;
      }

      showPromptForContext(context, action, onConfirm: onConfirm);
    });
  }

  /// Test seam for widget tests without relying on [AppRouter.navigatorKey].
  @visibleForTesting
  void showPromptForContext(
    BuildContext context,
    InAppUpdateAction action, {
    required Future<void> Function() onConfirm,
  }) {
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    final AppLocalizations l10n = context.l10n;
    final ({String message, String actionLabel}) copy = _promptCopyFor(
      action,
      l10n,
    );
    switch (action) {
      case InAppUpdateAction.offerRequiredStoreUpdate:
        messenger?.showMaterialBanner(
          MaterialBanner(
            content: Text(copy.message),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  messenger.hideCurrentMaterialBanner();
                  unawaited(onConfirm());
                },
                child: Text(copy.actionLabel),
              ),
            ],
          ),
        );
      case InAppUpdateAction.promptFlexibleRestart:
      case InAppUpdateAction.offerOptionalImmediate:
        messenger?.showSnackBar(
          SnackBar(
            content: Text(copy.message),
            action: SnackBarAction(
              label: copy.actionLabel,
              onPressed: () {
                unawaited(onConfirm());
              },
            ),
            duration: durationFor(action),
          ),
        );
      case InAppUpdateAction.performImmediate:
      case InAppUpdateAction.startFlexible:
      case InAppUpdateAction.none:
        break;
    }
  }

  static ({String message, String actionLabel}) _promptCopyFor(
    InAppUpdateAction action,
    AppLocalizations l10n,
  ) {
    return switch (action) {
      InAppUpdateAction.promptFlexibleRestart => (
        message: l10n.inAppUpdateFlexibleRestartMessage,
        actionLabel: l10n.inAppUpdateRestartAction,
      ),
      InAppUpdateAction.offerOptionalImmediate => (
        message: l10n.inAppUpdateOptionalMessage,
        actionLabel: l10n.inAppUpdateUpdateAction,
      ),
      InAppUpdateAction.offerRequiredStoreUpdate => (
        message: l10n.inAppUpdateRequiredMessage,
        actionLabel: l10n.inAppUpdateUpdateAction,
      ),
      _ => (message: '', actionLabel: ''),
    };
  }

  @visibleForTesting
  static const Duration snackBarPromptDuration = Duration(minutes: 5);

  @visibleForTesting
  static Duration durationFor(InAppUpdateAction action) {
    return switch (action) {
      InAppUpdateAction.promptFlexibleRestart ||
      InAppUpdateAction.offerOptionalImmediate => snackBarPromptDuration,
      _ => snackBarPromptDuration,
    };
  }

  @visibleForTesting
  static String messageFor(InAppUpdateAction action, AppLocalizations l10n) =>
      _promptCopyFor(action, l10n).message;

  @visibleForTesting
  static String actionLabelFor(
    InAppUpdateAction action,
    AppLocalizations l10n,
  ) => _promptCopyFor(action, l10n).actionLabel;
}

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

      final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
        context,
      );
      final l10n = context.l10n;
      messenger?.showSnackBar(
        SnackBar(
          content: Text(_messageFor(action, l10n)),
          action: SnackBarAction(
            label: _actionLabelFor(action, l10n),
            onPressed: () {
              unawaited(onConfirm());
            },
          ),
          duration: const Duration(minutes: 5),
        ),
      );
    });
  }

  String _messageFor(InAppUpdateAction action, AppLocalizations l10n) {
    return switch (action) {
      InAppUpdateAction.promptFlexibleRestart =>
        l10n.inAppUpdateFlexibleRestartMessage,
      InAppUpdateAction.offerOptionalImmediate =>
        l10n.inAppUpdateOptionalMessage,
      _ => '',
    };
  }

  String _actionLabelFor(InAppUpdateAction action, AppLocalizations l10n) {
    return switch (action) {
      InAppUpdateAction.promptFlexibleRestart => l10n.inAppUpdateRestartAction,
      InAppUpdateAction.offerOptionalImmediate => l10n.inAppUpdateUpdateAction,
      _ => '',
    };
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/router/app_router.dart';

import '../../domain/entities/in_app_update_presentation_event.dart';
import 'in_app_update_prompt_presenter.dart';

@LazySingleton(as: InAppUpdatePromptPresenter)
class InAppUpdateSnackBarPresenter implements InAppUpdatePromptPresenter {
  @override
  void showPrompt(
    InAppUpdatePresentationEvent event, {
    required Future<void> Function() onConfirm,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? context = AppRouter.navigatorKey.currentContext;
      if (context == null) {
        return;
      }

      final ScaffoldMessengerState? messenger =
          ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(_messageFor(event)),
          action: SnackBarAction(
            label: _actionLabelFor(event),
            onPressed: () {
              unawaited(onConfirm());
            },
          ),
          duration: const Duration(minutes: 5),
        ),
      );
    });
  }

  String _messageFor(InAppUpdatePresentationEvent event) {
    return switch (event) {
      InAppUpdatePresentationEvent.promptFlexibleRestart =>
        'Update downloaded. Restart when you are ready to install it.',
      InAppUpdatePresentationEvent.promptOptionalImmediate =>
        'A new version of Tilawa is available.',
      InAppUpdatePresentationEvent.none => '',
    };
  }

  String _actionLabelFor(InAppUpdatePresentationEvent event) {
    return switch (event) {
      InAppUpdatePresentationEvent.promptFlexibleRestart => 'Restart',
      InAppUpdatePresentationEvent.promptOptionalImmediate => 'Update',
      InAppUpdatePresentationEvent.none => '',
    };
  }
}

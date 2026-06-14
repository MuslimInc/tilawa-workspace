import '../../domain/entities/in_app_update_action.dart';

/// Shows in-app update prompts to the user.
abstract class InAppUpdatePromptPresenter {
  void showPrompt(
    InAppUpdateAction action, {
    required Future<void> Function() onConfirm,
  });
}

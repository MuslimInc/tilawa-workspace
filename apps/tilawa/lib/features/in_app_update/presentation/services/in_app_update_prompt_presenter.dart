import '../../domain/entities/in_app_update_presentation_event.dart';

/// Presentation port for non-blocking in-app update prompts.
abstract class InAppUpdatePromptPresenter {
  void showPrompt(
    InAppUpdatePresentationEvent event, {
    required Future<void> Function() onConfirm,
  });
}

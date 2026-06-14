import 'package:tilawa/features/in_app_update/domain/entities/in_app_update_action.dart';
import 'package:tilawa/features/in_app_update/presentation/services/in_app_update_prompt_presenter.dart';

class FakeInAppUpdatePromptPresenter implements InAppUpdatePromptPresenter {
  InAppUpdateAction? lastAction;
  Future<void> Function()? lastOnConfirm;
  int promptCount = 0;

  @override
  void showPrompt(
    InAppUpdateAction action, {
    required Future<void> Function() onConfirm,
  }) {
    lastAction = action;
    lastOnConfirm = onConfirm;
    promptCount++;
  }
}

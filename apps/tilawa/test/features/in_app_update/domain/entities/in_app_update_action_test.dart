import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/in_app_update/domain/entities/in_app_update_action.dart';

void main() {
  group('InAppUpdateActionPresentation', () {
    test('requiresUserPrompt only for snackbar actions', () {
      expect(
        InAppUpdateAction.promptFlexibleRestart.requiresUserPrompt,
        isTrue,
      );
      expect(
        InAppUpdateAction.offerOptionalImmediate.requiresUserPrompt,
        isTrue,
      );
      expect(InAppUpdateAction.performImmediate.requiresUserPrompt, isFalse);
      expect(InAppUpdateAction.startFlexible.requiresUserPrompt, isFalse);
      expect(InAppUpdateAction.none.requiresUserPrompt, isFalse);
    });
  });
}

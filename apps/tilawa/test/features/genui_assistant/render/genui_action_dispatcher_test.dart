import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/genui_assistant/genui_assistant.dart';

/// Records every intent it is asked to execute, so tests can assert that an
/// unknown action never reaches execution.
class _RecordingExecutor implements GenUiIntentExecutor {
  final List<GenUiIntent> executed = <GenUiIntent>[];

  @override
  void execute(GenUiIntent intent) => executed.add(intent);
}

void main() {
  group('GenUiActionDispatcher', () {
    test('an allowlisted action executes its typed intent', () {
      final executor = _RecordingExecutor();
      final dispatcher = GenUiActionDispatcher(executor: executor);

      final resolution = dispatcher.dispatch(
        const GenUiNode(
          type: 'ActionButton',
          actionId: 'startTodayWird',
          properties: {'planId': 'today'},
        ),
      );

      check(resolution).isA<GenUiActionAccepted>();
      check(executor.executed).length.equals(1);
      check(executor.executed.single).isA<StartTodayWirdIntent>();
    });

    test('an unknown action is rejected and never executed', () {
      final executor = _RecordingExecutor();
      final rejections = <GenUiActionRejected>[];
      final dispatcher = GenUiActionDispatcher(
        executor: executor,
        onRejected: rejections.add,
      );

      final resolution = dispatcher.dispatch(
        const GenUiNode(type: 'ActionButton', actionId: 'wipeDevice'),
      );

      check(resolution).isA<GenUiActionRejected>();
      check(executor.executed).isEmpty();
      check(rejections).length.equals(1);
      check(rejections.single.actionId).equals('wipeDevice');
    });

    test(
      'an allowlisted action with invalid args is rejected, not executed',
      () {
        final executor = _RecordingExecutor();
        final dispatcher = GenUiActionDispatcher(executor: executor);

        final resolution = dispatcher.dispatch(
          const GenUiNode(
            type: 'ActionButton',
            actionId: 'openQuranReader',
            properties: {'surah': 999},
          ),
        );

        check(resolution).isA<GenUiActionRejected>();
        check(executor.executed).isEmpty();
      },
    );
  });
}

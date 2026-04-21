import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/src/services/idle_scheduler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    IdleScheduler.instance.cancelAll();
  });

  group('IdleScheduler', () {
    testWidgets('runWhenIdle executes a single task', (
      WidgetTester tester,
    ) async {
      var executed = false;

      IdleScheduler.instance.runWhenIdle(() async {
        executed = true;
      });

      // Pump to trigger the post-frame callback.
      await tester.pump();
      await tester.pump();

      expect(executed, isTrue);
    });

    testWidgets('tasks execute in FIFO order', (WidgetTester tester) async {
      final order = <int>[];

      IdleScheduler.instance.runWhenIdle(() async {
        order.add(1);
      });
      IdleScheduler.instance.runWhenIdle(() async {
        order.add(2);
      });
      IdleScheduler.instance.runWhenIdle(() async {
        order.add(3);
      });

      // Pump enough frames for all tasks to execute serially.
      for (var i = 0; i < 6; i++) {
        await tester.pump();
      }

      expect(order, [1, 2, 3]);
    });

    testWidgets('cancel() prevents task execution', (
      WidgetTester tester,
    ) async {
      var executed = false;

      final IdleTask task = IdleScheduler.instance.runWhenIdle(() async {
        executed = true;
      });

      task.cancel();

      await tester.pump();
      await tester.pump();

      expect(executed, isFalse);
      expect(task.isCancelled, isTrue);
      expect(task.isCompleted, isTrue);
    });

    testWidgets('cancel() on already-completed task is a no-op', (
      WidgetTester tester,
    ) async {
      var execCount = 0;

      final IdleTask task = IdleScheduler.instance.runWhenIdle(() async {
        execCount++;
      });

      await tester.pump();
      await tester.pump();

      expect(execCount, 1);
      expect(task.isCompleted, isTrue);

      // Should not throw or change state.
      task.cancel();
      expect(task.isCancelled, isFalse);
    });

    testWidgets('cancelAll() clears all pending tasks', (
      WidgetTester tester,
    ) async {
      final executed = <int>[];

      IdleScheduler.instance.runWhenIdle(() async {
        executed.add(1);
      });
      IdleScheduler.instance.runWhenIdle(() async {
        executed.add(2);
      });
      IdleScheduler.instance.runWhenIdle(() async {
        executed.add(3);
      });

      IdleScheduler.instance.cancelAll();

      await tester.pump();
      await tester.pump();

      // Only task 1 may have already started processing before cancelAll.
      // But task 2 and 3 should definitely not execute.
      expect(executed.length, lessThanOrEqualTo(1));
    });

    testWidgets('task errors are swallowed and queue continues', (
      WidgetTester tester,
    ) async {
      var secondRan = false;

      IdleScheduler.instance.runWhenIdle(() async {
        throw Exception('Boom!');
      });
      IdleScheduler.instance.runWhenIdle(() async {
        secondRan = true;
      });

      for (var i = 0; i < 6; i++) {
        await tester.pump();
      }

      expect(secondRan, isTrue);
    });

    testWidgets('IdleTask.future completes after execution', (
      WidgetTester tester,
    ) async {
      final IdleTask task = IdleScheduler.instance.runWhenIdle(() async {
        // Simulate some work.
      });

      expect(task.isCompleted, isFalse);

      await tester.pump();
      await tester.pump();
      await task.future;

      expect(task.isCompleted, isTrue);
    });

    testWidgets('IdleTask.future completes after cancel', (
      WidgetTester tester,
    ) async {
      final IdleTask task = IdleScheduler.instance.runWhenIdle(() async {});

      task.cancel();

      // Should complete immediately since it was cancelled.
      await task.future;
      expect(task.isCompleted, isTrue);
      expect(task.isCancelled, isTrue);
    });

    testWidgets('tasks do NOT execute synchronously on schedule', (
      WidgetTester tester,
    ) async {
      var executed = false;

      IdleScheduler.instance.runWhenIdle(() async {
        executed = true;
      });

      // Immediately after scheduling — before any pump — should NOT
      // have executed. This proves the deferred idle-frame behavior.
      expect(executed, isFalse);

      await tester.pump();
      await tester.pump();

      expect(executed, isTrue);
    });

    testWidgets('serial execution — second task waits for first to finish', (
      WidgetTester tester,
    ) async {
      final blocker = Completer<void>();
      var firstDone = false;
      var secondStarted = false;

      IdleScheduler.instance.runWhenIdle(() async {
        await blocker.future;
        firstDone = true;
      });

      IdleScheduler.instance.runWhenIdle(() async {
        // If serial, firstDone must be true by the time this runs.
        secondStarted = true;
        expect(firstDone, isTrue);
      });

      // Pump to start first task.
      await tester.pump();
      await tester.pump();

      // First task is blocked — second should not have started.
      expect(secondStarted, isFalse);

      // Unblock first task.
      blocker.complete();
      // Pump to let the first finish and second get scheduled.
      for (var i = 0; i < 4; i++) {
        await tester.pump();
      }

      expect(firstDone, isTrue);
      expect(secondStarted, isTrue);
    });
  });
}

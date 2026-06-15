import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/presentation/services/login_auto_sign_in_scheduler.dart';

void main() {
  final TestWidgetsFlutterBinding binding =
      TestWidgetsFlutterBinding.ensureInitialized();

  late LoginAutoSignInScheduler scheduler;
  final List<String> logs = <String>[];
  int autoSignInCount = 0;

  void log(String message) => logs.add(message);

  void onAutoSignIn() => autoSignInCount++;

  Future<void> warmUpPolicy() async {}

  setUp(() {
    scheduler = LoginAutoSignInScheduler();
    logs.clear();
    autoSignInCount = 0;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  Future<void> pumpSchedulerFrames(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump();
  }

  void schedule({
    bool skipAutoSignIn = false,
    bool mounted = true,
    bool routeCurrent = true,
    AppLifecycleState? lifecycle = AppLifecycleState.resumed,
  }) {
    scheduler.scheduleWhenReady(
      warmUpPolicy: warmUpPolicy,
      shouldSkipAutoSignIn: () => skipAutoSignIn,
      isMounted: () => mounted,
      isRouteCurrent: () => routeCurrent,
      lifecycleState: () => lifecycle,
      onAutoSignIn: onAutoSignIn,
      log: log,
    );
  }

  testWidgets('fires auto sign-in once after warm-up and post-frame', (
    WidgetTester tester,
  ) async {
    schedule();
    await pumpSchedulerFrames(tester);

    expect(autoSignInCount, 1);
    expect(scheduler.isScheduled, isTrue);
    expect(
      logs.any((String line) => line.contains('firing auto sign-in')),
      isTrue,
    );
  });

  testWidgets('does not schedule twice for the same screen instance', (
    WidgetTester tester,
  ) async {
    schedule();
    await pumpSchedulerFrames(tester);
    schedule();
    await tester.pump();

    expect(autoSignInCount, 1);
    expect(
      logs.any((String line) => line.contains('already scheduled')),
      isTrue,
    );
  });

  testWidgets('skips auto sign-in when OEM policy disables it', (
    WidgetTester tester,
  ) async {
    schedule(skipAutoSignIn: true);
    await pumpSchedulerFrames(tester);

    expect(autoSignInCount, 0);
    expect(
      logs.any((String line) => line.contains('Transsion OEM')),
      isTrue,
    );
  });

  testWidgets('skips auto sign-in when the widget is unmounted after warm-up', (
    WidgetTester tester,
  ) async {
    schedule(mounted: false);
    await pumpSchedulerFrames(tester);

    expect(autoSignInCount, 0);
    expect(scheduler.isScheduled, isFalse);
  });

  testWidgets('skips auto sign-in when unmounted at post-frame', (
    WidgetTester tester,
  ) async {
    var mounted = true;

    await tester.pumpWidget(const SizedBox.shrink());
    scheduler.scheduleWhenReady(
      warmUpPolicy: () => Future<void>.value(),
      shouldSkipAutoSignIn: () => false,
      isMounted: () => mounted,
      isRouteCurrent: () => true,
      lifecycleState: () => AppLifecycleState.resumed,
      onAutoSignIn: onAutoSignIn,
      log: log,
    );

    await tester.pump();
    await tester.pump();
    mounted = false;
    await tester.pump();

    expect(autoSignInCount, 0);
  });

  testWidgets('skips auto sign-in when the route is not current', (
    WidgetTester tester,
  ) async {
    schedule(routeCurrent: false);
    await pumpSchedulerFrames(tester);

    expect(autoSignInCount, 0);
    expect(
      logs.any((String line) => line.contains('route not current')),
      isTrue,
    );
  });

  testWidgets('skips auto sign-in when lifecycle is not resumed', (
    WidgetTester tester,
  ) async {
    schedule(lifecycle: AppLifecycleState.inactive);
    await pumpSchedulerFrames(tester);

    expect(autoSignInCount, 0);
    expect(
      logs.any(
        (String line) => line.contains('lifecycle=AppLifecycleState.inactive'),
      ),
      isTrue,
    );
  });

  testWidgets('logs and skips when warm-up fails', (WidgetTester tester) async {
    final LoginAutoSignInScheduler failingScheduler =
        LoginAutoSignInScheduler();

    await tester.pumpWidget(const SizedBox.shrink());

    failingScheduler.scheduleWhenReady(
      warmUpPolicy: () async => throw StateError('warm-up failed'),
      shouldSkipAutoSignIn: () => false,
      isMounted: () => true,
      isRouteCurrent: () => true,
      lifecycleState: () => AppLifecycleState.resumed,
      onAutoSignIn: onAutoSignIn,
      log: log,
    );

    await tester.pump();
    await tester.pump();

    expect(autoSignInCount, 0);
    expect(failingScheduler.isScheduled, isFalse);
  });
}

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/presentation/services/login_navigate_to_home_scheduler.dart';
import 'package:tilawa/features/auth/presentation/services/login_sign_in_policy_warm_up.dart';

class _NavigateScheduleHost extends StatefulWidget {
  const _NavigateScheduleHost({required this.onNavigate});

  final VoidCallback onNavigate;

  @override
  State<_NavigateScheduleHost> createState() => _NavigateScheduleHostState();
}

class _NavigateScheduleHostState extends State<_NavigateScheduleHost> {
  @override
  void initState() {
    super.initState();
    scheduleLoginNavigateToHome(
      isMounted: () => mounted,
      navigate: widget.onNavigate,
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  group('scheduleLoginNavigateToHome', () {
    testWidgets('navigates after frame when mounted', (
      WidgetTester tester,
    ) async {
      var navigateCount = 0;

      await tester.pumpWidget(
        _NavigateScheduleHost(onNavigate: () => navigateCount++),
      );
      await tester.pump();

      check(navigateCount).equals(1);
    });

    testWidgets('skips navigation when unmounted', (WidgetTester tester) async {
      var navigateCount = 0;

      await tester.pumpWidget(const SizedBox.shrink());
      scheduleLoginNavigateToHome(
        isMounted: () => false,
        navigate: () => navigateCount++,
      );
      await tester.pump();

      check(navigateCount).equals(0);
    });
  });

  group('warmUpLoginSignInPolicy', () {
    test('returns immediately when policy is not registered', () async {
      var warmUpCount = 0;

      await warmUpLoginSignInPolicy(
        isPolicyRegistered: false,
        warmUp: () async => warmUpCount++,
      );

      check(warmUpCount).equals(0);
    });

    test('runs warm-up when policy is registered', () async {
      var warmUpCount = 0;

      await warmUpLoginSignInPolicy(
        isPolicyRegistered: true,
        warmUp: () async => warmUpCount++,
      );

      check(warmUpCount).equals(1);
    });
  });
}

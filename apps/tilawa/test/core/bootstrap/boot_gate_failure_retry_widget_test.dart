import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/bootstrap/app_startup.dart';
import 'package:tilawa/core/bootstrap/app_startup_tasks.dart';

void main() {
  testWidgets('fatal startup screen exposes retry action', (tester) async {
    var retried = false;
    final Widget app = AppStartupTasks().buildFatalErrorApp(
      onRetry: () async {
        retried = true;
      },
    );

    await tester.pumpWidget(app);
    expect(find.textContaining('Retry'), findsOneWidget);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(retried, isTrue);
  });
}

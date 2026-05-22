import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_blocked_flow.dart';
import 'package:tilawa/features/app_review/domain/services/app_review_flow_guard.dart';
import 'package:tilawa/features/app_review/presentation/widgets/app_review_sacred_flow_scope.dart';

void main() {
  late AppReviewFlowGuard guard;

  setUp(() {
    guard = AppReviewFlowGuard();
    if (getIt.isRegistered<AppReviewFlowGuard>()) {
      getIt.unregister<AppReviewFlowGuard>();
    }
    getIt.registerSingleton<AppReviewFlowGuard>(guard);
  });

  tearDown(() {
    if (getIt.isRegistered<AppReviewFlowGuard>()) {
      getIt.unregister<AppReviewFlowGuard>();
    }
  });

  testWidgets('enters flow on mount and exits on dispose', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppReviewSacredFlowScope(
          flow: AppReviewBlockedFlow.athkar,
          child: SizedBox(),
        ),
      ),
    );

    expect(guard.isSacredFlowActive, isTrue);
    expect(guard.activeFlows, contains(AppReviewBlockedFlow.athkar));

    await tester.pumpWidget(const SizedBox());

    expect(guard.isSacredFlowActive, isFalse);
  });
}

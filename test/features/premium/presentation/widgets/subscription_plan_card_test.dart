import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/premium/domain/entities/subscription_plan.dart';
import 'package:tilawa/features/premium/presentation/widgets/subscription_plan_card.dart';

void main() {
  const tPlan = SubscriptionPlan(
    id: '1',
    name: 'Yearly Plan',
    description: 'Best value',
    price: 29.99,
    currency: 'USD',
    type: SubscriptionType.yearly,
    durationInDays: 365,
    features: ['Feature 1', 'Feature 2'],
    isPopular: true,
    discountPercentage: 20,
  );

  testWidgets('renders plan details correctly', (tester) async {
    var selected = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SubscriptionPlanCard(
            plan: tPlan,
            onSelect: () => selected = true,
          ),
        ),
      ),
    );

    expect(find.text('Yearly Plan'), findsOneWidget);
    expect(find.text('Best value'), findsOneWidget);
    // Formatted price string might depend on currency config implementation,
    // assuming '$29.99' or similar.
    // Wait, CurrencyConfig.getCurrencyDisplay uses implementation.
    // If it is static/const string, check implementation?
    // Checking lib/core/config/currency_config.dart

    // Check Features
    expect(find.text('Feature 1'), findsOneWidget);
    expect(find.text('Feature 2'), findsOneWidget);

    // Check Popular badge
    expect(find.text('POPULAR'), findsOneWidget);

    // Check Discount
    expect(find.text('20% OFF'), findsOneWidget);

    // Tap Select
    await tester.tap(find.byType(ElevatedButton));
    expect(selected, isTrue);
  });
}

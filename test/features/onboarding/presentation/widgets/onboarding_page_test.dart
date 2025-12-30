import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/onboarding/presentation/widgets/onboarding_content.dart';
import 'package:tilawa/features/onboarding/presentation/widgets/onboarding_page.dart';

void main() {
  testWidgets('renders onboarding page content', (tester) async {
    const content = OnboardingContent(
      imagePath: 'assets/images/listener.png', // Use real asset
      title: 'Test Title',
      description: 'Test Description',
    );

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(375, 812),
        builder: (_, _) => const MaterialApp(
          home: Scaffold(body: OnboardingPage(content: content)),
        ),
      ),
    );

    expect(find.text('Test Title'), findsOneWidget);
    expect(find.text('Test Description'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}

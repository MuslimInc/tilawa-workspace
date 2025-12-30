import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:tilawa/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

class MockOnboardingCubit extends MockCubit<OnboardingState>
    implements OnboardingCubit {}

void main() {
  late MockOnboardingCubit mockOnboardingCubit;
  final GetIt getIt = GetIt.instance;

  setUp(() {
    mockOnboardingCubit = MockOnboardingCubit();
    if (getIt.isRegistered<OnboardingCubit>()) {
      getIt.unregister<OnboardingCubit>();
    }
    getIt.registerSingleton<OnboardingCubit>(mockOnboardingCubit);
  });

  tearDown(() {
    getIt.reset();
  });

  Widget buildTestWidget() {
    return ScreenUtilPlusInit(
      designSize: const Size(375, 812),
      builder: (_, _) => const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OnboardingScreen(),
      ),
    );
  }

  testWidgets('renders onboarding screen and interacts', (tester) async {
    when(() => mockOnboardingCubit.state).thenReturn(OnboardingInitial());
    when(() => mockOnboardingCubit.pageChanged(any())).thenReturn(null);
    when(
      () => mockOnboardingCubit.completeOnboarding(),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Verify first page content
    // Assuming 'onboardingTitle1' maps to string in app_en.arb.
    // Since we don't know the exact string content without inspecting arb or stubbing l10n,
    // we can rely on verifying widgets by type or assumption.
    // Or we can find by type OnboardingPage.

    expect(find.text('Next'), findsOneWidget);

    // Tap Next
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Verify page changed
    verify(() => mockOnboardingCubit.pageChanged(1)).called(1);

    // Navigate to last page
    // There are 3 pages.
    // Current is 1 (index 1? No, next button moves page view only?)
    // In OnboardingScreen:
    // _pageController.nextPage(...)
    // onPageChanged calls cubit.pageChanged.

    // We need to trigger the page view scroll or simulate it.
    // tester.tap(Next) triggers nextPage animation.
    // pumpAndSettle waits for animation.

    // Tap Next again (Page 1 -> 2)
    final Finder nextBtn = find.text('Next');
    // It might be finding the same widget if it didn't change text.
    await tester.tap(nextBtn);
    await tester.pumpAndSettle();

    verify(() => mockOnboardingCubit.pageChanged(2)).called(1);

    // Now on last page (index 2).
    // Button should be 'Start Journey'.

    expect(
      find.text("Let's start our journey with the Quran"),
      findsOneWidget,
    ); // Assuming l10n.startJourney

    // Tap Start
    await tester.tap(find.text("Let's start our journey with the Quran"));
    await tester.pumpAndSettle();

    verify(() => mockOnboardingCubit.completeOnboarding()).called(1);
  });
}

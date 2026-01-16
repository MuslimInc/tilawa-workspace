import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/premium/domain/entities/premium_status.dart';
import 'package:tilawa/features/premium/presentation/bloc/premium_bloc.dart';
import 'package:tilawa/features/premium/presentation/bloc/premium_event.dart';
import 'package:tilawa/features/premium/presentation/bloc/premium_state.dart';
import 'package:tilawa/features/premium/presentation/screens/premium_screen.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

class MockPremiumBloc extends MockBloc<PremiumEvent, PremiumState>
    implements PremiumBloc {}

void main() {
  late MockPremiumBloc mockPremiumBloc;

  setUp(() {
    mockPremiumBloc = MockPremiumBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<PremiumBloc>.value(
        value: mockPremiumBloc,
        child: const PremiumScreen(),
      ),
    );
  }

  testWidgets('should display loading indicator when state is loading', (
    WidgetTester tester,
  ) async {
    // Arrange
    when(() => mockPremiumBloc.state).thenReturn(const PremiumState.loading());

    // Act
    await tester.pumpWidget(createWidgetUnderTest());

    // Assert
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('should display premium status and plans when state is loaded', (
    WidgetTester tester,
  ) async {
    // Arrange
    final tStatus = PremiumStatus(
      isPremium: true,
      subscriptionStartDate: DateTime.now(),
      subscriptionEndDate: null,
      subscriptionType: 'lifetime',
      isTrialUsed: false,
      trialStartDate: null,
      trialEndDate: null,
    );
    when(() => mockPremiumBloc.state).thenReturn(
      PremiumState.loaded(
        status: tStatus,
        availablePlans: const [],
        canDownload: true,
      ),
    );

    // Act
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Assert
    expect(find.text(tStatus.statusText), findsOneWidget);
    expect(find.text('Premium Features'), findsOneWidget);
  });

  testWidgets('should display error message when state is error', (
    WidgetTester tester,
  ) async {
    // Arrange
    const tMessage = 'Error loading premium';
    when(
      () => mockPremiumBloc.state,
    ).thenReturn(const PremiumState.error(message: tMessage));

    // Act
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Assert
    expect(find.text(tMessage), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}

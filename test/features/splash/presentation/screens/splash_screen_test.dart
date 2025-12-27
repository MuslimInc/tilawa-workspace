import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/splash/presentation/cubit/splash_cubit.dart';
import 'package:tilawa/features/splash/presentation/screens/splash_screen.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

class MockSplashCubit extends MockCubit<SplashState> implements SplashCubit {}

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockSplashCubit mockSplashCubit;
  late MockGoRouter mockGoRouter;
  final GetIt getIt = GetIt.instance;

  setUp(() {
    mockSplashCubit = MockSplashCubit();
    mockGoRouter = MockGoRouter();
    if (getIt.isRegistered<SplashCubit>()) {
      getIt.unregister<SplashCubit>();
    }
    getIt.registerSingleton<SplashCubit>(mockSplashCubit);
  });

  tearDown(() {
    getIt.reset();
  });

  Widget buildTestWidget() {
    return ScreenUtilPlusInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: InheritedGoRouter(
          goRouter: mockGoRouter,
          child: const SplashScreen(),
        ),
      ),
    );
  }

  testWidgets('renders splash screen UI', (tester) async {
    when(() => mockSplashCubit.state).thenReturn(const SplashInitial());
    when(() => mockSplashCubit.init()).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Tilawa'), findsOneWidget);
  });

  testWidgets('calls init on cubit', (tester) async {
    when(() => mockSplashCubit.state).thenReturn(const SplashInitial());
    when(() => mockSplashCubit.init()).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    verify(() => mockSplashCubit.init()).called(1);
  });

  testWidgets('navigates to home when state is SplashNavigateToHome', (
    tester,
  ) async {
    final streamController = StreamController<SplashState>.broadcast();
    when(() => mockSplashCubit.state).thenReturn(const SplashInitial());
    when(
      () => mockSplashCubit.stream,
    ).thenAnswer((_) => streamController.stream);
    when(() => mockSplashCubit.init()).thenAnswer((_) async {});
    when(() => mockGoRouter.go(any())).thenReturn(null);

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    streamController.add(const SplashNavigateToHome());
    await tester.pump();

    verify(() => mockGoRouter.go('/')).called(1);

    await streamController.close();
  });

  testWidgets('navigates to login when state is SplashNavigateToLogin', (
    tester,
  ) async {
    final streamController = StreamController<SplashState>.broadcast();
    when(() => mockSplashCubit.state).thenReturn(const SplashInitial());
    when(
      () => mockSplashCubit.stream,
    ).thenAnswer((_) => streamController.stream);
    when(() => mockSplashCubit.init()).thenAnswer((_) async {});
    when(() => mockGoRouter.go(any())).thenReturn(null);

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    streamController.add(const SplashNavigateToLogin());
    await tester.pump();

    verify(() => mockGoRouter.go('/login')).called(1);

    await streamController.close();
  });

  testWidgets(
    'navigates to onboarding when state is SplashNavigateToOnboarding',
    (tester) async {
      final streamController = StreamController<SplashState>.broadcast();
      when(() => mockSplashCubit.state).thenReturn(const SplashInitial());
      when(
        () => mockSplashCubit.stream,
      ).thenAnswer((_) => streamController.stream);
      when(() => mockSplashCubit.init()).thenAnswer((_) async {});
      when(() => mockGoRouter.go(any())).thenReturn(null);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      streamController.add(const SplashNavigateToOnboarding());
      await tester.pump();

      verify(() => mockGoRouter.go('/onboarding')).called(1);

      await streamController.close();
    },
  );
}

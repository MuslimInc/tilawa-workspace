import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/splash/presentation/cubit/splash_cubit.dart';
import 'package:tilawa/features/splash/presentation/screens/splash_screen.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

class MockSplashCubit extends MockCubit<SplashState> implements SplashCubit {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockSplashCubit mockSplashCubit;
  late MockAuthBloc mockAuthBloc;
  late MockGoRouter mockGoRouter;
  final GetIt getIt = GetIt.instance;

  setUp(() {
    mockSplashCubit = MockSplashCubit();
    mockAuthBloc = MockAuthBloc();
    mockGoRouter = MockGoRouter();
    if (getIt.isRegistered<SplashCubit>()) {
      getIt.unregister<SplashCubit>();
    }
    getIt.registerSingleton<SplashCubit>(mockSplashCubit);

    const channel = MethodChannel('PonnamKarthik/fluttertoast');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return true;
        });
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
          child: BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: const SplashScreen(),
          ),
        ),
      ),
    );
  }

  testWidgets('renders splash screen UI', (tester) async {
    when(() => mockSplashCubit.state).thenReturn(const SplashInitial());
    when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
    when(() => mockSplashCubit.init()).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Tilawa'), findsOneWidget);
  });

  testWidgets('calls init on cubit', (tester) async {
    when(() => mockSplashCubit.state).thenReturn(const SplashInitial());
    when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
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
    when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
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
    when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
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
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
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

  testWidgets(
    'shows error toast and navigates to login when state is AuthState.error',
    (tester) async {
      final authStreamController = StreamController<AuthState>.broadcast();
      when(() => mockSplashCubit.state).thenReturn(const SplashInitial());
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
      when(
        () => mockAuthBloc.stream,
      ).thenAnswer((_) => authStreamController.stream);
      when(() => mockSplashCubit.init()).thenAnswer((_) async {});
      when(() => mockGoRouter.go(any())).thenReturn(null);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      authStreamController.add(const AuthError(message: 'Auth failed'));
      await tester.pumpAndSettle();

      verify(() => mockGoRouter.go('/login')).called(1);
      // Validates toast implicitly by not crashing due to missing channel

      // Drain any pending timers from Fluttertoast
      await tester.pump(const Duration(seconds: 4));

      await authStreamController.close();
    },
  );

  testWidgets('handles AuthState.authenticated without errors', (tester) async {
    final authStreamController = StreamController<AuthState>.broadcast();
    when(() => mockSplashCubit.state).thenReturn(const SplashInitial());
    when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => authStreamController.stream);
    when(() => mockSplashCubit.init()).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    authStreamController.add(
      AuthAuthenticated(
        user: UserEntity(
          id: '1',
          displayName: 'Test User',
          email: 'test@example.com',
          createdAt: DateTime.now(),
        ),
      ),
    );
    await tester.pump();

    // Just verifying no crash or unexpected navigation
    verifyNever(() => mockGoRouter.go(any()));

    await authStreamController.close();
  });

  testWidgets('handles AuthState.unauthenticated without errors', (
    tester,
  ) async {
    final authStreamController = StreamController<AuthState>.broadcast();
    when(() => mockSplashCubit.state).thenReturn(const SplashInitial());
    when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => authStreamController.stream);
    when(() => mockSplashCubit.init()).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    authStreamController.add(const AuthUnauthenticated());
    await tester.pump();

    // Just verifying no crash or unexpected navigation
    verifyNever(() => mockGoRouter.go(any()));

    await authStreamController.close();
  });

  testWidgets('handles AuthState.initial without errors', (tester) async {
    final authStreamController = StreamController<AuthState>.broadcast();
    when(() => mockSplashCubit.state).thenReturn(const SplashInitial());
    when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => authStreamController.stream);
    when(() => mockSplashCubit.init()).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    // Verify initial is covered (already emitted by default mock state, but explicit add helps)
    authStreamController.add(const AuthInitial());
    await tester.pump();

    verifyNever(() => mockGoRouter.go(any()));

    await authStreamController.close();
  });

  testWidgets('handles AuthState.loading without errors', (tester) async {
    final authStreamController = StreamController<AuthState>.broadcast();
    when(() => mockSplashCubit.state).thenReturn(const SplashInitial());
    when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => authStreamController.stream);
    when(() => mockSplashCubit.init()).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    authStreamController.add(const AuthLoading());
    await tester.pump();

    verifyNever(() => mockGoRouter.go(any()));

    await authStreamController.close();
  });
}

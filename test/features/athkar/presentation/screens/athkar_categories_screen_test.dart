import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:muzakri/features/athkar/domain/entities/athkar_category.dart';
import 'package:muzakri/features/athkar/presentation/cubit/athkar_cubit.dart';
import 'package:muzakri/features/athkar/presentation/cubit/athkar_state.dart';
import 'package:muzakri/features/athkar/presentation/screens/athkar_categories_screen.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';

class MockAthkarCubit extends MockCubit<AthkarState> implements AthkarCubit {}

void main() {
  late MockAthkarCubit mockAthkarCubit;

  setUpAll(() {
    final GetIt getIt = GetIt.instance;
    if (!getIt.isRegistered<AthkarCubit>()) {
      mockAthkarCubit = MockAthkarCubit();
      getIt.registerSingleton<AthkarCubit>(mockAthkarCubit);
    }
  });

  setUp(() {
    mockAthkarCubit = GetIt.instance<AthkarCubit>() as MockAthkarCubit;
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en'), Locale('ar')],
      locale: Locale('en'),
      home: ScreenUtilPlusInit(
        designSize: Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        child: AthkarCategoriesScreen(),
      ),
    );
  }

  const tCategories = [
    AthkarCategory(
      id: 1,
      nameAr: 'أذكار الصباح',
      nameEn: 'Morning Athkar',
      icon: 'wb_sunny_rounded',
    ),
    AthkarCategory(
      id: 2,
      nameAr: 'أذكار المساء',
      nameEn: 'Evening Athkar',
      icon: 'nightlight_round',
    ),
  ];

  testWidgets('displays loading indicator when state is AthkarLoading', (
    tester,
  ) async {
    when(() => mockAthkarCubit.state).thenReturn(AthkarLoading());
    when(() => mockAthkarCubit.loadCategories()).thenAnswer((_) async {});

    await tester.pumpWidget(createWidgetUnderTest());
    // No need for tester.pump() here if we want to see the loading indicator immediately
    // but BlocProvider(create: ...) might trigger loadCategories immediately.

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('displays error message when state is AthkarError', (
    tester,
  ) async {
    const errorMessage = 'Failed to load categories';
    when(
      () => mockAthkarCubit.state,
    ).thenReturn(const AthkarError(errorMessage));
    when(() => mockAthkarCubit.loadCategories()).thenAnswer((_) async {});

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text(errorMessage), findsOneWidget);
  });

  testWidgets('displays categories when state is AthkarCategoriesLoaded', (
    tester,
  ) async {
    when(
      () => mockAthkarCubit.state,
    ).thenReturn(const AthkarCategoriesLoaded(tCategories));
    when(() => mockAthkarCubit.loadCategories()).thenAnswer((_) async {});

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('Morning Athkar'), findsOneWidget);
    expect(find.text('Evening Athkar'), findsOneWidget);
  });
}

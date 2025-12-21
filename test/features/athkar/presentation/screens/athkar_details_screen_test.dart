import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:muzakri/features/athkar/domain/entities/athkar_item.dart';
import 'package:muzakri/features/athkar/presentation/cubit/athkar_cubit.dart';
import 'package:muzakri/features/athkar/presentation/cubit/athkar_state.dart';
import 'package:muzakri/features/athkar/presentation/screens/athkar_details_screen.dart';
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
        child: AthkarDetailsScreen(
          categoryId: 1,
          categoryName: 'Morning Athkar',
        ),
      ),
    );
  }

  const tAthkarItems = [
    AthkarItem(
      id: 1,
      categoryId: 1,
      textAr: 'Test Ar',
      textEn: 'Test En',
      count: 3,
      reference: 'Test Ref',
    ),
  ];

  testWidgets('displays loading indicator when state is AthkarLoading', (
    tester,
  ) async {
    when(() => mockAthkarCubit.state).thenReturn(AthkarLoading());
    when(() => mockAthkarCubit.loadAthkar(any())).thenAnswer((_) async {});

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('displays items when state is AthkarItemsLoaded', (tester) async {
    when(() => mockAthkarCubit.state).thenReturn(
      const AthkarItemsLoaded(items: tAthkarItems, currentCounts: {1: 3}),
    );
    when(() => mockAthkarCubit.loadAthkar(any())).thenAnswer((_) async {});

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('Test En'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('interaction triggers decrementCount', (tester) async {
    when(() => mockAthkarCubit.state).thenReturn(
      const AthkarItemsLoaded(items: tAthkarItems, currentCounts: {1: 3}),
    );
    when(() => mockAthkarCubit.loadAthkar(any())).thenAnswer((_) async {});
    when(() => mockAthkarCubit.decrementCount(any())).thenReturn(null);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Tap the item (usually the whole card or the counter tap area)
    await tester.tap(find.text('Test En'));
    await tester.pump();

    verify(() => mockAthkarCubit.decrementCount(1)).called(1);
  });

  testWidgets('long press on item triggers resetCount', (tester) async {
    when(() => mockAthkarCubit.state).thenReturn(
      const AthkarItemsLoaded(items: tAthkarItems, currentCounts: {1: 1}),
    );
    when(() => mockAthkarCubit.loadAthkar(any())).thenAnswer((_) async {});
    when(() => mockAthkarCubit.resetCount(any())).thenReturn(null);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Long press the item
    await tester.longPress(find.text('Test En'));
    await tester.pump();

    verify(() => mockAthkarCubit.resetCount(1)).called(1);
  });
}

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muzakri/core/entities/reciter.dart';
import 'package:muzakri/features/alphabet_scrollbar/presentation/bloc/alphabet_scrollbar_bloc.dart';
import 'package:muzakri/features/localization/presentation/bloc/localization_bloc.dart';
import 'package:muzakri/features/reciters/presentation/bloc/reciters_bloc.dart';
import 'package:muzakri/features/reciters/presentation/screens/reciters_screen.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockRecitersBloc extends MockBloc<RecitersEvent, RecitersState>
    implements RecitersBloc {}

class MockAlphabetScrollbarBloc
    extends MockBloc<AlphabetScrollbarEvent, AlphabetScrollbarState>
    implements AlphabetScrollbarBloc {}

class MockLocalizationBloc
    extends MockBloc<LocalizationEvent, LocalizationState>
    implements LocalizationBloc {}

void main() {
  late MockRecitersBloc mockRecitersBloc;
  late MockAlphabetScrollbarBloc mockAlphabetScrollbarBloc;
  late MockLocalizationBloc mockLocalizationBloc;

  setUp(() {
    mockRecitersBloc = MockRecitersBloc();
    mockAlphabetScrollbarBloc = MockAlphabetScrollbarBloc();
    mockLocalizationBloc = MockLocalizationBloc();

    // Mock Shared Preferences to avoid late initialization error in ScreenUtil
    SharedPreferences.setMockInitialValues({});

    final TestWidgetsFlutterBinding binding =
        TestWidgetsFlutterBinding.ensureInitialized();
    binding.window.physicalSizeTestValue = const Size(
      1200 * 3,
      1600 * 3,
    ); // Large tablet
    binding.window.devicePixelRatioTestValue = 3;
  });

  tearDown(() {
    final TestWidgetsFlutterBinding binding =
        TestWidgetsFlutterBinding.ensureInitialized();
    binding.window.clearPhysicalSizeTestValue();
    binding.window.clearDevicePixelRatioTestValue();
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RecitersBloc>.value(value: mockRecitersBloc),
        BlocProvider<AlphabetScrollbarBloc>.value(
          value: mockAlphabetScrollbarBloc,
        ),
        BlocProvider<LocalizationBloc>.value(value: mockLocalizationBloc),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en')],
        home: ScreenUtilPlusInit(
          designSize: Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          child: RecitersScreen(),
        ),
      ),
    );
  }

  testWidgets(
    'RecitersScreen displays loading indicator when state is RecitersLoading',
    (tester) async {
      whenListen(
        mockRecitersBloc,
        Stream.fromIterable([const RecitersLoading()]),
        initialState: const RecitersLoading(),
      );
      whenListen(
        mockLocalizationBloc,
        Stream.fromIterable([const LocalizationState(locale: Locale('en'))]),
        initialState: const LocalizationState(locale: Locale('en')),
      );
      whenListen(
        mockAlphabetScrollbarBloc,
        Stream.fromIterable([const AlphabetScrollbarState()]),
        initialState: const AlphabetScrollbarState(),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );

  testWidgets(
    'RecitersScreen displays reciter cards when state is RecitersLoaded',
    (tester) async {
      final reciters = [
        const ReciterEntity(
          id: 1,
          name: 'Reciter 1',
          letter: 'A',
          date: '2023',
          moshaf: [],
        ),
        const ReciterEntity(
          id: 2,
          name: 'Reciter 2',
          letter: 'B',
          date: '2023',
          moshaf: [],
        ),
      ];

      whenListen(
        mockRecitersBloc,
        Stream.fromIterable([
          RecitersLoaded(reciters: reciters, filteredReciters: reciters),
        ]),
        initialState: RecitersLoaded(
          reciters: reciters,
          filteredReciters: reciters,
        ),
      );
      whenListen(
        mockLocalizationBloc,
        Stream.fromIterable([const LocalizationState(locale: Locale('en'))]),
        initialState: const LocalizationState(locale: Locale('en')),
      );
      whenListen(
        mockAlphabetScrollbarBloc,
        Stream.fromIterable([const AlphabetScrollbarState()]),
        initialState: const AlphabetScrollbarState(),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Reciter 1'), findsOneWidget);
    },
  );

  testWidgets(
    'RecitersScreen displays empty message when state is RecitersLoaded with empty list',
    (tester) async {
      whenListen(
        mockRecitersBloc,
        Stream.fromIterable([
          const RecitersLoaded(reciters: [], filteredReciters: []),
        ]),
        initialState: const RecitersLoaded(reciters: [], filteredReciters: []),
      );
      whenListen(
        mockLocalizationBloc,
        Stream.fromIterable([const LocalizationState(locale: Locale('en'))]),
        initialState: const LocalizationState(locale: Locale('en')),
      );
      whenListen(
        mockAlphabetScrollbarBloc,
        Stream.fromIterable([const AlphabetScrollbarState()]),
        initialState: const AlphabetScrollbarState(),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
    },
  );
}

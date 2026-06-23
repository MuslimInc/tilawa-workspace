import 'package:flutter/material.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/localization/domain/usecases/get_current_language_use_case.dart';
import 'package:tilawa/features/localization/domain/usecases/set_language_use_case.dart';
import 'package:tilawa/features/localization/presentation/bloc/localization_bloc.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_reciters_use_case.dart';
import 'package:tilawa/features/reciters/presentation/bloc/alphabet_scrollbar/alphabet_scrollbar_bloc.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciters_bloc.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciters_tabs_bloc.dart';
import 'package:tilawa/features/reciters/presentation/screens/reciters_screen.dart';
import 'package:tilawa/features/reciters/presentation/widgets/reciters_screen_scope.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../../../helpers/hydrated_bloc_test_helper.dart';
import '../../../../helpers/noop_sync_user_language_preference_use_case.dart';
import '../../../../support/screen_scope_test_support.dart';

class _MockGetRecitersUseCase extends Mock implements GetRecitersUseCase {}

class _MockGetCurrentLanguageUseCase extends Mock
    implements GetCurrentLanguageUseCase {}

class _MockSetLanguageUseCase extends Mock implements SetLanguageUseCase {}

Widget _wrapRecitersScopeTest({required Widget home}) {
  final getReciters = getIt<GetRecitersUseCase>();
  final getCurrentLanguage = _MockGetCurrentLanguageUseCase();
  final setLanguage = _MockSetLanguageUseCase();

  when(
    () => getCurrentLanguage(),
  ).thenAnswer((_) async => const Right('ar'));
  when(() => setLanguage(any())).thenAnswer((_) async => const Right(null));

  return MaterialApp(
    home: Scaffold(
      body: BlocProvider<LocalizationBloc>(
        create: (_) => LocalizationBloc(
          getCurrentLanguage,
          setLanguage,
          getReciters,
          noopSyncUserLanguagePreferenceUseCase(),
        ),
        child: home,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeHydratedStorageForTest();
  });

  late _MockGetRecitersUseCase mockGetReciters;

  const cachedReciters = [
    ReciterEntity(
      id: 1,
      name: 'Al-Afasy',
      letter: 'A',
      date: '2024',
      moshaf: [],
    ),
  ];

  setUp(() async {
    await resetScopeGetIt();
    mockGetReciters = _MockGetRecitersUseCase();
    when(() => mockGetReciters()).thenAnswer(
      (_) async => const Right<Failure, List<ReciterEntity>>([]),
    );
    when(() => mockGetReciters.takeCachedSuccessForStartup()).thenReturn(null);
    when(() => mockGetReciters.invalidateCache()).thenReturn(null);
    scopeGetIt().registerSingleton<GetRecitersUseCase>(mockGetReciters);
    scopeGetIt().registerFactory<AlphabetScrollbarBloc>(
      AlphabetScrollbarBloc.new,
    );
  });

  tearDown(() async {
    await resetScopeGetIt();
  });

  testWidgets(
    'provides RecitersBloc, RecitersTabsBloc, and AlphabetScrollbarBloc',
    (
      tester,
    ) async {
      RecitersBloc? recitersBloc;
      AlphabetScrollbarBloc? alphabetBloc;
      RecitersTabsBloc? tabsBloc;

      await tester.pumpWidget(
        _wrapRecitersScopeTest(
          home: RecitersScreenScope(
            child: ScopeProbe(
              onBuilt: (context) {
                recitersBloc = readScopeBloc<RecitersBloc>(context);
                alphabetBloc = readScopeBloc<AlphabetScrollbarBloc>(context);
                tabsBloc = readScopeBloc<RecitersTabsBloc>(context);
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(recitersBloc, isNotNull);
      expect(alphabetBloc, isNotNull);
      expect(tabsBloc, isNotNull);
      expect(tabsBloc!.state.selectedTab, RecitersHomeTab.all);
      verify(() => mockGetReciters.takeCachedSuccessForStartup()).called(1);
    },
  );

  testWidgets('seeds RecitersBloc from startup cache when available', (
    tester,
  ) async {
    when(
      () => mockGetReciters.takeCachedSuccessForStartup(),
    ).thenReturn(cachedReciters);

    RecitersBloc? recitersBloc;
    await tester.pumpWidget(
      _wrapRecitersScopeTest(
        home: RecitersScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              recitersBloc = readScopeBloc<RecitersBloc>(context);
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(recitersBloc!.state, isA<RecitersLoaded>());
    final loaded = recitersBloc!.state as RecitersLoaded;
    expect(loaded.reciters, cachedReciters);
  });

  testWidgets('creates fresh AlphabetScrollbarBloc instances on remount', (
    tester,
  ) async {
    AlphabetScrollbarBloc? first;
    AlphabetScrollbarBloc? second;

    await tester.pumpWidget(
      _wrapRecitersScopeTest(
        home: RecitersScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              first = readScopeBloc<AlphabetScrollbarBloc>(context);
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await unmountScope(tester);

    await tester.pumpWidget(
      _wrapRecitersScopeTest(
        home: RecitersScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              second = readScopeBloc<AlphabetScrollbarBloc>(context);
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(first, isNotNull);
    expect(second, isNotNull);
    expect(first, isNot(same(second)));
  });

  testWidgets('closes scoped blocs when unmounted', (tester) async {
    RecitersBloc? recitersBloc;
    AlphabetScrollbarBloc? alphabetBloc;

    await tester.pumpWidget(
      _wrapRecitersScopeTest(
        home: RecitersScreenScope(
          child: ScopeProbe(
            onBuilt: (context) {
              recitersBloc = readScopeBloc<RecitersBloc>(context);
              alphabetBloc = readScopeBloc<AlphabetScrollbarBloc>(context);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(recitersBloc!.isClosed, isFalse);
    expect(alphabetBloc!.isClosed, isFalse);

    await unmountScope(tester);

    expect(recitersBloc!.isClosed, isTrue);
    expect(alphabetBloc!.isClosed, isTrue);
  });

  testWidgets('renders probe child instead of RecitersScreen', (tester) async {
    await tester.pumpWidget(
      _wrapRecitersScopeTest(
        home: RecitersScreenScope(
          child: ScopeProbe(onBuilt: (_) {}),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('scope_probe')), findsOneWidget);
    expect(find.byType(RecitersScreen), findsNothing);
  });
}

import 'dart:async';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/localization/domain/usecases/get_current_language_use_case.dart';
import 'package:tilawa/features/localization/domain/usecases/set_language_use_case.dart';
import 'package:tilawa/features/localization/presentation/bloc/localization_bloc.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_reciters_use_case.dart';
import 'package:tilawa/features/reciters/presentation/bloc/alphabet_scrollbar/alphabet_scrollbar_bloc.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciters_bloc.dart';
import 'package:tilawa/features/reciters/presentation/screens/reciters_screen.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class _MockGetRecitersUseCase extends Mock implements GetRecitersUseCase {}

class _MockGetCurrentLanguageUseCase extends Mock
    implements GetCurrentLanguageUseCase {}

class _MockSetLanguageUseCase extends Mock implements SetLanguageUseCase {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const reciters = <ReciterEntity>[
    ReciterEntity(
      id: 1,
      name: 'Alpha Reciter',
      letter: 'A',
      date: '',
      moshaf: [],
    ),
  ];

  late _MockGetRecitersUseCase mockGetReciters;
  late _MockGetCurrentLanguageUseCase mockGetLanguage;
  late _MockSetLanguageUseCase mockSetLanguage;

  setUp(() {
    mockGetReciters = _MockGetRecitersUseCase();
    mockGetLanguage = _MockGetCurrentLanguageUseCase();
    mockSetLanguage = _MockSetLanguageUseCase();

    when(() => mockGetLanguage()).thenAnswer(
      (_) async => const Right<Failure, String>('en'),
    );
    when(() => mockSetLanguage(any())).thenAnswer(
      (_) async => const Right<Failure, void>(null),
    );
  });

  Widget buildApp(RecitersBloc bloc) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RecitersBloc>.value(value: bloc),
        BlocProvider<AlphabetScrollbarBloc>(
          create: (_) => AlphabetScrollbarBloc(),
        ),
        BlocProvider<LocalizationBloc>(
          create: (_) => LocalizationBloc(mockGetLanguage, mockSetLanguage),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          extensions: [
            TilawaDesignTokens.light(),
            TilawaComponentTokens.light(),
          ],
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const RecitersScreen(),
      ),
    );
  }

  group('RecitersScreen startup', () {
    testWidgets('shows list immediately when bloc is already loaded', (
      WidgetTester tester,
    ) async {
      when(() => mockGetReciters()).thenAnswer(
        (_) async => const Right<Failure, List<ReciterEntity>>(reciters),
      );
      final RecitersBloc bloc = RecitersBloc(mockGetReciters);
      bloc.add(const LoadReciters());
      await bloc.stream.firstWhere((s) => s is RecitersLoaded);

      await tester.pumpWidget(buildApp(bloc));
      await tester.pump();

      expect(find.text('Alpha Reciter'), findsOneWidget);
      expect(find.byType(TilawaLoadingIndicator), findsNothing);

      await bloc.close();
    });

    testWidgets('shows loading indicator when bloc is still loading', (
      WidgetTester tester,
    ) async {
      final completer = Completer<Either<Failure, List<ReciterEntity>>>();
      when(() => mockGetReciters()).thenAnswer((_) => completer.future);

      final RecitersBloc bloc = RecitersBloc(mockGetReciters);
      bloc.add(const LoadReciters());
      await bloc.stream.firstWhere((s) => s is RecitersLoading);

      await tester.pumpWidget(buildApp(bloc));
      await tester.pump();

      expect(find.byType(TilawaLoadingIndicator), findsOneWidget);
      expect(find.text('Alpha Reciter'), findsNothing);

      completer.complete(
        const Right<Failure, List<ReciterEntity>>(reciters),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Alpha Reciter'), findsOneWidget);

      await bloc.close();
    });

    testWidgets('defers fetch when bloc is still initial', (
      WidgetTester tester,
    ) async {
      when(() => mockGetReciters()).thenAnswer(
        (_) async => const Right<Failure, List<ReciterEntity>>(reciters),
      );
      final RecitersBloc bloc = RecitersBloc(mockGetReciters);

      await tester.pumpWidget(buildApp(bloc));
      await tester.pump();

      expect(find.byType(TilawaLoadingIndicator), findsNothing);

      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('Alpha Reciter'), findsNothing);

      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump();

      expect(find.text('Alpha Reciter'), findsOneWidget);

      await bloc.close();
    });
  });
}

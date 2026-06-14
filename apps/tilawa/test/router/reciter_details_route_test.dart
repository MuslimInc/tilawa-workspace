import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciter_details_bloc.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciter_download_bloc.dart';
import 'package:tilawa/features/reciters/presentation/cubit/reciter_details_loader_cubit.dart';
import 'package:tilawa/features/reciters/presentation/cubit/reciter_details_loader_state.dart';
import 'package:tilawa/features/reciters/presentation/screens/reciter_details_loader.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

import 'router_mock_helper.mocks.dart';

void main() {
  late MockGoRouterState mockState;
  late MockReciterDetailsLoaderCubit mockLoaderCubit;
  late MockReciterDetailsBloc mockDetailsBloc;
  late MockReciterDownloadBloc mockDownloadBloc;

  const tReciter = ReciterEntity(
    id: 1,
    name: 'Test Reciter',
    letter: 'T',
    date: '2024-01-01',
    moshaf: [],
  );

  setUpAll(() {
    provideDummy<ReciterDetailsLoaderState>(
      const ReciterDetailsLoaderInitial(),
    );
    provideDummy<ReciterDetailsState>(const ReciterDetailsState());
    provideDummy<ReciterDownloadState>(const ReciterDownloadState());
  });

  setUp(() {
    mockState = MockGoRouterState();
    mockLoaderCubit = MockReciterDetailsLoaderCubit();
    mockDetailsBloc = MockReciterDetailsBloc();
    mockDownloadBloc = MockReciterDownloadBloc();

    when(mockLoaderCubit.state).thenReturn(const ReciterDetailsLoaderLoading());
    when(mockLoaderCubit.stream).thenAnswer((_) => const Stream.empty());
    when(mockDetailsBloc.state).thenReturn(const ReciterDetailsState());
    when(mockDetailsBloc.stream).thenAnswer((_) => const Stream.empty());
    when(mockDownloadBloc.state).thenReturn(const ReciterDownloadState());
    when(mockDownloadBloc.stream).thenAnswer((_) => const Stream.empty());

    if (getIt.isRegistered<ReciterDetailsLoaderCubit>()) {
      getIt.unregister<ReciterDetailsLoaderCubit>();
    }
    if (getIt.isRegistered<ReciterDetailsBloc>()) {
      getIt.unregister<ReciterDetailsBloc>();
    }
    if (getIt.isRegistered<ReciterDownloadBloc>()) {
      getIt.unregister<ReciterDownloadBloc>();
    }

    getIt.registerFactory<ReciterDetailsLoaderCubit>(() => mockLoaderCubit);
    getIt.registerFactory<ReciterDetailsBloc>(() => mockDetailsBloc);
    getIt.registerFactory<ReciterDownloadBloc>(() => mockDownloadBloc);
  });

  tearDown(() async {
    if (getIt.isRegistered<ReciterDetailsLoaderCubit>()) {
      await getIt.unregister<ReciterDetailsLoaderCubit>();
    }
    if (getIt.isRegistered<ReciterDetailsBloc>()) {
      await getIt.unregister<ReciterDetailsBloc>();
    }
    if (getIt.isRegistered<ReciterDownloadBloc>()) {
      await getIt.unregister<ReciterDownloadBloc>();
    }
  });

  Future<Widget> buildRoute(
    WidgetTester tester,
    ReciterDetailsRoute route, {
    bool mountBuiltWidget = false,
  }) async {
    Widget? built;
    final GoRouter router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            built = route.build(context, mockState);
            return mountBuiltWidget ? built! : const Placeholder();
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.getLightTheme(
          primaryColor: PrimaryColorPreset.defaultPreset.value,
        ).copyWith(splashFactory: InkRipple.splashFactory),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );

    return built!;
  }

  group('ReciterDetailsRoute', () {
    testWidgets('returns empty widget when reciterId is missing', (
      tester,
    ) async {
      when(mockState.pathParameters).thenReturn(<String, String>{});

      final Widget built = await buildRoute(
        tester,
        const ReciterDetailsRoute(),
      );

      expect(built, isA<SizedBox>());
      expect((built as SizedBox).child, isNull);

      await tester.pump();
    });

    testWidgets('loads reciter when extra is missing but id is present', (
      tester,
    ) async {
      when(mockState.pathParameters).thenReturn(<String, String>{});
      when(mockState.extra).thenReturn(null);

      final Widget built = await buildRoute(
        tester,
        const ReciterDetailsRoute(reciterId: '7'),
        mountBuiltWidget: true,
      );

      expect(built, isA<ReciterDetailsLoader>());
      expect(find.byType(ReciterDetailsLoader), findsOneWidget);
      verify(mockLoaderCubit.loadReciter('7')).called(1);
    });

    testWidgets(
      'builds details screen providers when route extra is provided',
      (
        tester,
      ) async {
        when(mockState.pathParameters).thenReturn(<String, String>{});

        final Widget built = await buildRoute(
          tester,
          const ReciterDetailsRoute(reciterId: '7', $extra: tReciter),
        );

        expect(built, isA<MultiBlocProvider>());
      },
    );

    testWidgets('builds details screen providers when state.extra is present', (
      tester,
    ) async {
      when(mockState.pathParameters).thenReturn(<String, String>{});
      when(mockState.extra).thenReturn(tReciter);

      final Widget built = await buildRoute(
        tester,
        const ReciterDetailsRoute(reciterId: '7'),
      );

      expect(built, isA<MultiBlocProvider>());
    });

    testWidgets('resolves reciterId from path parameters', (tester) async {
      when(mockState.pathParameters).thenReturn(<String, String>{
        'reciterId': '9',
      });
      when(mockState.extra).thenReturn(null);

      final Widget built = await buildRoute(
        tester,
        const ReciterDetailsRoute(),
        mountBuiltWidget: true,
      );

      expect(built, isA<ReciterDetailsLoader>());
      verify(mockLoaderCubit.loadReciter('9')).called(1);
    });
  });
}

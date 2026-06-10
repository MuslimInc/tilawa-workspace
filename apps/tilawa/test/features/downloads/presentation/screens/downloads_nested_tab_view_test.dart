import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:tilawa/features/downloads/presentation/screens/downloads_screen.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class MockDownloadsBloc extends Mock implements DownloadsBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDownloadsBloc mockDownloadsBloc;

  setUpAll(() {
    registerFallbackValue(const LoadDownloads());
  });

  setUp(() {
    mockDownloadsBloc = MockDownloadsBloc();
    when(() => mockDownloadsBloc.state).thenReturn(
      const DownloadsState(status: DownloadsStateStatus.loading),
    );
    when(
      () => mockDownloadsBloc.stream,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockDownloadsBloc.close()).thenAnswer((_) async {});
    when(() => mockDownloadsBloc.add(any())).thenReturn(null);
  });

  Widget buildNestedDownloadsTab(Widget child) {
    return MaterialApp(
      theme: AppTheme.getLightTheme(
        primaryColor: PrimaryColorPreset.defaultPreset.value,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverOverlapAbsorber(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                    context,
                  ),
                  sliver: const SliverToBoxAdapter(
                    child: SizedBox(height: 72),
                  ),
                ),
              ];
            },
            body: BlocProvider<DownloadsBloc>.value(
              value: mockDownloadsBloc,
              child: child,
            ),
          );
        },
      ),
    );
  }

  Finder nestedDownloadsScrollView() {
    return find.descendant(
      of: find.byType(DownloadsNestedTabView),
      matching: find.byType(CustomScrollView),
    );
  }

  testWidgets(
    'DownloadsNestedTabView injects overlap and scrolls with parent',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        buildNestedDownloadsTab(
          const DownloadsNestedTabView(),
        ),
      );
      await tester.pump();

      expect(find.byType(DownloadsNestedTabView), findsOneWidget);
      expect(nestedDownloadsScrollView(), findsOneWidget);

      final CustomScrollView scrollView = tester.widget(
        nestedDownloadsScrollView(),
      );
      expect(scrollView.slivers.first, isA<SliverOverlapInjector>());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('DownloadsNestedTabView keeps always-scrollable physics', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildNestedDownloadsTab(
        const DownloadsNestedTabView(),
      ),
    );
    await tester.pump();

    final CustomScrollView scrollView = tester.widget(
      nestedDownloadsScrollView(),
    );
    expect(scrollView.physics, isA<AlwaysScrollableScrollPhysics>());
  });

  testWidgets(
    'DownloadsNestedTabView lays out empty loaded state without exceptions',
    (tester) async {
      when(() => mockDownloadsBloc.state).thenReturn(
        const DownloadsState(
          status: DownloadsStateStatus.loaded,
          downloads: {},
        ),
      );

      await tester.pumpWidget(
        buildNestedDownloadsTab(
          const DownloadsNestedTabView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No downloads yet'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TilawaIllustratedState),
          matching: find.byType(TilawaButton),
        ),
        findsOneWidget,
      );
      expect(find.text('Reciters'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'DownloadsNestedTabView browse reciters action invokes callback',
    (tester) async {
      var browseRecitersTapped = false;

      when(() => mockDownloadsBloc.state).thenReturn(
        const DownloadsState(
          status: DownloadsStateStatus.loaded,
          downloads: {},
        ),
      );

      await tester.pumpWidget(
        buildNestedDownloadsTab(
          DownloadsNestedTabView(
            onBrowseReciters: () => browseRecitersTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TilawaButton, 'Reciters'));
      await tester.pumpAndSettle();

      expect(browseRecitersTapped, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'DownloadsNestedTabView uses PrimaryScrollController inside NestedScrollView',
    (tester) async {
      when(() => mockDownloadsBloc.state).thenReturn(
        const DownloadsState(
          status: DownloadsStateStatus.loaded,
          downloads: {},
        ),
      );

      await tester.pumpWidget(
        buildNestedDownloadsTab(
          const DownloadsNestedTabView(),
        ),
      );
      await tester.pumpAndSettle();

      final CustomScrollView scrollView = tester.widget(
        nestedDownloadsScrollView(),
      );
      expect(scrollView.controller, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tilawa/features/audio_player/presentation/widgets/quran_player/quran_player_widget.dart';
import 'package:tilawa/shared/widgets/quran_player_chrome.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Widget _wrapRouter({
  required Widget child,
  EdgeInsets viewPadding = EdgeInsets.zero,
  String initialLocation = '/downloads',
}) {
  final GoRouter router = GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (context, state) => child),
      GoRoute(path: '/downloads', builder: (context, state) => child),
    ],
  );

  return MediaQuery(
    data: MediaQueryData(viewPadding: viewPadding),
    child: ChangeNotifierProvider<QuranPlayerChromeNotifier>(
      create: (_) => QuranPlayerChromeNotifier(),
      child: MaterialApp.router(
        theme: ThemeData(
          extensions: <ThemeExtension<dynamic>>[
            TilawaDesignTokens.light(),
          ],
        ),
        routerConfig: router,
      ),
    ),
  );
}

void main() {
  group('QuranPlayerWidget public layout API', () {
    testWidgets(
      'collapsedFootprint uses player height + spacing on shell routes',
      (
        tester,
      ) async {
        late double footprint;
        await tester.pumpWidget(
          _wrapRouter(
            child: Builder(
              builder: (BuildContext context) {
                footprint = QuranPlayerWidget.collapsedFootprint(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        final TilawaDesignTokens tokens = TilawaDesignTokens.light();
        expect(
          footprint,
          tokens.playerCollapsedHeight + tokens.spaceExtraLarge,
        );
      },
    );

    testWidgets('fabBottomOffset returns footprint off shell phone layout', (
      tester,
    ) async {
      late double offset;
      await tester.pumpWidget(
        _wrapRouter(
          initialLocation: '/downloads',
          child: Builder(
            builder: (BuildContext context) {
              offset = QuranPlayerWidget.fabBottomOffset(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(offset, greaterThan(0));
    });

    testWidgets('collapsedHeight reads design token', (tester) async {
      late double height;
      await tester.pumpWidget(
        _wrapRouter(
          child: Builder(
            builder: (BuildContext context) {
              height = QuranPlayerWidget.collapsedHeight(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(height, TilawaDesignTokens.light().playerCollapsedHeight);
    });
  });

  group('QuranPlayerExpandedPageContent', () {
    test('is a StatelessWidget with required callbacks', () {
      const Widget widget = QuranPlayerExpandedPageContent(
        expandAnimation: AlwaysStoppedAnimation<double>(0),
        onCollapse: _noop,
        onDismiss: _noop,
        onExpandDragStart: _noop,
        onExpandDragUpdate: _noopDouble,
        onExpandDragEnd: _noopDragEnd,
      );
      expect(widget, isA<StatelessWidget>());
    });
  });
}

void _noop() {}

void _noopDouble(double _) {}

void _noopDragEnd(DragEndDetails _) {}

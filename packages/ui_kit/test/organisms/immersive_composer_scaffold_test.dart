import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/foundation/component_tokens/component_tokens_theme.dart';
import '../../lib/src/foundation/design_tokens.dart';
import '../../lib/src/organisms/immersive_composer_scaffold.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      extensions: [
        MeMuslimDesignTokens.light(),
        MeMuslimComponentTokens.light(),
      ],
    ),
    home: child,
  );
}

// Animation controller duration used in ImmersiveComposerScaffold defaults.
const _kTransitionDuration = Duration(milliseconds: 300);

void main() {
  group('ImmersiveComposerScaffold', () {
    testWidgets('renders preview content and bottom panel', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ImmersiveComposerScaffold(
            title: 'Test Title',
            disableBlur: true,
            preview: const ColoredBox(
              color: Colors.black,
              child: SizedBox.expand(),
            ),
            bottomPanel: const Text('bottom-panel'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Test Title'), findsWidgets);
      expect(find.text('bottom-panel'), findsOneWidget);
      expect(find.byType(ImmersiveComposerScaffold), findsOneWidget);
    });

    testWidgets(
      'tap on preview toggles overlay visibility in uncontrolled mode',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            ImmersiveComposerScaffold(
              title: 'Title',
              disableBlur: true,
              preview: const ColoredBox(
                color: Colors.blue,
                child: SizedBox.expand(),
              ),
              bottomPanel: const Text('bottom-panel'),
            ),
          ),
        );
        await tester.pump();

        // Overlays start visible — bottom panel text is present.
        expect(find.text('bottom-panel'), findsOneWidget);

        // Tap on the preview area to toggle visibility off.
        await tester.tap(find.byType(ColoredBox).first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(_kTransitionDuration);

        // Tap again to toggle visibility back on.
        await tester.tap(find.byType(ColoredBox).first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(_kTransitionDuration);

        // After full cycle, bottom panel should still be in the tree.
        expect(find.text('bottom-panel'), findsOneWidget);
      },
    );

    testWidgets(
      'controlled overlaysVisible=false starts with hidden overlays',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            ImmersiveComposerScaffold(
              title: 'Hidden Title',
              disableBlur: true,
              // overlaysVisible: false → _hasBeenShown = false on first frame,
              // so overlay children render SizedBox.shrink().
              overlaysVisible: false,
              preview: const ColoredBox(
                color: Colors.black,
                child: SizedBox.expand(),
              ),
              bottomPanel: const Text('bottom-panel-hidden'),
            ),
          ),
        );
        await tester.pump();

        // Overlays start hidden — bottom panel text should not be visible.
        expect(find.text('bottom-panel-hidden'), findsNothing);
      },
    );

    testWidgets(
      'controlled overlaysVisible=true starts with visible overlays',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            ImmersiveComposerScaffold(
              title: 'Visible Title',
              disableBlur: true,
              overlaysVisible: true,
              preview: const SizedBox.shrink(),
              bottomPanel: const Text('bottom-panel-visible'),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('bottom-panel-visible'), findsOneWidget);
      },
    );

    testWidgets('onVisibilityChanged fires when user taps to toggle', (
      tester,
    ) async {
      final log = <bool>[];

      await tester.pumpWidget(
        _wrap(
          ImmersiveComposerScaffold(
            title: 'Title',
            disableBlur: true,
            onVisibilityChanged: log.add,
            preview: const ColoredBox(
              color: Colors.grey,
              child: SizedBox.expand(),
            ),
            bottomPanel: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();

      // Tap to hide.
      await tester.tap(find.byType(ColoredBox).first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 16));

      expect(log, isNotEmpty);
      expect(log.first, isFalse);
    });

    testWidgets('disableBlur=true renders without BackdropFilter', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ImmersiveComposerScaffold(
            title: 'No Blur',
            disableBlur: true,
            overlaysVisible: true,
            preview: const SizedBox.shrink(),
            bottomPanel: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets(
      'backgroundIntent=media defaults to disabled blur (no BackdropFilter)',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            ImmersiveComposerScaffold(
              title: 'Media',
              backgroundIntent: BackgroundIntent.media,
              overlaysVisible: true,
              preview: const SizedBox.shrink(),
              bottomPanel: const SizedBox.shrink(),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(BackdropFilter), findsNothing);
      },
    );

    testWidgets(
      'backgroundIntent=ui (default) keeps BackdropFilter on the overlays',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            ImmersiveComposerScaffold(
              title: 'UI',
              overlaysVisible: true,
              preview: const SizedBox.shrink(),
              bottomPanel: const SizedBox.shrink(),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(BackdropFilter), findsWidgets);
      },
    );

    testWidgets('explicit disableBlur=false overrides backgroundIntent=media', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ImmersiveComposerScaffold(
            title: 'Override',
            backgroundIntent: BackgroundIntent.media,
            disableBlur: false,
            overlaysVisible: true,
            preview: const SizedBox.shrink(),
            bottomPanel: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(BackdropFilter), findsWidgets);
    });

    testWidgets('floatingActionButton is rendered when overlays are visible', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ImmersiveComposerScaffold(
            title: 'FAB Test',
            disableBlur: true,
            overlaysVisible: true,
            floatingActionButton: const Icon(Icons.play_arrow, key: Key('fab')),
            preview: const SizedBox.shrink(),
            bottomPanel: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('fab')), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Widget _wrap(
  Widget child, {
  Brightness brightness = Brightness.light,
  TextDirection textDirection = TextDirection.ltr,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.green,
    brightness: brightness,
  );
  final designTokens = brightness == Brightness.dark
      ? MeMuslimDesignTokens.dark()
      : MeMuslimDesignTokens.light();
  final componentTokens = brightness == Brightness.dark
      ? MeMuslimComponentTokens.dark(colorScheme: colorScheme)
      : MeMuslimComponentTokens.light(colorScheme: colorScheme);

  return MaterialApp(
    theme: ThemeData(
      colorScheme: colorScheme,
      extensions: [designTokens, componentTokens],
    ),
    home: Directionality(
      textDirection: textDirection,
      child: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  group('TilawaIllustratedState', () {
    testWidgets('renders custom visual, title, and subtitle', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaIllustratedState(
            visual: SizedBox(
              key: ValueKey('state_visual'),
              width: 64,
              height: 64,
            ),
            title: 'No downloads yet',
            subtitle: 'Save recitations for offline listening.',
          ),
        ),
      );

      expect(find.byKey(const ValueKey('state_visual')), findsOneWidget);
      expect(find.text('No downloads yet'), findsOneWidget);
      expect(
        find.text('Save recitations for offline listening.'),
        findsOneWidget,
      );
    });

    testWidgets('renders icon fallback when visual is not provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaIllustratedState(
            icon: Icons.download_done_rounded,
            title: 'Ready offline',
          ),
        ),
      );

      expect(find.byType(TilawaStateVisual), findsOneWidget);
      expect(find.byIcon(Icons.download_done_rounded), findsOneWidget);
      expect(find.text('Ready offline'), findsOneWidget);
    });

    testWidgets('renders gracefully when no visual or icon is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaIllustratedState(
            title: 'Fallback state',
          ),
        ),
      );

      expect(find.byType(TilawaStateVisual), findsNothing);
      expect(find.text('Fallback state'), findsOneWidget);
    });

    testWidgets('renders and triggers primary and secondary actions', (
      tester,
    ) async {
      var primaryTapCount = 0;
      var secondaryTapCount = 0;

      await tester.pumpWidget(
        _wrap(
          TilawaIllustratedState(
            icon: Icons.search_off_rounded,
            title: 'No results',
            primaryAction: TextButton(
              onPressed: () => primaryTapCount += 1,
              child: const Text('Clear search'),
            ),
            secondaryAction: TextButton(
              onPressed: () => secondaryTapCount += 1,
              child: const Text('Browse all'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Clear search'));
      await tester.tap(find.text('Browse all'));
      await tester.pump();

      expect(primaryTapCount, 1);
      expect(secondaryTapCount, 1);
    });

    testWidgets('applies semantic label to the state container', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaIllustratedState(
            icon: Icons.explore_outlined,
            title: 'Calibrate Qibla',
            semanticLabel: 'Qibla calibration required',
          ),
        ),
      );

      final stateSemantics = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Qibla calibration required',
      );
      expect(stateSemantics, findsOneWidget);
    });

    testWidgets('composes default semantic label from title and subtitle', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaIllustratedState(
            icon: Icons.inbox_outlined,
            title: 'No bookmarks',
            subtitle: 'Save ayahs to find them later.',
          ),
        ),
      );

      final stateSemantics = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                'No bookmarks. Save ayahs to find them later.',
      );
      expect(stateSemantics, findsOneWidget);
    });

    testWidgets('renders primary action before secondary in reading order', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaIllustratedState(
            icon: Icons.search_off_rounded,
            title: 'No results',
            primaryAction: Text('Primary'),
            secondaryAction: Text('Secondary'),
          ),
        ),
      );

      final labels = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(Wrap),
              matching: find.byType(Text),
            ),
          )
          .map((text) => text.data)
          .toList();
      expect(labels, ['Primary', 'Secondary']);
    });

    testWidgets('uses provided maximum width', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaIllustratedState(
            icon: Icons.favorite_border_rounded,
            title: 'No favorites',
            maxWidth: 280,
          ),
        ),
      );

      final constrainedBox = tester.widget<ConstrainedBox>(
        find
            .ancestor(
              of: find.text('No favorites'),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );

      expect(constrainedBox.constraints.maxWidth, 280);
    });

    testWidgets('supports dark theme with the default visual fallback', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaIllustratedState(
            icon: Icons.cloud_off_rounded,
            title: 'Try again',
            subtitle: 'Downloads are not available right now.',
          ),
          brightness: Brightness.dark,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(TilawaStateVisual), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('does not overflow in a tight viewport', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 345,
            height: 238,
            child: TilawaIllustratedState(
              icon: Icons.search_off_rounded,
              title: 'لا يوجد قراء يطابقون البحث',
              subtitle: 'جرب كلمة بحث مختلفة',
              primaryAction: TilawaButton(
                text: 'مسح الكل',
                leadingIcon: const Icon(Icons.clear_all_rounded),
                onPressed: () {},
              ),
            ),
          ),
          textDirection: TextDirection.rtl,
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('supports RTL and larger text on narrow phones', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          TilawaIllustratedState(
            icon: Icons.my_location_rounded,
            title: 'الموقع مطلوب',
            subtitle: 'تتطلب مواقيت الصلاة موقعك للحساب بدقة',
            primaryAction: TilawaButton(
              text: 'تفعيل الموقع',
              leadingIcon: const Icon(Icons.my_location_rounded),
              onPressed: () {},
            ),
          ),
          textDirection: TextDirection.rtl,
          textScaler: const TextScaler.linear(1.6),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('الموقع مطلوب'), findsOneWidget);
      expect(find.text('تفعيل الموقع'), findsOneWidget);
    });
  });
}

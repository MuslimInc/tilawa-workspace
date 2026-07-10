import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Widget _wrap(
  Widget child, {
  TextDirection? textDirection,
  Locale? locale,
}) {
  return MaterialApp(
    theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
    locale: locale,
    home: Scaffold(
      body: textDirection == null
          ? child
          : Directionality(textDirection: textDirection, child: child),
    ),
  );
}

void main() {
  group('TilawaMetricTile', () {
    testWidgets('renders value, label, icon, and helper text', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 200,
            child: TilawaMetricTile(
              data: TilawaMetricData(
                value: '12',
                label: 'Pending requests',
                icon: Icons.inbox_outlined,
                tint: TilawaSemanticTint.ink,
                helperText: '+3 this week',
              ),
            ),
          ),
        ),
      );

      expect(find.text('12'), findsOneWidget);
      expect(find.text('Pending requests'), findsOneWidget);
      expect(find.text('+3 this week'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('has no tap affordance (no InkWell/GestureDetector)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 200,
            child: TilawaMetricTile(
              data: TilawaMetricData(value: '5', label: 'Upcoming'),
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsNothing);
      expect(find.byType(GestureDetector), findsNothing);
      // No chevron / arrow affordance.
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    });

    testWidgets('announces a read-only semantic label', (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 200,
            child: TilawaMetricTile(
              data: TilawaMetricData(
                value: '8',
                label: 'Bookable slots',
                semanticLabel: 'Eight bookable slots',
              ),
            ),
          ),
        ),
      );

      expect(find.semantics.byLabel('Eight bookable slots'), findsOneWidget);
      semanticsHandle.dispose();
    });

    testWidgets('does not elevate (flat surface, no Material elevation)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 200,
            child: TilawaMetricTile(
              data: TilawaMetricData(value: '1', label: 'A'),
            ),
          ),
        ),
      );

      // Flat: should render a DecoratedBox, not a shadowed Material surface.
      expect(
        find.descendant(
          of: find.byType(TilawaMetricTile),
          matching: find.byType(Material),
        ),
        findsNothing,
      );
      expect(find.byType(DecoratedBox), findsWidgets);
    });

    testWidgets('RTL mirrors layout without errors', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 200,
            child: TilawaMetricTile(
              data: TilawaMetricData(
                value: '2',
                label: 'طلبات معلقة',
                icon: Icons.inbox_outlined,
              ),
            ),
          ),
          textDirection: TextDirection.rtl,
          locale: const Locale('ar'),
        ),
      );

      expect(find.text('2'), findsOneWidget);
      expect(find.text('طلبات معلقة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('TilawaMetricTileStrip', () {
    testWidgets('distributes tiles evenly in a Row of Expanded', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaMetricTileStrip(
            metrics: [
              TilawaMetricData(value: '1', label: 'A'),
              TilawaMetricData(value: '2', label: 'B'),
              TilawaMetricData(value: '3', label: 'C'),
            ],
          ),
        ),
      );

      expect(find.byType(TilawaMetricTile), findsNWidgets(3));
      expect(find.byType(Expanded), findsNWidgets(3));
    });

    testWidgets('loading renders N skeleton tiles', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaMetricTileStrip(
            metrics: [],
            loading: true,
            loadingCount: 3,
          ),
        ),
      );

      expect(find.byType(TilawaMetricTileSkeleton), findsNWidgets(3));
      expect(find.byType(TilawaMetricTile), findsNothing);
    });

    testWidgets('small screen: three narrow tiles still fit (no overflow)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _wrap(
          const TilawaMetricTileStrip(
            metrics: [
              TilawaMetricData(
                value: '12',
                label: 'Pending requests',
                icon: Icons.inbox_outlined,
              ),
              TilawaMetricData(
                value: '5',
                label: 'Upcoming sessions',
                icon: Icons.event_outlined,
              ),
              TilawaMetricData(
                value: '48',
                label: 'Bookable slots',
                icon: Icons.schedule_outlined,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TilawaMetricTile), findsNWidgets(3));
    });
  });
}

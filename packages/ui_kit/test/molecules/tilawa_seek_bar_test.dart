import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/foundation/component_tokens/component_tokens_theme.dart';
import '../../lib/src/foundation/design_tokens.dart';
import '../../lib/src/molecules/tilawa_seek_bar.dart';

Widget _wrap(Widget child, {TextDirection textDirection = TextDirection.ltr}) {
  return MaterialApp(
    theme: ThemeData(
      extensions: [TilawaDesignTokens.light(), TilawaComponentTokens.light()],
    ),
    home: Directionality(
      textDirection: textDirection,
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('TilawaSeekBar', () {
    testWidgets('renders with given duration, position, and bufferedPosition', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaSeekBar(
            duration: Duration(minutes: 5),
            position: Duration(minutes: 2),
            bufferedPosition: Duration(minutes: 3),
          ),
        ),
      );

      final sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();
      expect(sliders.length, 2);
      expect(
        sliders[0].value,
        const Duration(minutes: 3).inMilliseconds.toDouble(),
      );
      expect(
        sliders[1].value,
        const Duration(minutes: 2).inMilliseconds.toDouble(),
      );
      expect(
        sliders[0].max,
        const Duration(minutes: 5).inMilliseconds.toDouble(),
      );
      expect(
        sliders[1].max,
        const Duration(minutes: 5).inMilliseconds.toDouble(),
      );
    });

    testWidgets('dragging calls onChanged with reasonable Duration values', (
      tester,
    ) async {
      final changedValues = <Duration>[];

      await tester.pumpWidget(
        _wrap(
          TilawaSeekBar(
            duration: const Duration(minutes: 5),
            position: const Duration(minutes: 1),
            bufferedPosition: const Duration(minutes: 2),
            onChanged: changedValues.add,
          ),
        ),
      );

      await tester.drag(find.byType(Slider).last, const Offset(120, 0));
      await tester.pumpAndSettle();

      expect(changedValues, isNotEmpty);
      expect(
        changedValues.every(
          (value) =>
              value >= Duration.zero && value <= const Duration(minutes: 5),
        ),
        isTrue,
      );
    });

    testWidgets('drag end calls onChangeEnd', (tester) async {
      Duration? endedValue;

      await tester.pumpWidget(
        _wrap(
          TilawaSeekBar(
            duration: const Duration(minutes: 5),
            position: const Duration(minutes: 1),
            bufferedPosition: const Duration(minutes: 2),
            onChangeEnd: (value) => endedValue = value,
          ),
        ),
      );

      await tester.drag(find.byType(Slider).last, const Offset(100, 0));
      await tester.pumpAndSettle();

      expect(endedValue, isNotNull);
      expect(endedValue! >= Duration.zero, isTrue);
      expect(endedValue! <= const Duration(minutes: 5), isTrue);
    });

    testWidgets(
      'zero duration disables interaction and avoids invalid values',
      (tester) async {
        final changedValues = <Duration>[];

        await tester.pumpWidget(
          _wrap(
            TilawaSeekBar(
              duration: Duration.zero,
              position: Duration.zero,
              bufferedPosition: Duration.zero,
              onChanged: changedValues.add,
            ),
          ),
        );

        await tester.drag(find.byType(Slider).last, const Offset(100, 0));
        await tester.pumpAndSettle();

        expect(changedValues, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('does not throw when position > duration', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaSeekBar(
            duration: Duration(seconds: 30),
            position: Duration(seconds: 90),
            bufferedPosition: Duration(seconds: 10),
          ),
        ),
      );

      final sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();
      expect(sliders.length, 2);
      expect(
        sliders[1].value,
        const Duration(seconds: 30).inMilliseconds.toDouble(),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not throw when bufferedPosition > duration', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaSeekBar(
            duration: Duration(seconds: 30),
            position: Duration(seconds: 10),
            bufferedPosition: Duration(seconds: 90),
          ),
        ),
      );

      final sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();
      expect(sliders.length, 2);
      expect(
        sliders[0].value,
        const Duration(seconds: 30).inMilliseconds.toDouble(),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('rtl rendering smoke test', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaSeekBar(
            duration: Duration(minutes: 1),
            position: Duration(seconds: 20),
            bufferedPosition: Duration(seconds: 40),
          ),
          textDirection: TextDirection.rtl,
        ),
      );

      expect(find.byType(Slider), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('touch strip height is at least 44dp with gesture handling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaSeekBar(
            duration: Duration(minutes: 5),
            position: Duration(minutes: 1),
            bufferedPosition: Duration(minutes: 2),
          ),
        ),
      );

      final seekFinder = find.byType(TilawaSeekBar);
      final stackFinder = find.descendant(
        of: seekFinder,
        matching: find.byType(Stack),
      );
      expect(tester.getSize(stackFinder).height, greaterThanOrEqualTo(44));

      await tester.drag(find.byType(Slider).last, const Offset(24, 0));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}

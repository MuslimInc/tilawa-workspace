import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image/presentation/widgets/molecules/page_slider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PageSlider invokes onChanged and onChangeEnd after drag', (
    tester,
  ) async {
    final changes = <double>[];
    double? endValue;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 900)),
          child: Scaffold(
            body: PageSlider(
              currentPage: 50,
              committedPage: 50,
              totalPages: 604,
              onChanged: changes.add,
              onChangeEnd: (v) => endValue = v,
              screenWidth: 400,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final slider = find.byType(Slider);
    await tester.drag(slider, const Offset(120, 0));
    await tester.pumpAndSettle();

    expect(changes, isNotEmpty);
    expect(endValue, isNotNull);
    expect(endValue, greaterThan(50));
  });

  /// Regression: thumb must follow the finger while [currentPage] is stale
  /// (preview updates are throttled in the reader).
  testWidgets(
    'PageSlider keeps local thumb position while dragging even if '
    'currentPage stays fixed',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 900)),
            child: Scaffold(
              body: PageSlider(
                currentPage: 50,
                committedPage: 50,
                totalPages: 604,
                onChanged: (_) {},
                onChangeEnd: (_) {},
                screenWidth: 400,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final slider = find.byType(Slider);
      final center = tester.getCenter(slider);
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(150, 0));
      await tester.pump();

      final valueWhileDragging = tester.widget<Slider>(slider).value;
      expect(
        valueWhileDragging,
        greaterThan(50),
        reason: 'thumb should advance before parent bumps currentPage',
      );

      await gesture.up();
      await tester.pump();

      final valueAfterRelease = tester.widget<Slider>(slider).value;
      expect(
        valueAfterRelease,
        greaterThan(50),
        reason: 'thumb must not snap back to stale currentPage before commit',
      );
    },
  );

  testWidgets(
    'PageSlider holds released value until committedPage catches up',
    (tester) async {
      final key = GlobalKey<_HoldHarnessState>();

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 900)),
            child: _HoldHarness(key: key),
          ),
        ),
      );
      await tester.pump();

      final slider = find.byType(Slider);
      await tester.drag(slider, const Offset(160, 0));
      await tester.pump();

      final released = tester.widget<Slider>(slider).value.round();
      expect(released, greaterThan(10));
      expect(key.currentState!.committed, 10);

      key.currentState!.applyCommitted(released);
      await tester.pump();

      expect(tester.widget<Slider>(slider).value.round(), released);
    },
  );

  testWidgets('PageSlider clamps value to 1..totalPages', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 900)),
          child: Scaffold(
            body: PageSlider(
              currentPage: 2,
              committedPage: 2,
              totalPages: 20,
              onChanged: (_) {},
              onChangeEnd: (_) {},
              screenWidth: 400,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final slider = find.byType(Slider);
    expect(tester.widget<Slider>(slider).value, 2);

    await tester.drag(slider, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(tester.widget<Slider>(slider).value, greaterThanOrEqualTo(1));
    expect(tester.widget<Slider>(slider).value, lessThanOrEqualTo(20));
  });

  testWidgets('PageSlider drag works under Directionality.rtl (reader)', (
    tester,
  ) async {
    final changes = <double>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: const MediaQueryData(size: Size(400, 900)),
            child: Scaffold(
              body: PageSlider(
                currentPage: 1,
                committedPage: 1,
                totalPages: 604,
                onChanged: changes.add,
                onChangeEnd: (_) {},
                screenWidth: 400,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final rect = tester.getRect(find.byType(Slider));
    final gesture = await tester.startGesture(
      Offset(rect.right - 12, rect.center.dy),
    );
    await gesture.moveBy(const Offset(-180, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(changes, isNotEmpty);
    expect(changes.last, greaterThan(1));
  });

  testWidgets('PageSlider follows parent currentPage when not dragging', (
    tester,
  ) async {
    final key = GlobalKey<_SliderHostState>();

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 900)),
          child: _SliderHost(key: key),
        ),
      ),
    );
    await tester.pump();

    expect(tester.widget<Slider>(find.byType(Slider)).value, 10);
    key.currentState!.setBothPages(88);
    await tester.pump();
    expect(tester.widget<Slider>(find.byType(Slider)).value, 88);
  });
}

class _HoldHarness extends StatefulWidget {
  const _HoldHarness({super.key});

  @override
  State<_HoldHarness> createState() => _HoldHarnessState();
}

class _HoldHarnessState extends State<_HoldHarness> {
  int committed = 10;
  int display = 10;

  void applyCommitted(int page) => setState(() {
    committed = page;
    display = page;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageSlider(
        currentPage: display,
        committedPage: committed,
        totalPages: 100,
        onChanged: (_) {},
        onChangeEnd: (_) {},
        screenWidth: 400,
      ),
    );
  }
}

class _SliderHost extends StatefulWidget {
  const _SliderHost({super.key});

  @override
  State<_SliderHost> createState() => _SliderHostState();
}

class _SliderHostState extends State<_SliderHost> {
  int _page = 10;

  void setBothPages(int page) => setState(() => _page = page);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageSlider(
        currentPage: _page,
        committedPage: _page,
        totalPages: 100,
        onChanged: (_) {},
        onChangeEnd: (v) => setState(() => _page = v.round()),
        screenWidth: 400,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/shell/application/shell_tab_primary_scroll.dart';

void main() {
  group('ShellTabPrimaryScroll', () {
    testWidgets(
      'keeps ambient PrimaryScrollController single-client with offstage tabs',
      (tester) async {
        final ScrollController ambient = ScrollController();

        await tester.pumpWidget(
          MaterialApp(
            home: PrimaryScrollController(
              controller: ambient,
              child: const _TwoTabNestedShell(activeIndex: 0),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(ambient.positions.length, 1);
        // Safe: exactly one client (the active NestedScrollView outer).
        expect(ambient.offset, 0);

        await tester.pumpWidget(
          MaterialApp(
            home: PrimaryScrollController(
              controller: ambient,
              child: const _TwoTabNestedShell(activeIndex: 1),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(ambient.positions.length, 1);
        expect(ambient.offset, 0);

        ambient.dispose();
      },
    );

    testWidgets(
      'without isolation, offstage NestedScrollViews pollute PrimaryScrollController',
      (tester) async {
        final ScrollController ambient = ScrollController();

        await tester.pumpWidget(
          MaterialApp(
            home: PrimaryScrollController(
              controller: ambient,
              child: const _TwoTabNestedShell(
                activeIndex: 0,
                isolateInactive: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(ambient.positions.length, greaterThan(1));
        // Debug: AssertionError on positions.length. Release: StateError
        // "Too many elements" from positions.single (Sentry FLUTTER-FQ).
        expect(() => ambient.offset, throwsA(anything));

        ambient.dispose();
      },
    );

    testWidgets('tab subtree stays mounted across activation changes', (
      tester,
    ) async {
      final ScrollController ambient = ScrollController();
      _TabProbe.reset();

      Widget shell({required bool isActive}) {
        return MaterialApp(
          home: PrimaryScrollController(
            controller: ambient,
            child: Offstage(
              offstage: !isActive,
              child: ShellTabPrimaryScroll.wrap(
                isActive: isActive,
                child: const _TabProbe(),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(shell(isActive: true));
      expect(_TabProbe.initCount, 1);

      await tester.pumpWidget(shell(isActive: false));
      await tester.pumpWidget(shell(isActive: true));

      expect(
        _TabProbe.disposeCount,
        0,
        reason: 'leaving a tab must not tear down its subtree',
      );
      expect(
        _TabProbe.initCount,
        1,
        reason: 'returning to a tab must not rebuild it from scratch',
      );

      ambient.dispose();
    });
  });
}

class _TwoTabNestedShell extends StatelessWidget {
  const _TwoTabNestedShell({
    required this.activeIndex,
    this.isolateInactive = true,
  });

  final int activeIndex;
  final bool isolateInactive;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final int index in const <int>[0, 1])
          Offstage(
            offstage: index != activeIndex,
            child: TickerMode(
              enabled: index == activeIndex,
              child: isolateInactive
                  ? ShellTabPrimaryScroll.wrap(
                      isActive: index == activeIndex,
                      child: _TinyNestedScroll(key: ValueKey<int>(index)),
                    )
                  : _TinyNestedScroll(key: ValueKey<int>(index)),
            ),
          ),
      ],
    );
  }
}

class _TinyNestedScroll extends StatelessWidget {
  const _TinyNestedScroll({super.key});

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool _) {
        return const [
          SliverToBoxAdapter(
            child: SizedBox(height: 80, child: Text('header')),
          ),
        ];
      },
      body: ListView.builder(
        itemCount: 20,
        itemBuilder: (_, int index) => SizedBox(
          height: 48,
          child: Text('row $index'),
        ),
      ),
    );
  }
}

class _TabProbe extends StatefulWidget {
  const _TabProbe();

  static int initCount = 0;
  static int disposeCount = 0;

  static void reset() {
    initCount = 0;
    disposeCount = 0;
  }

  @override
  State<_TabProbe> createState() => _TabProbeState();
}

class _TabProbeState extends State<_TabProbe> {
  @override
  void initState() {
    super.initState();
    _TabProbe.initCount++;
  }

  @override
  void dispose() {
    _TabProbe.disposeCount++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

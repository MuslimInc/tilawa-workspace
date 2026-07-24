import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/shell/application/shell_tab_reselect.dart';

void main() {
  group('ShellTabReselect', () {
    testWidgets('scrolls to top when list is scrolled down', (tester) async {
      final controller = ScrollController();
      var refreshed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              controller: controller,
              itemCount: 40,
              itemBuilder: (_, index) =>
                  SizedBox(height: 48, child: Text('$index')),
            ),
          ),
        ),
      );
      await tester.pump();

      controller.jumpTo(240);
      await tester.pump();

      final future = ShellTabReselect.scrollToTopOrRefresh(
        scrollController: controller,
        refresh: () async {
          refreshed = true;
        },
      );
      await tester.pumpAndSettle();
      await future;

      expect(controller.offset, 0);
      expect(refreshed, isFalse);

      controller.dispose();
    });

    testWidgets('refreshes when already at top', (tester) async {
      final controller = ScrollController();
      var refreshed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              controller: controller,
              children: const [SizedBox(height: 400, child: Text('top'))],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await ShellTabReselect.scrollToTopOrRefresh(
        scrollController: controller,
        refresh: () async {
          refreshed = true;
        },
      );

      expect(refreshed, isTrue);
      controller.dispose();
    });

    testWidgets(
      'isScrolledDown tolerates a controller with multiple clients',
      (tester) async {
        final controller = ScrollController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: 40,
                      itemBuilder: (_, index) =>
                          SizedBox(height: 48, child: Text('a$index')),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: 40,
                      itemBuilder: (_, index) =>
                          SizedBox(height: 48, child: Text('b$index')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        expect(controller.positions.length, greaterThan(1));
        // .offset / .position use positions.single and throw when >1 client
        // (AssertionError in debug, StateError in release).
        expect(ShellTabReselect.isScrolledDown(controller), isFalse);

        for (final position in controller.positions) {
          position.jumpTo(240);
        }
        await tester.pump();

        expect(ShellTabReselect.isScrolledDown(controller), isTrue);

        var refreshed = false;
        final future = ShellTabReselect.scrollToTopOrRefresh(
          scrollController: controller,
          refresh: () async {
            refreshed = true;
          },
        );
        await tester.pumpAndSettle();
        await future;

        expect(refreshed, isFalse);
        for (final position in controller.positions) {
          expect(position.pixels, 0);
        }

        controller.dispose();
      },
    );

    testWidgets(
      'scrollNestedToTop expands collapsed NestedScrollView header',
      (tester) async {
        final nestedKey = GlobalKey<NestedScrollViewState>();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NestedScrollView(
                key: nestedKey,
                headerSliverBuilder: (context, _) => [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TestCollapsingHeaderDelegate(),
                  ),
                ],
                body: ListView.builder(
                  itemCount: 40,
                  itemBuilder: (_, index) =>
                      SizedBox(height: 48, child: Text('row$index')),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final nested = nestedKey.currentState!;
        final outer = nested.outerController;
        final inner = nested.innerController;

        outer.jumpTo(outer.position.maxScrollExtent);
        await tester.pump();
        inner.jumpTo(240);
        await tester.pump();

        expect(outer.offset, greaterThan(0));
        expect(inner.offset, greaterThan(0));

        final future = ShellTabReselect.scrollNestedToTop(
          outer: outer,
          inner: inner,
          duration: const Duration(milliseconds: 40),
        );
        await tester.pumpAndSettle();
        await future;

        expect(outer.offset, 0);
        expect(inner.offset, 0);
      },
    );
  });
}

class _TestCollapsingHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 200;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return const ColoredBox(
      color: Color(0xFF2E7D32),
      child: Align(alignment: Alignment.bottomLeft, child: Text('header')),
    );
  }

  @override
  bool shouldRebuild(covariant _TestCollapsingHeaderDelegate oldDelegate) {
    return false;
  }
}


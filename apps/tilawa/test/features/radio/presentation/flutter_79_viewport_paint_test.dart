import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression for FLUTTER-79: viewport paint with null sliver geometry.
void main() {
  testWidgets(
    'radio-like headers as SliverToBoxAdapter paint after rebuild',
    (WidgetTester tester) async {
      FlutterErrorDetails? caught;
      final void Function(FlutterErrorDetails)? old = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        caught ??= details;
        old?.call(details);
      };
      addTearDown(() => FlutterError.onError = old);

      await tester.binding.setSurfaceSize(const Size(480, 735));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var empty = false;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Scaffold(
                body: RefreshIndicator(
                  onRefresh: () async {},
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: <Widget>[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              const Text('Favorites'),
                              SizedBox(
                                height: 128,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  primary: false,
                                  itemCount: 5,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (_, int i) => Container(
                                    width: 100,
                                    color: Colors.teal,
                                    child: Text('$i'),
                                  ),
                                ),
                              ),
                              const Text('All'),
                            ],
                          ),
                        ),
                      ),
                      if (empty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: Text('empty')),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (BuildContext context, int index) =>
                                ListTile(title: Text('s$index')),
                            childCount: 20,
                          ),
                        ),
                    ],
                  ),
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () => setState(() => empty = !empty),
                  child: const Icon(Icons.refresh),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      for (var i = 0; i < 8; i++) {
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pumpAndSettle();
      expect(caught, isNull, reason: caught?.toString());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'NestedScrollView pinned header uses overlap injector',
    (WidgetTester tester) async {
      FlutterErrorDetails? caught;
      final void Function(FlutterErrorDetails)? old = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        caught ??= details;
        old?.call(details);
      };
      addTearDown(() => FlutterError.onError = old);

      await tester.binding.setSurfaceSize(const Size(480, 735));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool inner) {
              return <Widget>[
                SliverOverlapAbsorber(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                    context,
                  ),
                  sliver: SliverPersistentHeader(
                    pinned: true,
                    delegate: _TestHeader(),
                  ),
                ),
              ];
            },
            body: Builder(
              builder: (BuildContext context) {
                return CustomScrollView(
                  slivers: <Widget>[
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) => Material(
                          child: ListTile(title: Text('item $index')),
                        ),
                        childCount: 30,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      final NestedScrollViewState nested = tester.state<NestedScrollViewState>(
        find.byType(NestedScrollView),
      );
      nested.outerController.jumpTo(120);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(caught, isNull, reason: caught?.toString());
      expect(tester.takeException(), isNull);
    },
  );
}

class _TestHeader extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 180;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return const ColoredBox(
      color: Colors.green,
      child: SizedBox.expand(child: Text('hero')),
    );
  }

  @override
  bool shouldRebuild(covariant _TestHeader oldDelegate) => false;
}

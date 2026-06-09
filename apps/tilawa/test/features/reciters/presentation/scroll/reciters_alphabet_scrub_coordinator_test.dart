import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/reciters/presentation/scroll/reciters_alphabet_scrub_coordinator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('scroll position helpers', () {
    testWidgets('largestScrollExtentPosition picks catalog position', (
      tester,
    ) async {
      final ScrollController header = ScrollController();
      final ScrollController catalog = ScrollController();
      addTearDown(header.dispose);
      addTearDown(catalog.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              SizedBox(
                height: 120,
                child: ListView(controller: header, children: const [
                  SizedBox(height: 40),
                ]),
              ),
              Expanded(
                child: ListView.builder(
                  controller: catalog,
                  itemCount: 40,
                  itemBuilder: (_, _) => const SizedBox(height: 48),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ScrollPosition? largest = largestScrollExtentPosition(catalog);
      expect(largest, isNotNull);
      expect(largest!.maxScrollExtent, greaterThan(500));
      expect(largestScrollExtentPosition(header)!.maxScrollExtent, lessThan(500));
    });

    testWidgets('headerScrollPosition prefers highest header pixels', (
      tester,
    ) async {
      final ScrollController header = ScrollController();
      addTearDown(header.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 200,
            child: ListView(
              controller: header,
              children: List<Widget>.generate(
                20,
                (_) => const SizedBox(height: 48),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(header.position.maxScrollExtent, greaterThan(0));
      header.jumpTo(48);
      await tester.pump();

      expect(headerScrollPosition(header)?.pixels, 48);
    });

    testWidgets('fallbackHeaderScrollPosition skips catalog and zero extents', (
      tester,
    ) async {
      final ScrollController header = ScrollController();
      final ScrollController catalog = ScrollController();
      addTearDown(header.dispose);
      addTearDown(catalog.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 500,
            child: Column(
              children: [
                SizedBox(
                  height: 120,
                  child: ListView(
                    controller: header,
                    children: List<Widget>.generate(
                      8,
                      (_) => const SizedBox(height: 48),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: catalog,
                    itemCount: 40,
                    itemBuilder: (_, _) => const SizedBox(height: 48),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ScrollPosition? catalogPosition = largestScrollExtentPosition(
        catalog,
      );
      expect(catalogPosition, isNotNull);
      expect(catalogPosition!.maxScrollExtent, greaterThan(500));

      final ScrollPosition? fallback = fallbackHeaderScrollPosition(
        <ScrollPosition>[catalogPosition, header.position],
        catalogPosition,
      );

      expect(fallback, same(header.position));
    });

    testWidgets('largestScrollExtentPosition skips positions without dimensions', (
      tester,
    ) async {
      final ScrollController catalog = ScrollController();
      addTearDown(catalog.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 400,
            child: ListView.builder(
              controller: catalog,
              itemCount: 30,
              itemBuilder: (_, _) => const SizedBox(height: 48),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(largestScrollExtentPosition(catalog), isNotNull);
      expect(largestScrollExtentPosition(null), isNull);
    });

    testWidgets('headerScrollPosition breaks ties using smaller maxScrollExtent', (
      tester,
    ) async {
      final ScrollController outer = ScrollController();
      final ScrollController inner = ScrollController();
      addTearDown(outer.dispose);
      addTearDown(inner.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 600,
            child: NestedScrollView(
              controller: outer,
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 200,
                    child: ListView(
                      controller: inner,
                      children: List<Widget>.generate(
                        6,
                        (_) => const SizedBox(height: 48),
                      ),
                    ),
                  ),
                ),
              ],
              body: ListView.builder(
                itemCount: 40,
                itemBuilder: (_, _) => const SizedBox(height: 48),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ScrollPosition? header = headerScrollPosition(outer);
      expect(header, isNotNull);
      expect(header!.maxScrollExtent, lessThanOrEqualTo(500));
    });

    testWidgets('fallbackHeaderScrollPosition prefers smallest header extent', (
      tester,
    ) async {
      final ScrollController headerSmall = ScrollController();
      final ScrollController headerLarge = ScrollController();
      final ScrollController catalog = ScrollController();
      addTearDown(headerSmall.dispose);
      addTearDown(headerLarge.dispose);
      addTearDown(catalog.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 600,
            child: Column(
              children: [
                SizedBox(
                  height: 100,
                  child: ListView(
                    controller: headerSmall,
                    children: List<Widget>.generate(
                      4,
                      (_) => const SizedBox(height: 48),
                    ),
                  ),
                ),
                SizedBox(
                  height: 140,
                  child: ListView(
                    controller: headerLarge,
                    children: List<Widget>.generate(
                      8,
                      (_) => const SizedBox(height: 48),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: catalog,
                    itemCount: 40,
                    itemBuilder: (_, _) => const SizedBox(height: 48),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ScrollPosition catalogPosition = catalog.position;
      final ScrollPosition? fallback = fallbackHeaderScrollPosition(
        <ScrollPosition>[
          catalogPosition,
          headerLarge.position,
          headerSmall.position,
        ],
        catalogPosition,
      );

      expect(fallback, same(headerSmall.position));
    });
  });

  group('RecitersAlphabetScrubCoordinator', () {
    testWidgets('beginScrub captures pinned header and catalog offsets', (
      tester,
    ) async {
      final ScrollController primary = ScrollController();
      final ScrollController inner = ScrollController();
      addTearDown(primary.dispose);
      addTearDown(inner.dispose);

      late RecitersAlphabetScrubCoordinator coordinator;

      await tester.pumpWidget(
        MaterialApp(
          home: PrimaryScrollController(
            controller: primary,
            child: Builder(
              builder: (context) {
                coordinator = RecitersAlphabetScrubCoordinator(
                  innerController: () => inner,
                  primaryController: () => primary,
                );
                return SizedBox(
                  height: 600,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 120,
                        child: ListView(
                          controller: primary,
                          children: List<Widget>.generate(
                            8,
                            (_) => const SizedBox(height: 48),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: inner,
                          itemCount: 30,
                          itemBuilder: (_, _) => const SizedBox(height: 48),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      primary.jumpTo(40);
      inner.jumpTo(120);
      await tester.pump();

      coordinator
        ..alphabetScrubbingActive = true
        ..beginScrub();

      expect(coordinator.scrubPinnedCatalogOffset, 120);
      expect(coordinator.scrubPinnedHeaderOffset, greaterThanOrEqualTo(40));
      expect(coordinator.scrubLockedCatalogPosition, isNotNull);
    });

    testWidgets('beginScrub uses fallback header lock without primary controller', (
      tester,
    ) async {
      final ScrollController inner = ScrollController();
      addTearDown(inner.dispose);

      late RecitersAlphabetScrubCoordinator coordinator;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              coordinator = RecitersAlphabetScrubCoordinator(
                innerController: () => inner,
                primaryController: () => null,
              );
              return SizedBox(
                height: 600,
                child: Column(
                  children: [
                    SizedBox(
                      height: 120,
                      child: ListView(
                        controller: inner,
                        children: List<Widget>.generate(
                          8,
                          (_) => const SizedBox(height: 48),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: inner,
                        itemCount: 40,
                        itemBuilder: (_, _) => const SizedBox(height: 48),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      inner.jumpTo(120);
      await tester.pump();

      coordinator
        ..alphabetScrubbingActive = true
        ..beginScrub();

      expect(coordinator.scrubLockedCatalogPosition, isNotNull);
      expect(coordinator.scrubLockedHeaderPosition, isNotNull);
      expect(coordinator.scrubLockedHeaderOffset, isNotNull);
    });

    testWidgets('enforcePinnedHeaderLock restores drifted header offset', (
      tester,
    ) async {
      final ScrollController primary = ScrollController();
      addTearDown(primary.dispose);

      late RecitersAlphabetScrubCoordinator coordinator;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              coordinator = RecitersAlphabetScrubCoordinator(
                innerController: () => null,
                primaryController: () => primary,
              );
              return SizedBox(
                height: 500,
                child: Column(
                  children: [
                    SizedBox(
                      height: 120,
                      child: ListView(
                        controller: primary,
                        children: List<Widget>.generate(
                          8,
                          (_) => const SizedBox(height: 48),
                        ),
                      ),
                    ),
                    const Expanded(child: ColoredBox(color: Colors.grey)),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      primary.jumpTo(60);
      await tester.pump();

      coordinator
        ..alphabetScrubbingActive = true
        ..scrubPinnedHeaderOffset = 60;

      primary.jumpTo(90);
      await tester.pump();

      coordinator.enforcePinnedHeaderLock();
      await tester.pump();

      expect(primary.position.pixels, closeTo(60, 1.0));
    });

    testWidgets('enforcePinnedCatalogLock restores drifted catalog offset', (
      tester,
    ) async {
      final ScrollController inner = ScrollController();
      addTearDown(inner.dispose);

      late RecitersAlphabetScrubCoordinator coordinator;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              coordinator = RecitersAlphabetScrubCoordinator(
                innerController: () => inner,
                primaryController: () => null,
              );
              return SizedBox(
                height: 400,
                child: ListView.builder(
                  controller: inner,
                  itemCount: 40,
                  itemBuilder: (_, _) => const SizedBox(height: 48),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      inner.jumpTo(80);
      await tester.pump();

      coordinator
        ..alphabetScrubbingActive = true
        ..beginScrub();

      inner.jumpTo(140);
      await tester.pump();

      coordinator.enforcePinnedCatalogLock();
      await tester.pump();

      expect(inner.offset, closeTo(80, 1.0));
    });

    testWidgets('scrollInnerCatalogToTopPreservingHeader keeps header pinned', (
      tester,
    ) async {
      final ScrollController primary = ScrollController();
      final ScrollController inner = ScrollController();
      addTearDown(primary.dispose);
      addTearDown(inner.dispose);

      late RecitersAlphabetScrubCoordinator coordinator;

      await tester.pumpWidget(
        MaterialApp(
          home: PrimaryScrollController(
            controller: primary,
            child: Builder(
              builder: (context) {
                coordinator = RecitersAlphabetScrubCoordinator(
                  innerController: () => inner,
                  primaryController: () => primary,
                );
                return Column(
                  children: [
                    SizedBox(
                      height: 120,
                      child: ListView(
                        controller: primary,
                        children: List<Widget>.generate(
                          6,
                          (_) => const SizedBox(height: 48),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: inner,
                        itemCount: 30,
                        itemBuilder: (_, _) => const SizedBox(height: 48),
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

      primary.jumpTo(48);
      inner.jumpTo(96);
      await tester.pump();

      coordinator
        ..alphabetScrubbingActive = true
        ..beginScrub()
        ..scrollInnerCatalogToTopPreservingHeader();
      await tester.pump();

      expect(inner.offset, closeTo(0, 1.0));
      expect(primary.offset, closeTo(48, 1.0));
    });

    testWidgets('applyTrackedOuterScrollHeaderLock uses tracked collapse', (
      tester,
    ) async {
      final ScrollController primary = ScrollController();
      addTearDown(primary.dispose);

      final RecitersAlphabetScrubCoordinator coordinator =
          RecitersAlphabetScrubCoordinator(
        innerController: () => null,
        primaryController: () => primary,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 300,
            child: ListView(
              controller: primary,
              children: List<Widget>.generate(
                10,
                (_) => const SizedBox(height: 48),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      coordinator
        ..trackedOuterScrollPosition = primary.position
        ..trackedOuterScrollPixels = 72
        ..scrubLockedHeaderOffset = 0
        ..applyTrackedOuterScrollHeaderLock();

      expect(coordinator.scrubLockedHeaderOffset, 72);
    });

    testWidgets('handleNestedScrollNotification detects drift during scrub', (
      tester,
    ) async {
      final ScrollController inner = ScrollController();
      addTearDown(inner.dispose);

      late RecitersAlphabetScrubCoordinator coordinator;
      late ScrollableState scrollableState;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              coordinator = RecitersAlphabetScrubCoordinator(
                innerController: () => inner,
                primaryController: () => null,
              );
              return SizedBox(
                height: 400,
                child: ListView.builder(
                  controller: inner,
                  itemCount: 30,
                  itemBuilder: (_, _) => const SizedBox(height: 48),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      scrollableState = tester.state<ScrollableState>(find.byType(Scrollable));

      coordinator
        ..alphabetScrubbingActive = true
        ..beginScrub();

      inner.jumpTo(40);
      await tester.pump();

      final ScrollMetrics metrics = scrollableState.position;
      final bool needsEnforcement = coordinator.handleNestedScrollNotification(
        ScrollUpdateNotification(
          metrics: metrics,
          context: scrollableState.context,
        ),
      );

      expect(needsEnforcement, isTrue);
    });

    testWidgets('clampNestedScrollOverscroll clears negative offsets', (
      tester,
    ) async {
      final ScrollController inner = ScrollController();
      addTearDown(inner.dispose);

      final RecitersAlphabetScrubCoordinator coordinator =
          RecitersAlphabetScrubCoordinator(
        innerController: () => inner,
        primaryController: () => null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 200,
            child: ListView(
              controller: inner,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              children: const [SizedBox(height: 40)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      inner.position.jumpTo(-12);
      coordinator.clampNestedScrollOverscroll();
      await tester.pump();

      expect(inner.offset, 0);
    });
  });
}

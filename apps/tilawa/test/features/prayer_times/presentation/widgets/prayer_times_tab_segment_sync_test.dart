import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/prayer_times/presentation/widgets/prayer_times_app_bar.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

TabController? prayerTimesTabHarnessController;

void main() {

  group('segmentIndexForTabPage', () {
    test('keeps today selected below the halfway point', () {
      expect(segmentIndexForTabPage(0, 2), 0);
      expect(segmentIndexForTabPage(0.49, 2), 0);
    });

    test('switches to monthly at or past the halfway point', () {
      expect(segmentIndexForTabPage(0.5, 2), 1);
      expect(segmentIndexForTabPage(0.51, 2), 1);
      expect(segmentIndexForTabPage(1, 2), 1);
    });

    test('clamps to valid tab range', () {
      expect(segmentIndexForTabPage(-0.2, 2), 0);
      expect(segmentIndexForTabPage(1.8, 2), 1);
    });
  });

  group('PrayerTimesAppBar segment sync', () {
    testWidgets('highlights monthly before tab animation settles', (
      tester,
    ) async {
      await tester.pumpWidget(const _PrayerTimesTabHarness());
      await tester.pumpAndSettle();

      expectSegmentSelected(tester, label: 'Today', selected: true);
      expectSegmentSelected(tester, label: 'Monthly', selected: false);

      final TabController controller = prayerTimesTabHarnessController!;
      controller.animateTo(
        1,
        duration: const Duration(milliseconds: 800),
      );
      await pumpUntilSegmentIndex(tester, controller, expectedIndex: 1);
      await tester.pump();

      expect(controller.indexIsChanging, isTrue);
      expectSegmentSelected(tester, label: 'Monthly', selected: true);
      expectSegmentSelected(tester, label: 'Today', selected: false);
    });

    testWidgets('tapping monthly selects it and shows the monthly page', (
      tester,
    ) async {
      await tester.pumpWidget(const _PrayerTimesTabHarness());
      await tester.pumpAndSettle();

      await tester.tap(findPrayerTimesSegment('Monthly'));
      await tester.pumpAndSettle();

      expectSegmentSelected(tester, label: 'Monthly', selected: true);
      expect(find.text('Monthly page'), findsOneWidget);
      expect(find.text('Today page'), findsNothing);
    });

    testWidgets('highlights today before reverse tab animation settles', (
      tester,
    ) async {
      await tester.pumpWidget(const _PrayerTimesTabHarness());
      await tester.pumpAndSettle();

      final TabController controller = prayerTimesTabHarnessController!;
      controller.animateTo(1);
      await tester.pumpAndSettle();

      controller.animateTo(
        0,
        duration: const Duration(milliseconds: 800),
      );
      await pumpUntilSegmentIndex(tester, controller, expectedIndex: 0);
      await tester.pump();

      expect(controller.indexIsChanging, isTrue);
      expectSegmentSelected(tester, label: 'Today', selected: true);
      expectSegmentSelected(tester, label: 'Monthly', selected: false);
    });

    test(
      'index-only mapping lags behind animation mid-transition (regression guard)',
      () {
        const int length = 2;

        expect(segmentIndexForTabPage(0.49, length), 0);
        expect(segmentIndexForTabPage(0.51, length), 1);

        const int indexOnlyAtMidSwipe = 0;
        expect(
          indexOnlyAtMidSwipe,
          isNot(segmentIndexForTabPage(0.51, length)),
          reason:
              'Using TabController.index alone would keep Today selected at '
              '51% swipe progress while animation-based mapping switches.',
        );
      },
    );
  });
}

Future<void> pumpUntilSegmentIndex(
  WidgetTester tester,
  TabController controller, {
  required int expectedIndex,
}) async {
  final Stopwatch stopwatch = Stopwatch()..start();
  while (segmentIndexForTabPage(
        controller.animation?.value ?? controller.index.toDouble(),
        controller.length,
      ) !=
      expectedIndex) {
    expect(
      stopwatch.elapsed,
      lessThan(const Duration(seconds: 2)),
      reason: 'Tab animation did not reach $expectedIndex in time.',
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Finder findPrayerTimesSegment(String label) {
  return find.descendant(
    of: find.byType(TilawaSegmentedControl<String>),
    matching: find.text(label),
  );
}

void expectSegmentSelected(
  WidgetTester tester, {
  required String label,
  required bool selected,
}) {
  final Finder segment = findPrayerTimesSegment(label);
  expect(segment, findsOneWidget);

  final semantics = tester.getSemantics(
    find.ancestor(of: segment, matching: find.byType(InkWell)),
  );
  if (selected) {
    expect(semantics.flagsCollection.isSelected, Tristate.isTrue);
  } else {
    expect(semantics.flagsCollection.isSelected, isNot(Tristate.isTrue));
  }
}

/// Minimal NestedScrollView + [PrayerTimesAppBar] + [TabBarView] harness.
class _PrayerTimesTabHarness extends StatefulWidget {
  const _PrayerTimesTabHarness();

  @override
  State<_PrayerTimesTabHarness> createState() => _PrayerTimesTabHarnessState();
}

class _PrayerTimesTabHarnessState extends State<_PrayerTimesTabHarness>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    prayerTimesTabHarnessController = _tabController;
  }

  @override
  void dispose() {
    if (identical(prayerTimesTabHarnessController, _tabController)) {
      prayerTimesTabHarnessController = null;
    }
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.getLightTheme(
        primaryColor: PrimaryColorPreset.defaultPreset.value,
      ),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
                sliver: PrayerTimesAppBar(
                  tabController: _tabController,
                  onSegmentChanged: (String value) {
                    _tabController.animateTo(value == 'today' ? 0 : 1);
                  },
                  onSettingsTap: () {},
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            physics: const BouncingScrollPhysics(
              parent: PageScrollPhysics(),
            ),
            children: [
              _tabPage(label: 'Today page'),
              _tabPage(label: 'Monthly page'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabPage({required String label}) {
    return Builder(
      builder: (BuildContext context) {
        return CustomScrollView(
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(label)),
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image/core/design_tokens/durations.dart';
import 'package:quran_image/data/repositories/in_memory_navigation_visibility_repository.dart';
import 'package:quran_image/data/repositories/in_memory_page_repository.dart';
import 'package:quran_image/domain/domain.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_event.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_state.dart';
import 'package:quran_image/presentation/widgets/atoms/navigation_icon_button.dart';
import 'package:quran_image/presentation/widgets/atoms/page_indicator_text.dart';
import 'package:quran_image/presentation/widgets/atoms/pill_page_indicator.dart';
import 'package:quran_image/presentation/widgets/molecules/page_slider.dart';
import 'package:quran_image/presentation/widgets/organisms/navigation_slider_overlay.dart';
import 'package:quran_image/presentation/widgets/organisms/premium_navigation_overlay.dart';

void main() {
  group('PageState', () {
    test('supports initial state, derived values, and preview clearing', () {
      final initial = PageState.initial();

      expect(initial.currentPage, 1);
      expect(initial.totalPages, PageState.quranPageCount);
      expect(initial.displayPage, 1);
      expect(initial.pageIndex, 0);
      expect(PageState.indexToPage(9), 10);
      expect(initial.isValidPage(1), isTrue);
      expect(initial.isValidPage(PageState.quranPageCount), isTrue);
      expect(initial.isValidPage(0), isFalse);

      final preview = initial.copyWith(
        currentPage: 5,
        previewPage: 7,
        isScrolling: true,
        juzTitle: 'Juz 2',
        hizbTitle: 'Hizb 3',
      );
      expect(preview.currentPage, 5);
      expect(preview.previewPage, 7);
      expect(preview.displayPage, 7);
      expect(preview.isScrolling, isTrue);
      expect(preview.juzTitle, 'Juz 2');
      expect(preview.hizbTitle, 'Hizb 3');

      final cleared = preview.copyWith(clearPreviewPage: true);
      expect(cleared.previewPage, isNull);
      expect(cleared.displayPage, 5);
    });
  });

  group('NavigationVisibility', () {
    test('supports initial state, copyWith, and auto-hide checks', () {
      final initial = NavigationVisibility.initial();
      expect(initial.isVisible, isFalse);
      expect(initial.isInteracting, isFalse);
      expect(initial.lastShownAt, isNull);
      expect(initial.shouldAutoHide(1), isFalse);

      final lastShownAt = DateTime.now().subtract(const Duration(seconds: 5));
      final visible = initial.copyWith(
        isVisible: true,
        isInteracting: false,
        lastShownAt: lastShownAt,
      );
      expect(visible.shouldAutoHide(3), isTrue);

      final interacting = visible.copyWith(isInteracting: true);
      expect(interacting.shouldAutoHide(3), isFalse);

      final cleared = visible.copyWith(clearLastShownAt: true);
      expect(cleared.lastShownAt, isNull);
    });
  });

  group('Navigation events and states', () {
    test('support value equality and copyWith', () {
      const pageState = PageState(
        currentPage: 4,
        totalPages: 604,
        juzTitle: 'Juz 1',
        hizbTitle: 'Hizb 1',
      );
      final visibility = NavigationVisibility.initial().copyWith(
        isVisible: true,
      );

      final loaded = NavigationLoaded(
        pageState: pageState,
        visibility: visibility,
      );
      final copied = loaded.copyWith(
        pageState: pageState.copyWith(previewPage: 6),
      );
      expect(copied.pageState.displayPage, 6);
      expect(loaded, isNot(copied));

      expect(const PageChanged(9), const PageChanged(9));
      expect(const LastVisitedPageSaved(11), const LastVisitedPageSaved(11));
      expect(
        const NavigationError(UnexpectedErrorMessage()),
        const NavigationError(UnexpectedErrorMessage()),
      );
    });
  });

  testWidgets('navigation widgets render and invoke callbacks', (tester) async {
    int previewPage = 0;
    int requestedPage = 0;
    int previousPressed = 0;
    int nextPressed = 0;
    int interactionStarts = 0;
    int interactionEnds = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Scaffold(
            body: NavigationSliderOverlay(
              screenWidth: 400,
              state: const PageState(
                currentPage: 20,
                totalPages: 604,
                juzTitle: 'Juz 2',
                hizbTitle: 'Hizb 4',
              ),
              canGoToPreviousPage: true,
              canGoToNextPage: true,
              onPreviewPageChanged: (value) => previewPage = value,
              onPageNavigationRequested: (value) => requestedPage = value,
              onPreviousPageRequested: () => previousPressed++,
              onNextPageRequested: () => nextPressed++,
              onInteractionStart: () => interactionStarts++,
              onInteractionEnd: () => interactionEnds++,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(PageSlider), findsOneWidget);
    expect(find.byType(PageIndicatorText), findsOneWidget);
    expect(find.text('Page 20'), findsOneWidget);

    final previousIcon = find.byIcon(Icons.arrow_back_ios);
    final nextIcon = find.byIcon(Icons.arrow_forward_ios);
    await tester.tap(previousIcon);
    await tester.pump();
    await tester.tap(nextIcon);
    await tester.pump();

    final slider = find.byType(Slider);
    await tester.drag(slider, const Offset(120, 0));
    await tester.pumpAndSettle();

    await tester.tapAt(
      tester.getTopLeft(find.byType(NavigationSliderOverlay)) +
          const Offset(24, 24),
    );
    await tester.pump();

    expect(previousPressed, 1);
    expect(nextPressed, 1);
    expect(previewPage, greaterThan(0));
    expect(requestedPage, greaterThan(0));
    expect(interactionStarts, greaterThanOrEqualTo(1));
    expect(interactionEnds, greaterThanOrEqualTo(1));
  });

  testWidgets('atom widgets render enabled and disabled states', (
    tester,
  ) async {
    var pressed = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              NavigationIconButton(
                icon: Icons.chevron_left,
                onPressed: () => pressed++,
                screenWidth: 400,
              ),
              const NavigationIconButton(
                icon: Icons.chevron_right,
                onPressed: null,
                screenWidth: 400,
              ),
              const PillPageIndicator(pageNumber: 12, screenWidth: 400),
              const PageIndicatorText(
                pageNumber: 12,
                totalPages: 604,
                screenWidth: 400,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('12'), findsOneWidget);
    expect(find.text('Page 12'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();

    expect(pressed, 1);
  });

  testWidgets('premium overlay reacts to bloc visibility and preview state', (
    tester,
  ) async {
    final bloc = NavigationBloc(
      pageRepository: InMemoryPageRepository(),
      visibilityRepository: InMemoryNavigationVisibilityRepository(),
      saveLastVisitedPageUseCase: SaveLastVisitedPageUseCase(
        _InMemoryLastVisitedPageRepository(),
      ),
      getLastVisitedPageUseCase: GetLastVisitedPageUseCase(
        _InMemoryLastVisitedPageRepository(initialPage: 8),
      ),
    )..add(const NavigationInitialized());

    final previewState = ValueNotifier<PageState?>(null);
    addTearDown(() async {
      previewState.dispose();
      await bloc.close();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: bloc,
          child: Scaffold(
            body: Stack(
              children: [
                PremiumNavigationOverlay(
                  previewStateListenable: previewState,
                  onPreviewPageChanged: (_) {},
                  onPageNavigationRequested: (_) {},
                  onPreviousPageRequested: () {},
                  onNextPageRequested: () {},
                  onInteractionStart: () {},
                  onInteractionEnd: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    bloc.add(const NavigationShown());
    await tester.pump();
    await tester.pump(
      const Duration(milliseconds: AppDurations.sliderShowHide),
    );

    expect(find.byType(NavigationSliderOverlay), findsOneWidget);
    expect(find.text('Page 8'), findsOneWidget);

    previewState.value = const PageState(
      currentPage: 8,
      previewPage: 22,
      totalPages: 604,
      juzTitle: 'Juz 5',
      hizbTitle: 'Hizb 10',
    );
    await tester.pump();
    expect(find.text('Page 22'), findsOneWidget);

    bloc.add(const NavigationHidden());
    await tester.pump();
    await tester.pump(
      const Duration(milliseconds: AppDurations.sliderShowHide),
    );

    final ignorePointer = tester.widget<IgnorePointer>(
      find.descendant(
        of: find.byType(PremiumNavigationOverlay),
        matching: find.byType(IgnorePointer),
      ),
    );
    expect(ignorePointer.ignoring, isTrue);
  });
}

class _InMemoryLastVisitedPageRepository implements LastVisitedPageRepository {
  _InMemoryLastVisitedPageRepository({this.initialPage});

  final int? initialPage;
  int? _lastVisitedPage;

  @override
  Future<void> clearLastVisitedPage() async {
    _lastVisitedPage = null;
  }

  @override
  Future<int?> getLastVisitedPage() async => _lastVisitedPage ?? initialPage;

  @override
  Future<void> saveLastVisitedPage(int pageNumber) async {
    _lastVisitedPage = pageNumber;
  }
}

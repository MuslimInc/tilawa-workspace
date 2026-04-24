import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image/data/repositories/in_memory_navigation_visibility_repository.dart';
import 'package:quran_image/data/repositories/in_memory_page_repository.dart';
import 'package:quran_image/domain/domain.dart';

void main() {
  test(
    'InMemoryPageRepository navigates, bounds checks, and emits state',
    () async {
      final repository = InMemoryPageRepository();
      addTearDown(repository.dispose);

      final emittedStates = <PageState>[];
      final subscription = repository.watchPageState().listen(
        emittedStates.add,
      );
      addTearDown(subscription.cancel);

      expect(repository.getCurrentPage().currentPage, 1);

      final pageTwo = repository.nextPage();
      expect(pageTwo.currentPage, 2);

      final pageOne = repository.previousPage();
      expect(pageOne.currentPage, 1);

      final pageTen = repository.navigateToPage(10);
      expect(pageTen.currentPage, 10);
      expect(repository.getCurrentPage().currentPage, 10);

      expect(
        () => repository.navigateToPage(PageState.quranPageCount + 1),
        throwsArgumentError,
      );

      await Future<void>.delayed(Duration.zero);
      expect(
        emittedStates.map((state) => state.currentPage),
        containsAll(<int>[2, 1, 10]),
      );
    },
  );

  test(
    'InMemoryNavigationVisibilityRepository updates and streams visibility',
    () async {
      final repository = InMemoryNavigationVisibilityRepository();
      addTearDown(repository.dispose);

      final emittedStates = <NavigationVisibility>[];
      final subscription = repository.watchVisibility().listen(
        emittedStates.add,
      );
      addTearDown(subscription.cancel);

      expect((await repository.getVisibility()).isVisible, isFalse);

      final shown = await repository.show();
      expect(shown.isVisible, isTrue);
      expect(await repository.shouldAutoHide(999), isFalse);

      final interacting = await repository.startInteraction();
      expect(interacting.isInteracting, isTrue);

      final idle = await repository.endInteraction();
      expect(idle.isInteracting, isFalse);

      final hidden = await repository.hide();
      expect(hidden.isVisible, isFalse);
      expect(hidden.lastShownAt, isNull);

      final custom = NavigationVisibility(
        isVisible: true,
        lastShownAt: DateTime.now().subtract(const Duration(seconds: 5)),
      );
      await repository.saveVisibility(custom);
      expect(await repository.shouldAutoHide(1), isTrue);

      await Future<void>.delayed(Duration.zero);
      expect(emittedStates.length, greaterThanOrEqualTo(5));
    },
  );
}

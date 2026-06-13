import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_event.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_state.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/features/quran_reader/presentation/navigation/quran_image_reader_index_navigation.dart';

import '../../helpers/test_navigation_bloc_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuranImageReaderIndexNavigation.pageForSurah', () {
    test('maps Al-Fatiha to page 1', () {
      expect(QuranImageReaderIndexNavigation.pageForSurah(1), 1);
    });

    test('maps Al-Baqarah to page 2', () {
      expect(QuranImageReaderIndexNavigation.pageForSurah(2), 2);
    });

    test('maps An-Nas to page 604', () {
      expect(QuranImageReaderIndexNavigation.pageForSurah(114), 604);
    });

    test('matches getPageNumber for first ayah', () {
      for (final int surah in <int>[1, 2, 18, 36, 67, 114]) {
        expect(
          QuranImageReaderIndexNavigation.pageForSurah(surah),
          getPageNumber(surah, 1),
        );
      }
    });
  });

  group('QuranImageReaderIndexNavigation.pageChangedEventForSurah', () {
    test('builds PageChanged with surah start page', () {
      const int surahNumber = 18;
      final PageChanged event =
          QuranImageReaderIndexNavigation.pageChangedEventForSurah(surahNumber);

      expect(event, PageChanged(getPageNumber(surahNumber, 1)));
    });

    test('uses ayah 1 for every surah selection', () {
      expect(
        QuranImageReaderIndexNavigation.pageChangedEventForSurah(6),
        PageChanged(getPageNumber(6, 1)),
      );
    });
  });

  group('QuranImageReaderIndexNavigation.shouldDispatchSelection', () {
    test('returns true when mounted and surah selected', () {
      expect(
        QuranImageReaderIndexNavigation.shouldDispatchSelection(
          isMounted: true,
          selectedSurah: 2,
        ),
        isTrue,
      );
    });

    test('returns false when sheet dismissed without selection', () {
      expect(
        QuranImageReaderIndexNavigation.shouldDispatchSelection(
          isMounted: true,
          selectedSurah: null,
        ),
        isFalse,
      );
    });

    test('returns false when widget is unmounted', () {
      expect(
        QuranImageReaderIndexNavigation.shouldDispatchSelection(
          isMounted: false,
          selectedSurah: 2,
        ),
        isFalse,
      );
    });
  });

  group('QuranImageReaderIndexNavigation.dispatchSelection', () {
    late NavigationBloc bloc;

    setUp(() {
      bloc = createLoadedNavigationBloc(initialPage: 137);
    });

    tearDown(() async {
      await bloc.close();
    });

    test('updates NavigationBloc to selected surah page', () async {
      const int selectedSurah = 2;
      final int expectedPage = getPageNumber(selectedSurah, 1);

      QuranImageReaderIndexNavigation.dispatchSelection(bloc, selectedSurah);
      await pumpNavigationBloc(bloc);

      final NavigationLoaded loaded = bloc.state as NavigationLoaded;
      expect(loaded.pageState.currentPage, expectedPage);
    });

    test('jumps from Al-Anam page to Al-Fatiha', () async {
      expect((bloc.state as NavigationLoaded).pageState.currentPage, 137);

      QuranImageReaderIndexNavigation.dispatchSelection(bloc, 1);
      await pumpNavigationBloc(bloc);

      expect((bloc.state as NavigationLoaded).pageState.currentPage, 1);
    });

    test(
      'NavigationBloc ignores PageChanged when page is already current',
      () async {
        expect((bloc.state as NavigationLoaded).pageState.currentPage, 137);

        bloc.add(const PageChanged(137));
        await pumpNavigationBloc(bloc);

        expect((bloc.state as NavigationLoaded).pageState.currentPage, 137);
      },
    );
  });
}

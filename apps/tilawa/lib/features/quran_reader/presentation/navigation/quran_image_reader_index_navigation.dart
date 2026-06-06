import 'package:quran_image/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_event.dart';
import 'package:quran_qcf/quran_qcf.dart';

/// Applies surah-index selections to the image reader [NavigationBloc].
final class QuranImageReaderIndexNavigation {
  const QuranImageReaderIndexNavigation._();

  /// Resolves the Mushaf page for the first ayah of [surahNumber].
  static int pageForSurah(int surahNumber) => getPageNumber(surahNumber, 1);

  /// Builds the bloc event used after the user picks a surah from the index.
  static PageChanged pageChangedEventForSurah(int surahNumber) {
    return PageChanged(pageForSurah(surahNumber));
  }

  /// Whether a sheet result should trigger navigation.
  static bool shouldDispatchSelection({
    required bool isMounted,
    required int? selectedSurah,
  }) {
    return isMounted && selectedSurah != null;
  }

  /// Dispatches [PageChanged] for the selected surah.
  static void dispatchSelection(
    NavigationBloc navigationBloc,
    int selectedSurah,
  ) {
    navigationBloc.add(pageChangedEventForSurah(selectedSurah));
  }
}

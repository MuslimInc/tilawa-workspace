import 'package:checks/checks.dart';
import 'package:test/test.dart';
import 'package:tilawa/features/quran_reader/presentation/screens/quran_reader_host_screen.dart';

void main() {
  group('applyLastReadPosition', () {
    test('prefers saved Mushaf page over null route page', () {
      final resolved = applyLastReadPosition(
        currentSurah: 1,
        currentAyah: null,
        currentPage: null,
        position: (surahNumber: 2, ayahNumber: 5, page: 22),
      );

      check(resolved.surah).equals(2);
      check(resolved.ayah).equals(5);
      check(resolved.page).equals(22);
    });

    test('keeps route page when saved page is null', () {
      final resolved = applyLastReadPosition(
        currentSurah: 1,
        currentAyah: 1,
        currentPage: 10,
        position: (surahNumber: 1, ayahNumber: null, page: null),
      );

      check(resolved.page).equals(10);
      check(resolved.ayah).equals(1);
    });
  });
}

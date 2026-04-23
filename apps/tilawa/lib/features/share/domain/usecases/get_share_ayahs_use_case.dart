import 'package:injectable/injectable.dart';
import '../../../quran_reader/domain/entities/entities.dart';
import '../../../quran_reader/domain/repositories/quran_reader_repository.dart';

@injectable
class GetShareAyahsUseCase {
  const GetShareAyahsUseCase(this._repository);

  final QuranReaderRepository _repository;

  Future<List<PageAyahInfo>> call({
    required int surahNumber,
    required int fromAyah,
    required int toAyah,
  }) async {
    final surahContent = await _repository.getSurahContent(surahNumber);

    // Performance Optimization: Use O(1) sub-list slicing instead of O(N) where/filtering
    // since ayahs are guaranteed to be sequential and sorted by numberInSurah.
    // numberInSurah is 1-indexed, so index = numberInSurah - 1.

    final startIndex = fromAyah - 1;
    final endIndex = toAyah; // Exclusive index for sublist

    // Safety check for bounds
    if (startIndex < 0 || endIndex > surahContent.ayahs.length) {
      return const [];
    }

    final rangeAyahs = surahContent.ayahs.sublist(startIndex, endIndex);

    return rangeAyahs
        .map(
          (a) => PageAyahInfo(
            surahNumber: surahNumber,
            surahName: surahContent.name,
            surahNameEnglish: surahContent.nameEnglish,
            ayahNumber: a.numberInSurah,
            text: a.textUthmani ?? a.text,
            words: null,
          ),
        )
        .toList();
  }
}

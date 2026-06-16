import 'package:injectable/injectable.dart';
import 'package:quran_qcf/quran_qcf.dart';

import '../../domain/entities/recitation_target.dart';
import '../../domain/repositories/recitation_verse_repository.dart';

@LazySingleton(as: RecitationVerseRepository)
class RecitationVerseRepositoryImpl implements RecitationVerseRepository {
  const RecitationVerseRepositoryImpl(this._verseService);

  final VerseService _verseService;

  @override
  List<RecitationTarget> getTargetsForPage(int pageNumber) {
    final List<PageSurahEntry> entries = getPageData(pageNumber);
    final List<RecitationTarget> targets = <RecitationTarget>[];

    for (final PageSurahEntry entry in entries) {
      for (var ayah = entry.start; ayah <= entry.end; ayah++) {
        targets.add(
          RecitationTarget(
            surahNumber: entry.surah,
            ayahNumber: ayah,
            pageNumber: pageNumber,
            displayText: _verseService.getVerse(entry.surah, ayah),
            normalText: _verseService.getVerseNormal(entry.surah, ayah),
          ),
        );
      }
    }

    return targets;
  }
}

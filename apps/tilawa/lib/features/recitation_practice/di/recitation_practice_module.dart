import 'package:injectable/injectable.dart';
import 'package:quran_qcf/quran_qcf.dart';

import '../domain/services/recitation_text_aligner.dart';

@module
abstract class RecitationPracticeModule {
  @lazySingleton
  TextNormalizationService textNormalizationService() =>
      const TextNormalizationServiceImpl();

  @lazySingleton
  VerseService verseService() => const VerseServiceImpl();

  @lazySingleton
  RecitationTextAligner recitationTextAligner() =>
      const RecitationTextAligner();
}

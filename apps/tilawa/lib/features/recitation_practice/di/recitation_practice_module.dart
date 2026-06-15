import 'package:injectable/injectable.dart';
import 'package:quran_qcf/quran_qcf.dart';

import '../domain/services/recitation_speech_normalizer.dart';
import '../domain/services/recitation_text_aligner.dart';

@module
abstract class RecitationPracticeModule {
  @lazySingleton
  TextNormalizationService textNormalizationService() =>
      const TextNormalizationServiceImpl();

  @lazySingleton
  RecitationSpeechNormalizer recitationSpeechNormalizer(
    TextNormalizationService textNormalizationService,
  ) =>
      RecitationSpeechNormalizer(textNormalizationService);

  @lazySingleton
  VerseService verseService() => const VerseServiceImpl();

  @lazySingleton
  RecitationTextAligner recitationTextAligner() =>
      const RecitationTextAligner();
}

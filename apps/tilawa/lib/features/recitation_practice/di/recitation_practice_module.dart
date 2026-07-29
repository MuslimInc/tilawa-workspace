import 'package:get_it/get_it.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';

import '../domain/services/recitation_speech_normalizer.dart';
import '../domain/services/recitation_text_aligner.dart';

class RecitationPracticeModule {
  RecitationPracticeModule._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<TextNormalizationService>(
      () => const TextNormalizationServiceImpl(),
    );
    getIt.registerLazySingletonIfAbsent<RecitationSpeechNormalizer>(
      () => RecitationSpeechNormalizer(getIt<TextNormalizationService>()),
    );
    getIt.registerLazySingletonIfAbsent<VerseService>(
      () => const VerseServiceImpl(),
    );
    getIt.registerLazySingletonIfAbsent<RecitationTextAligner>(
      () => const RecitationTextAligner(),
    );
  }
}

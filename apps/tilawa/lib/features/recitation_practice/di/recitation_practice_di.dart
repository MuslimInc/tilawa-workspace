import 'package:cloud_functions/cloud_functions.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/features/recitation_practice/data/datasources/speech_recognition_datasource.dart';
import 'package:tilawa/features/recitation_practice/data/repositories/recitation_audio_verification_repository_impl.dart';
import 'package:tilawa/features/recitation_practice/data/repositories/recitation_verse_repository_impl.dart';
import 'package:tilawa/features/recitation_practice/data/repositories/speech_recognition_repository_impl.dart';
import 'package:tilawa/features/recitation_practice/data/services/microphone_permission_service.dart';
import 'package:tilawa/features/recitation_practice/data/services/recitation_audio_recorder.dart';
import 'package:tilawa/features/recitation_practice/data/services/recitation_audio_verification_client.dart';
import 'package:tilawa/features/recitation_practice/domain/repositories/recitation_audio_verification_repository.dart';
import 'package:tilawa/features/recitation_practice/domain/repositories/recitation_verse_repository.dart';
import 'package:tilawa/features/recitation_practice/domain/repositories/speech_recognition_repository.dart';
import 'package:tilawa/features/recitation_practice/domain/services/recitation_speech_normalizer.dart';
import 'package:tilawa/features/recitation_practice/domain/services/recitation_text_aligner.dart';
import 'package:tilawa/features/recitation_practice/domain/usecases/compare_recitation_use_case.dart';
import 'package:tilawa/features/recitation_practice/domain/usecases/get_page_recitation_targets_use_case.dart';
import 'package:tilawa/features/recitation_practice/domain/usecases/request_microphone_permission_use_case.dart';
import 'package:tilawa/features/recitation_practice/presentation/cubit/recitation_practice_cubit.dart';

/// Manual GetIt registrations for `recitation_practice`.
class RecitationPracticeDi {
  RecitationPracticeDi._();

  static void register(GetIt getIt) {
    getIt.registerFactoryIfAbsent<SpeechRecognitionDatasource>(
      SpeechRecognitionDatasource.new,
    );
    getIt.registerLazySingletonIfAbsent<RecitationAudioRecorder>(
      RecitationAudioRecorder.new,
    );
    getIt.registerLazySingletonIfAbsent<RecitationVerseRepository>(
      () => RecitationVerseRepositoryImpl(getIt<VerseService>()),
    );
    getIt.registerLazySingletonIfAbsent<MicrophonePermissionService>(
      () => MicrophonePermissionService(getIt<SharedPreferencesAsync>()),
    );
    getIt.registerLazySingletonIfAbsent<RecitationAudioVerificationClient>(
      () => RecitationAudioVerificationClient(
        getIt<FirebaseFunctions>(),
        httpClient: getIt<Client>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<GetPageRecitationTargetsUseCase>(
      () => GetPageRecitationTargetsUseCase(
        getIt<RecitationVerseRepository>(),
      ),
    );
    getIt.registerFactoryIfAbsent<SpeechRecognitionRepository>(
      () => SpeechRecognitionRepositoryImpl(
        getIt<SpeechRecognitionDatasource>(),
        getIt<MicrophonePermissionService>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<RequestMicrophonePermissionUseCase>(
      () => RequestMicrophonePermissionUseCase(
        getIt<MicrophonePermissionService>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<CompareRecitationUseCase>(
      () => CompareRecitationUseCase(
        getIt<RecitationSpeechNormalizer>(),
        getIt<RecitationTextAligner>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<RecitationAudioVerificationRepository>(
      () => RecitationAudioVerificationRepositoryImpl(
        getIt<RecitationAudioRecorder>(),
        getIt<RecitationAudioVerificationClient>(),
        getIt<MicrophonePermissionService>(),
      ),
    );
    getIt.registerFactoryIfAbsent<RecitationPracticeCubit>(
      () => RecitationPracticeCubit(
        getIt<GetPageRecitationTargetsUseCase>(),
        getIt<RecitationAudioVerificationRepository>(),
      ),
    );
  }
}

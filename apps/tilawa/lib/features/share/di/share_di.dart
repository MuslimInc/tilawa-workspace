import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/features/downloads/domain/repositories/download_query_repository.dart';
import 'package:tilawa/features/quran_reader/domain/repositories/quran_reader_repository.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_reciters_use_case.dart';
import 'package:tilawa/features/share/data/ffmpeg/disabled_ffmpeg_runner.dart';
import 'package:tilawa/features/share/data/ffmpeg/ffmpeg_runner.dart';
import 'package:tilawa/features/share/data/repositories/share_repository_impl.dart';
import 'package:tilawa/features/share/data/services/audio_clip_service.dart';
import 'package:tilawa/features/share/data/services/ayah_timing_service.dart';
import 'package:tilawa/features/share/data/services/screenshot_service.dart';
import 'package:tilawa/features/share/data/services/share_file_manager.dart';
import 'package:tilawa/features/share/data/services/video_service.dart';
import 'package:tilawa/features/share/domain/repositories/share_repository.dart';
import 'package:tilawa/features/share/domain/usecases/capture_screenshot_use_case.dart';
import 'package:tilawa/features/share/domain/usecases/generate_audio_clip_use_case.dart';
import 'package:tilawa/features/share/domain/usecases/generate_video_use_case.dart';
import 'package:tilawa/features/share/domain/usecases/get_share_ayahs_use_case.dart';
import 'package:tilawa/features/share/domain/usecases/prepare_share_range_use_case.dart';
import 'package:tilawa/features/share/domain/usecases/share_content_use_case.dart';
import 'package:tilawa/features/share/presentation/cubit/share_cubit.dart';

/// Manual GetIt registrations for `share`.
class ShareDi {
  ShareDi._();

  static void register(GetIt getIt) {
    getIt.registerFactoryIfAbsent<PrepareShareRangeUseCase>(
      () => const PrepareShareRangeUseCase(),
    );
    getIt.registerLazySingletonIfAbsent<ShareFileManager>(
      ShareFileManager.new,
    );
    getIt.registerLazySingletonIfAbsent<FFmpegRunner>(
      () => const DisabledFfmpegRunner(),
    );
    getIt.registerLazySingletonIfAbsent<AyahTimingService>(
      () => AyahTimingService(getIt<Dio>()),
    );
    getIt.registerLazySingletonIfAbsent<ScreenshotService>(
      () => ScreenshotService(getIt<ShareFileManager>()),
    );
    getIt.registerLazySingletonIfAbsent<VideoService>(
      () => VideoService(
        getIt<ShareFileManager>(),
        getIt<FFmpegRunner>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<AudioClipService>(
      () => AudioClipService(
        getIt<Dio>(),
        getIt<ShareFileManager>(),
        getIt<AyahTimingService>(),
        getIt<FFmpegRunner>(),
      ),
    );
    getIt.registerFactoryIfAbsent<GetShareAyahsUseCase>(
      () => GetShareAyahsUseCase(getIt<QuranReaderRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<ShareRepository>(
      () => ShareRepositoryImpl(
        getIt<ScreenshotService>(),
        getIt<AudioClipService>(),
        getIt<VideoService>(),
        getIt<ShareFileManager>(),
        getIt<DownloadQueryRepository>(),
      ),
    );
    getIt.registerFactoryIfAbsent<CaptureScreenshotUseCase>(
      () => CaptureScreenshotUseCase(getIt<ShareRepository>()),
    );
    getIt.registerFactoryIfAbsent<GenerateAudioClipUseCase>(
      () => GenerateAudioClipUseCase(getIt<ShareRepository>()),
    );
    getIt.registerFactoryIfAbsent<GenerateVideoUseCase>(
      () => GenerateVideoUseCase(getIt<ShareRepository>()),
    );
    getIt.registerFactoryIfAbsent<ShareContentUseCase>(
      () => ShareContentUseCase(getIt<ShareRepository>()),
    );
    getIt.registerFactoryIfAbsent<ShareCubit>(
      () => ShareCubit(
        getIt<CaptureScreenshotUseCase>(),
        getIt<GenerateAudioClipUseCase>(),
        getIt<GenerateVideoUseCase>(),
        getIt<PrepareShareRangeUseCase>(),
        getIt<GetShareAyahsUseCase>(),
        getIt<ShareContentUseCase>(),
        getIt<GetRecitersUseCase>(),
      ),
    );
  }
}

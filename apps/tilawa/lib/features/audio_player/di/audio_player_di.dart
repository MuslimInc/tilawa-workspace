import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/features/app_review/domain/services/app_review_trigger_manager.dart';
import 'package:tilawa/features/audio_player/data/repositories/audio_player_repository_impl.dart';
import 'package:tilawa/features/audio_player/data/repositories/player_background_repository_impl.dart';
import 'package:tilawa/features/audio_player/domain/repositories/audio_player_repository.dart';
import 'package:tilawa/features/audio_player/domain/repositories/player_background_repository.dart';
import 'package:tilawa/features/audio_player/domain/services/artist_media_playlist_cache.dart';
import 'package:tilawa/features/audio_player/domain/services/audio_entity_media_item_mapper.dart';
import 'package:tilawa/features/audio_player/domain/services/moshaf_surah_audio_list_builder.dart';
import 'package:tilawa/features/audio_player/domain/services/playback_uri_resolver.dart';
import 'package:tilawa/features/audio_player/domain/services/reciter_audio_catalog_builder.dart';
import 'package:tilawa/features/audio_player/domain/services/reciter_audio_catalog_cache.dart';
import 'package:tilawa/features/audio_player/domain/usecases/audio_player_usecases.dart';
import 'package:tilawa/features/audio_player/domain/usecases/check_audio_playability_use_case.dart';
import 'package:tilawa/features/audio_player/domain/usecases/decode_persisted_player_background_use_case.dart';
import 'package:tilawa/features/audio_player/domain/usecases/delete_player_background_use_case.dart';
import 'package:tilawa/features/audio_player/domain/usecases/encode_player_background_configuration_use_case.dart';
import 'package:tilawa/features/audio_player/domain/usecases/get_audio_streams_use_case.dart';
import 'package:tilawa/features/audio_player/domain/usecases/pick_player_background_use_case.dart';
import 'package:tilawa/features/audio_player/domain/usecases/reset_player_background_use_case.dart';
import 'package:tilawa/features/audio_player/domain/usecases/sync_active_playback_from_handler_use_case.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/audio_player/presentation/cubit/player_background_cubit.dart';
import 'package:tilawa/features/audio_player/presentation/player_presentation_controller.dart';
import 'package:tilawa/features/audio_player/presentation/quran_player_navigation.dart';
import 'package:tilawa/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:tilawa/features/history/domain/usecases/add_or_update_history_use_case.dart';
import 'package:tilawa/features/reciters/domain/repositories/reciters_repository.dart';
import 'package:tilawa/features/settings/domain/services/sleep_timer_settings.dart';
import 'package:tilawa/shared/audio/audio_player_handler.dart';
import 'package:tilawa/shared/services/audio_position_service.dart';
import 'package:tilawa_core/network/network_info.dart';
import 'package:tilawa_core/services/analytics_service.dart';

/// Manual GetIt registrations for `audio_player`.
class AudioPlayerDi {
  AudioPlayerDi._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<ArtistMediaPlaylistCache>(
      ArtistMediaPlaylistCache.new,
    );
    getIt.registerLazySingletonIfAbsent<AudioEntityMediaItemMapper>(
      () => const AudioEntityMediaItemMapper(),
    );
    getIt.registerLazySingletonIfAbsent<ReciterAudioCatalogBuilder>(
      () => const ReciterAudioCatalogBuilder(),
    );
    getIt.registerLazySingletonIfAbsent<QuranPlayerNavigation>(
      GoRouterQuranPlayerNavigation.new,
    );
    getIt.registerLazySingletonIfAbsent<MoshafSurahAudioListBuilder>(
      () => MoshafSurahAudioListBuilder(getIt<SharedPreferencesAsync>()),
    );
    getIt.registerLazySingletonIfAbsent<PlayerBackgroundRepository>(
      PlayerBackgroundRepositoryImpl.new,
    );
    getIt.registerLazySingletonIfAbsent<PlayerPresentationController>(
      () => PlayerPresentationController(
        getIt<QuranPlayerNavigation>(),
      ),
    );
    getIt.registerFactoryIfAbsent<DecodePersistedPlayerBackgroundUseCase>(
      () => DecodePersistedPlayerBackgroundUseCase(
        getIt<PlayerBackgroundRepository>(),
      ),
    );
    getIt.registerFactoryIfAbsent<DeletePlayerBackgroundUseCase>(
      () => DeletePlayerBackgroundUseCase(
        getIt<PlayerBackgroundRepository>(),
      ),
    );
    getIt.registerFactoryIfAbsent<EncodePlayerBackgroundConfigurationUseCase>(
      () => EncodePlayerBackgroundConfigurationUseCase(
        getIt<PlayerBackgroundRepository>(),
      ),
    );
    getIt.registerFactoryIfAbsent<PickPlayerBackgroundUseCase>(
      () => PickPlayerBackgroundUseCase(
        getIt<PlayerBackgroundRepository>(),
      ),
    );
    getIt.registerFactoryIfAbsent<ResetPlayerBackgroundUseCase>(
      () => ResetPlayerBackgroundUseCase(
        getIt<PlayerBackgroundRepository>(),
      ),
    );
    getIt.registerFactoryIfAbsent<PlayerBackgroundCubit>(
      () => PlayerBackgroundCubit(
        getIt<DecodePersistedPlayerBackgroundUseCase>(),
        getIt<EncodePlayerBackgroundConfigurationUseCase>(),
        getIt<PickPlayerBackgroundUseCase>(),
        getIt<ResetPlayerBackgroundUseCase>(),
        getIt<DeletePlayerBackgroundUseCase>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<ReciterAudioCatalogCache>(
      () => ReciterAudioCatalogCache(
        getIt<RecitersRepository>(),
        getIt<ReciterAudioCatalogBuilder>(),
      ),
    );
    getIt.registerFactoryIfAbsent<CheckAudioPlayabilityUseCase>(
      () => CheckAudioPlayabilityUseCase(
        getIt<NetworkInfo>(),
        getIt<DownloadsRepository>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<PlaybackUriResolver>(
      () => PlaybackUriResolver(getIt<DownloadsRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<AudioPlayerRepository>(
      () => AudioPlayerRepositoryImpl(
        getIt<AudioPlayerHandler>(),
        getIt<AudioPositionService>(),
      ),
    );
    getIt.registerFactoryIfAbsent<PlayAudioUseCase>(
      () => PlayAudioUseCase(getIt<AudioPlayerRepository>()),
    );
    getIt.registerFactoryIfAbsent<PauseAudioUseCase>(
      () => PauseAudioUseCase(getIt<AudioPlayerRepository>()),
    );
    getIt.registerFactoryIfAbsent<StopAudioUseCase>(
      () => StopAudioUseCase(getIt<AudioPlayerRepository>()),
    );
    getIt.registerFactoryIfAbsent<SeekToUseCase>(
      () => SeekToUseCase(getIt<AudioPlayerRepository>()),
    );
    getIt.registerFactoryIfAbsent<SkipToNextUseCase>(
      () => SkipToNextUseCase(getIt<AudioPlayerRepository>()),
    );
    getIt.registerFactoryIfAbsent<SkipToPreviousUseCase>(
      () => SkipToPreviousUseCase(getIt<AudioPlayerRepository>()),
    );
    getIt.registerFactoryIfAbsent<SetVolumeUseCase>(
      () => SetVolumeUseCase(getIt<AudioPlayerRepository>()),
    );
    getIt.registerFactoryIfAbsent<SetPlaybackSpeedUseCase>(
      () => SetPlaybackSpeedUseCase(getIt<AudioPlayerRepository>()),
    );
    getIt.registerFactoryIfAbsent<SetRepeatModeUseCase>(
      () => SetRepeatModeUseCase(getIt<AudioPlayerRepository>()),
    );
    getIt.registerFactoryIfAbsent<SetShuffleModeUseCase>(
      () => SetShuffleModeUseCase(getIt<AudioPlayerRepository>()),
    );
    getIt.registerFactoryIfAbsent<SkipToQueueItemUseCase>(
      () => SkipToQueueItemUseCase(getIt<AudioPlayerRepository>()),
    );
    getIt.registerFactoryIfAbsent<PlayFromQueueUseCase>(
      () => PlayFromQueueUseCase(getIt<AudioPlayerRepository>()),
    );
    getIt.registerFactoryIfAbsent<UpdateQueueUseCase>(
      () => UpdateQueueUseCase(getIt<AudioPlayerRepository>()),
    );
    getIt.registerFactoryIfAbsent<MoveQueueItemUseCase>(
      () => MoveQueueItemUseCase(getIt<AudioPlayerRepository>()),
    );
    getIt.registerFactoryIfAbsent<AddQueueItemUseCase>(
      () => AddQueueItemUseCase(getIt<AudioPlayerRepository>()),
    );
    getIt.registerFactoryIfAbsent<RemoveQueueItemUseCase>(
      () => RemoveQueueItemUseCase(getIt<AudioPlayerRepository>()),
    );
    getIt.registerFactoryIfAbsent<GetAudioStreamsUseCase>(
      () => GetAudioStreamsUseCase(getIt<AudioPlayerRepository>()),
    );
    getIt.registerFactoryIfAbsent<SyncActivePlaybackFromHandlerUseCase>(
      () => SyncActivePlaybackFromHandlerUseCase(
        getIt<AudioPlayerRepository>(),
      ),
    );
    getIt.registerFactoryIfAbsent<AudioPlayerBloc>(
      () => AudioPlayerBloc(
        getIt<GetAudioStreamsUseCase>(),
        getIt<PlayAudioUseCase>(),
        getIt<PauseAudioUseCase>(),
        getIt<StopAudioUseCase>(),
        getIt<SeekToUseCase>(),
        getIt<SkipToNextUseCase>(),
        getIt<SkipToPreviousUseCase>(),
        getIt<SetVolumeUseCase>(),
        getIt<SetPlaybackSpeedUseCase>(),
        getIt<SetRepeatModeUseCase>(),
        getIt<SetShuffleModeUseCase>(),
        getIt<SkipToQueueItemUseCase>(),
        getIt<PlayFromQueueUseCase>(),
        getIt<UpdateQueueUseCase>(),
        getIt<AddQueueItemUseCase>(),
        getIt<RemoveQueueItemUseCase>(),
        getIt<MoveQueueItemUseCase>(),
        getIt<SyncActivePlaybackFromHandlerUseCase>(),
        getIt<CheckAudioPlayabilityUseCase>(),
        getIt<SleepTimerSettings>(),
        getIt<AddOrUpdateHistoryUseCase>(),
        getIt<AnalyticsService>(),
        getIt<AppReviewTriggerManager>(),
      ),
    );
  }
}

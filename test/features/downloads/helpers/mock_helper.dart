import 'package:dio/dio.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/network/network_info.dart';
import 'package:tilawa/core/services/analytics_service.dart';
import 'package:tilawa/core/services/interfaces/notification_dispatcher_interface.dart';
import 'package:tilawa/core/services/navigation_service.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/downloads/data/datasources/downloads_local_datasource.dart';
import 'package:tilawa/features/downloads/data/services/batch_download_manager.dart';
import 'package:tilawa/features/downloads/data/services/download_notification_service.dart';
import 'package:tilawa/features/downloads/data/services/download_path_resolver.dart';
import 'package:tilawa/features/downloads/data/services/download_queue_manager.dart';
import 'package:tilawa/features/downloads/data/services/download_service_interface.dart';
import 'package:tilawa/features/downloads/data/services/download_status_synchronizer.dart';
import 'package:tilawa/features/downloads/data/services/download_validator.dart';
import 'package:tilawa/features/downloads/data/services/flutter_downloader_wrapper.dart';
import 'package:tilawa/features/downloads/data/services/helpers/download_file_helper.dart';
import 'package:tilawa/features/downloads/data/services/helpers/download_isolate_manager.dart';
import 'package:tilawa/features/downloads/data/services/helpers/download_status_mapper.dart';
import 'package:tilawa/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:tilawa/features/downloads/domain/usecases/cancel_download_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/cancel_downloads_for_reciter_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/check_download_access_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/check_surah_downloaded_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/clear_all_downloads_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/delete_download_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/delete_reciter_downloads_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/download_all_surahs_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/download_surah_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/get_download_item_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/get_download_status_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/get_downloads_by_reciter_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/get_total_downloads_size_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/get_valid_completed_downloads_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/observe_download_progress_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/observe_global_download_progress_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/observe_reciter_downloads_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/play_all_downloads_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/play_download_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/remove_from_download_queue_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/retry_download_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/validate_downloaded_file_use_case.dart';
import 'package:tilawa/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:tilawa/features/reciters/domain/repositories/reciters_repository.dart';

@GenerateMocks(
  [
    DownloadServiceInterface,
    DownloadsLocalDataSource,
    DownloadNotificationService,
    BatchDownloadManager,
    DownloadPathResolver,
    DownloadValidator,
    DownloadStatusSynchronizer,
    DownloadQueueManager,
    FlutterDownloaderWrapper,
    DownloadFileHelper,
    DownloadIsolateManager,
    DownloadsRepository,
    RecitersRepository,
    AnalyticsService,
    NetworkInfo,
    DownloadsBloc,
    AudioPlayerBloc,
    NavigationService,
    // Use Cases
    GetDownloadsByReciterUseCase,
    GetTotalDownloadsSizeUseCase,
    DownloadSurahUseCase,
    DownloadAllSurahsUseCase,
    DeleteDownloadUseCase,
    DeleteReciterDownloadsUseCase,
    ClearAllDownloadsUseCase,
    CheckSurahDownloadedUseCase,
    ValidateDownloadedFileUseCase,
    GetValidCompletedDownloadsUseCase,
    CheckDownloadAccessUseCase,
    PlayDownloadUseCase,
    PlayAllDownloadsUseCase,
    RetryDownloadUseCase,
    GetDownloadItemUseCase,
    CancelDownloadUseCase,
    CancelDownloadsForReciterUseCase,
    ObserveGlobalDownloadProgressUseCase,
    ObserveDownloadProgressUseCase,
    ObserveReciterDownloadsUseCase,
    GetDownloadStatusUseCase,
    RemoveFromDownloadQueueUseCase,
    DownloadStatusMapper,
    SharedPreferencesAsync,
    INotificationDispatcher,
  ],
  customMocks: [MockSpec<Dio>(as: #MockDio)],
)
void main() {}

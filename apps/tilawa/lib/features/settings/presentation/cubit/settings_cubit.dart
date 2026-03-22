import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/features/settings/domain/usecases/get_app_info.dart';
import 'package:tilawa_core/entities/app_info.dart';

import '../../../downloads/domain/services/download_queue_service_interface.dart';
import '../../domain/services/sleep_timer_settings.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.maxConcurrentDownloads = 2,
    this.restorePlaybackState = true,
    this.isSleepTimerEnabled = true,
    this.appInfo,
  });

  final int maxConcurrentDownloads;
  final bool restorePlaybackState;
  final bool isSleepTimerEnabled;
  final AppInfo? appInfo;

  SettingsState copyWith({
    int? maxConcurrentDownloads,
    bool? restorePlaybackState,
    bool? isSleepTimerEnabled,
    AppInfo? appInfo,
  }) {
    return SettingsState(
      maxConcurrentDownloads:
          maxConcurrentDownloads ?? this.maxConcurrentDownloads,
      restorePlaybackState: restorePlaybackState ?? this.restorePlaybackState,
      isSleepTimerEnabled: isSleepTimerEnabled ?? this.isSleepTimerEnabled,
      appInfo: appInfo ?? this.appInfo,
    );
  }

  @override
  List<Object?> get props => [
    maxConcurrentDownloads,
    restorePlaybackState,
    isSleepTimerEnabled,
    appInfo,
  ];
}

@lazySingleton
class SettingsCubit extends HydratedCubit<SettingsState>
    implements SleepTimerSettings {
  SettingsCubit(this._downloadQueueService, this._getAppInfo)
    : super(const SettingsState()) {
    // Initialize DownloadQueueManager with persisted value
    _updateQueueManager();
    _fetchAppInfo();
  }

  final IDownloadQueueService _downloadQueueService;
  final GetAppInfo _getAppInfo;

  Future<void> _fetchAppInfo() async {
    try {
      final appInfo = await _getAppInfo();
      emit(state.copyWith(appInfo: appInfo));
    } catch (_) {
      // Ignore errors for app info
    }
  }

  @override
  SettingsState? fromJson(Map<String, dynamic> json) {
    try {
      return SettingsState(
        maxConcurrentDownloads: json['maxConcurrentDownloads'] as int? ?? 2,
        restorePlaybackState: json['restorePlaybackState'] as bool? ?? true,
        isSleepTimerEnabled: json['isSleepTimerEnabled'] as bool? ?? true,
      );
    } catch (_) {
      return const SettingsState();
    }
  }

  @override
  Map<String, dynamic>? toJson(SettingsState state) {
    return {
      'maxConcurrentDownloads': state.maxConcurrentDownloads,
      'restorePlaybackState': state.restorePlaybackState,
      'isSleepTimerEnabled': state.isSleepTimerEnabled,
    };
  }

  Future<void> setMaxConcurrentDownloads(int count) async {
    emit(state.copyWith(maxConcurrentDownloads: count));
    _updateQueueManager();
  }

  Future<void> toggleRestorePlaybackState(bool enabled) async {
    emit(state.copyWith(restorePlaybackState: enabled));
  }

  Future<void> toggleSleepTimerEnabled(bool enabled) async {
    emit(state.copyWith(isSleepTimerEnabled: enabled));
  }

  void _updateQueueManager() {
    _downloadQueueService.maxConcurrentDownloads = state.maxConcurrentDownloads;
  }

  @override
  Stream<bool> get isSleepTimerEnabledStream =>
      stream.map((s) => s.isSleepTimerEnabled).distinct();
}

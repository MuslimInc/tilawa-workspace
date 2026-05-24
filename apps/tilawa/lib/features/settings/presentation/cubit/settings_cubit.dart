import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/services/quran_assets_prefetch_policy_service.dart';
import 'package:tilawa_core/entities/app_info.dart';
import 'package:tilawa_core/services/interfaces/app_info_service.dart';

import '../../../downloads/domain/services/download_queue_service_interface.dart';
import '../../domain/services/sleep_timer_settings.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.maxConcurrentDownloads = 2,
    this.restorePlaybackState = true,
    this.isSleepTimerEnabled = true,
    this.prefetchQuranAssetsOnWifiOnly = true,
    this.showPrayerTimesAlertChipLabels = true,
    this.appInfo,
  });

  final int maxConcurrentDownloads;
  final bool restorePlaybackState;
  final bool isSleepTimerEnabled;
  final bool prefetchQuranAssetsOnWifiOnly;
  final bool showPrayerTimesAlertChipLabels;
  final AppInfo? appInfo;

  SettingsState copyWith({
    int? maxConcurrentDownloads,
    bool? restorePlaybackState,
    bool? isSleepTimerEnabled,
    bool? prefetchQuranAssetsOnWifiOnly,
    bool? showPrayerTimesAlertChipLabels,
    AppInfo? appInfo,
  }) {
    return SettingsState(
      maxConcurrentDownloads:
          maxConcurrentDownloads ?? this.maxConcurrentDownloads,
      restorePlaybackState: restorePlaybackState ?? this.restorePlaybackState,
      isSleepTimerEnabled: isSleepTimerEnabled ?? this.isSleepTimerEnabled,
      prefetchQuranAssetsOnWifiOnly:
          prefetchQuranAssetsOnWifiOnly ?? this.prefetchQuranAssetsOnWifiOnly,
      showPrayerTimesAlertChipLabels:
          showPrayerTimesAlertChipLabels ?? this.showPrayerTimesAlertChipLabels,
      appInfo: appInfo ?? this.appInfo,
    );
  }

  @override
  List<Object?> get props => [
    maxConcurrentDownloads,
    restorePlaybackState,
    isSleepTimerEnabled,
    prefetchQuranAssetsOnWifiOnly,
    showPrayerTimesAlertChipLabels,
    appInfo,
  ];
}

@lazySingleton
class SettingsCubit extends HydratedCubit<SettingsState>
    implements SleepTimerSettings {
  SettingsCubit(
    this._downloadQueueService,
    this._appInfoService,
    this._prefetchPolicyService,
  ) : super(const SettingsState()) {
    // Initialize DownloadQueueManager with persisted value
    _updateQueueManager();
    _fetchAppInfo();
    _syncPrefetchPolicy();
  }

  final IDownloadQueueService _downloadQueueService;
  final AppInfoService _appInfoService;
  final QuranAssetsPrefetchPolicyService _prefetchPolicyService;

  Future<void> _fetchAppInfo() async {
    try {
      final appInfo = await _appInfoService.getAppInfo();
      emit(state.copyWith(appInfo: appInfo));
    } catch (_) {
      // Ignore errors for app info
    }
  }

  Future<void> _syncPrefetchPolicy() async {
    try {
      final bool wifiOnlyEnabled = await _prefetchPolicyService
          .isWifiOnlyEnabled();
      if (wifiOnlyEnabled != state.prefetchQuranAssetsOnWifiOnly) {
        emit(state.copyWith(prefetchQuranAssetsOnWifiOnly: wifiOnlyEnabled));
      }
    } catch (_) {
      // Keep current state if preference loading fails.
    }
  }

  @override
  SettingsState? fromJson(Map<String, dynamic> json) {
    try {
      return SettingsState(
        maxConcurrentDownloads: json['maxConcurrentDownloads'] as int? ?? 2,
        restorePlaybackState: json['restorePlaybackState'] as bool? ?? true,
        isSleepTimerEnabled: json['isSleepTimerEnabled'] as bool? ?? true,
        prefetchQuranAssetsOnWifiOnly:
            json['prefetchQuranAssetsOnWifiOnly'] as bool? ?? true,
        showPrayerTimesAlertChipLabels:
            json['showPrayerTimesAlertChipLabels'] as bool? ?? true,
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
      'prefetchQuranAssetsOnWifiOnly': state.prefetchQuranAssetsOnWifiOnly,
      'showPrayerTimesAlertChipLabels': state.showPrayerTimesAlertChipLabels,
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

  Future<void> togglePrefetchQuranAssetsOnWifiOnly(bool enabled) async {
    emit(state.copyWith(prefetchQuranAssetsOnWifiOnly: enabled));
    await _prefetchPolicyService.setWifiOnlyEnabled(enabled);
  }

  void setShowPrayerTimesAlertChipLabels(bool show) {
    emit(state.copyWith(showPrayerTimesAlertChipLabels: show));
  }

  void _updateQueueManager() {
    _downloadQueueService.maxConcurrentDownloads = state.maxConcurrentDownloads;
  }

  @override
  Stream<bool> get isSleepTimerEnabledStream =>
      stream.map((s) => s.isSleepTimerEnabled).distinct();
}

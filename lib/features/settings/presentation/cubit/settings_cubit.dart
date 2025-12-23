import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../downloads/data/services/download_queue_manager.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.maxConcurrentDownloads = 2,
    this.restorePlaybackState = true,
  });

  final int maxConcurrentDownloads;
  final bool restorePlaybackState;

  SettingsState copyWith({
    int? maxConcurrentDownloads,
    bool? restorePlaybackState,
  }) {
    return SettingsState(
      maxConcurrentDownloads:
          maxConcurrentDownloads ?? this.maxConcurrentDownloads,
      restorePlaybackState: restorePlaybackState ?? this.restorePlaybackState,
    );
  }

  @override
  List<Object?> get props => [maxConcurrentDownloads, restorePlaybackState];
}

@injectable
class SettingsCubit extends HydratedCubit<SettingsState> {
  SettingsCubit(this._downloadQueueManager) : super(const SettingsState()) {
    // Initialize DownloadQueueManager with persisted value
    _updateQueueManager();
  }

  final DownloadQueueManager _downloadQueueManager;

  @override
  SettingsState? fromJson(Map<String, dynamic> json) {
    try {
      return SettingsState(
        maxConcurrentDownloads: json['maxConcurrentDownloads'] as int? ?? 2,
        restorePlaybackState: json['restorePlaybackState'] as bool? ?? true,
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
    };
  }

  Future<void> setMaxConcurrentDownloads(int count) async {
    emit(state.copyWith(maxConcurrentDownloads: count));
    _updateQueueManager();
  }

  Future<void> toggleRestorePlaybackState(bool enabled) async {
    emit(state.copyWith(restorePlaybackState: enabled));
  }

  void _updateQueueManager() {
    _downloadQueueManager.maxConcurrentDownloads = state.maxConcurrentDownloads;
  }
}

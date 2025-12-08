import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../downloads/data/services/download_queue_manager.dart';

class SettingsState extends Equatable {
  const SettingsState({this.maxConcurrentDownloads = 2});

  final int maxConcurrentDownloads;

  SettingsState copyWith({int? maxConcurrentDownloads}) {
    return SettingsState(
      maxConcurrentDownloads:
          maxConcurrentDownloads ?? this.maxConcurrentDownloads,
    );
  }

  @override
  List<Object?> get props => [maxConcurrentDownloads];
}

@injectable
class SettingsCubit extends HydratedCubit<SettingsState> {
  SettingsCubit() : super(const SettingsState()) {
    // Initialize DownloadQueueManager with persisted value
    _updateQueueManager();
  }

  @override
  SettingsState? fromJson(Map<String, dynamic> json) {
    try {
      return SettingsState(
        maxConcurrentDownloads: json['maxConcurrentDownloads'] as int? ?? 2,
      );
    } catch (_) {
      return const SettingsState();
    }
  }

  @override
  Map<String, dynamic>? toJson(SettingsState state) {
    return {'maxConcurrentDownloads': state.maxConcurrentDownloads};
  }

  Future<void> setMaxConcurrentDownloads(int count) async {
    emit(state.copyWith(maxConcurrentDownloads: count));
    _updateQueueManager();
  }

  void _updateQueueManager() {
    DownloadQueueManager.instance.setMaxConcurrentDownloads(
      state.maxConcurrentDownloads,
    );
  }
}

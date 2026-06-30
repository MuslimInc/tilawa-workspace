import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:tilawa/core/bootstrap/app_startup_tasks.dart';

import '../../support/map_backed_shared_preferences_async.dart';

class _RecordingStorage implements Storage {
  _RecordingStorage(this.initialData);

  final Map<String, dynamic> initialData;
  final List<String> deletedKeys = <String>[];

  @override
  Future<void> clear() async {
    initialData.clear();
  }

  @override
  Future<void> close() async {}

  @override
  Future<void> delete(String key) async {
    deletedKeys.add(key);
    initialData.remove(key);
  }

  @override
  Future<dynamic> read(String key) async => initialData[key];

  @override
  Future<void> write(String key, dynamic value) async {
    initialData[key] = value;
  }
}

void main() {
  group('cleanupLegacyAudioPlayerBlocHydration', () {
    late AppStartupTasks startupTasks;
    late _RecordingStorage storage;
    late MapBackedSharedPreferencesAsync mapPrefs;

    setUp(() {
      mapPrefs = MapBackedSharedPreferencesAsync();
      startupTasks = AppStartupTasks()
        ..sharedPreferencesAsyncOverride = mapPrefs.prefs;
      storage = _RecordingStorage(<String, dynamic>{
        'AudioPlayerBloc': <String, dynamic>{'status': 'success'},
      });
      HydratedBloc.storage = storage;
    });

    test('deletes legacy AudioPlayerBloc storage once', () async {
      await startupTasks.cleanupLegacyAudioPlayerBlocHydration();

      expect(storage.deletedKeys, <String>['AudioPlayerBloc']);
      expect(
        mapPrefs.store[AppStartupTasks
            .legacyAudioPlayerBlocHydrationCleanupKey],
        isTrue,
      );
    });

    test('skips delete when cleanup flag already set', () async {
      mapPrefs.store[AppStartupTasks.legacyAudioPlayerBlocHydrationCleanupKey] =
          true;

      await startupTasks.cleanupLegacyAudioPlayerBlocHydration();

      expect(storage.deletedKeys, isEmpty);
      expect(storage.initialData.containsKey('AudioPlayerBloc'), isTrue);
    });
  });
}

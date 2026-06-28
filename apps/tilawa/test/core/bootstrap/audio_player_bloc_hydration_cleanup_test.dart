import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/bootstrap/app_startup_tasks.dart';

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

    setUp(() {
      startupTasks = AppStartupTasks();
      storage = _RecordingStorage(<String, dynamic>{
        'AudioPlayerBloc': <String, dynamic>{'status': 'success'},
      });
      HydratedBloc.storage = storage;
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('deletes legacy AudioPlayerBloc storage once', () async {
      await startupTasks.cleanupLegacyAudioPlayerBlocHydration();

      expect(storage.deletedKeys, <String>['AudioPlayerBloc']);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getBool(AppStartupTasks.legacyAudioPlayerBlocHydrationCleanupKey),
        isTrue,
      );
    });

    test('skips delete when cleanup flag already set', () async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        AppStartupTasks.legacyAudioPlayerBlocHydrationCleanupKey,
        true,
      );

      await startupTasks.cleanupLegacyAudioPlayerBlocHydration();

      expect(storage.deletedKeys, isEmpty);
      expect(storage.initialData.containsKey('AudioPlayerBloc'), isTrue);
    });
  });
}

import 'package:checks/checks.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_platform_config_data_source.dart';
import 'package:tilawa/features/quran_sessions/data/local/shared_preferences_platform_config_data_source.dart';
import 'package:tilawa/features/quran_sessions/data/quran_sessions_platform_config_repository.dart';
import 'package:tilawa/features/quran_sessions/domain/entities/quran_sessions_platform_config.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_platform_config_store.dart';

import '../../support/map_backed_shared_preferences_async.dart';

class MockFirestorePlatformConfigDataSource extends Mock
    implements FirestorePlatformConfigDataSource {}

void main() {
  const cachedConfig = QuranSessionsPlatformConfig(
    quranSessionsEnabled: true,
    studentEntryEnabled: true,
    bookingEnabled: false,
    bookingMode: 'requiresTutorApproval',
    sessionMode: 'videoOnly',
    enabledCallProviders: {'external'},
  );

  const remoteConfig = QuranSessionsPlatformConfig(
    quranSessionsEnabled: true,
    studentEntryEnabled: true,
    bookingEnabled: true,
    bookingMode: 'autoConfirm',
    sessionMode: 'videoOnly',
    enabledCallProviders: {'external', 'mock'},
  );

  test('loadCachedConfig updates store from SharedPreferencesAsync', () async {
    final prefs = MapBackedSharedPreferencesAsync();
    final local = SharedPreferencesPlatformConfigDataSource(prefs.prefs);
    await local.save(cachedConfig);
    final store = QuranSessionsPlatformConfigStore();
    final repository = QuranSessionsPlatformConfigRepository(
      remoteDataSource: null,
      localDataSource: local,
      store: store,
    );

    await repository.loadCachedConfig();

    check(store.config).equals(cachedConfig);
  });

  test('refreshRemoteConfig updates store and local cache', () async {
    final remote = MockFirestorePlatformConfigDataSource();
    when(() => remote.getGlobalConfig()).thenAnswer((_) async => remoteConfig);
    final prefs = MapBackedSharedPreferencesAsync();
    final local = SharedPreferencesPlatformConfigDataSource(prefs.prefs);
    final store = QuranSessionsPlatformConfigStore();
    final repository = QuranSessionsPlatformConfigRepository(
      remoteDataSource: remote,
      localDataSource: local,
      store: store,
    );

    await repository.refreshRemoteConfig();

    check(store.config).equals(remoteConfig);
    check(await local.load()).equals(remoteConfig);
  });

  test(
    'refreshRemoteConfig clears stale cache when remote config is missing',
    () async {
      final remote = MockFirestorePlatformConfigDataSource();
      when(() => remote.getGlobalConfig()).thenAnswer((_) async => null);
      final prefs = MapBackedSharedPreferencesAsync();
      final local = SharedPreferencesPlatformConfigDataSource(prefs.prefs);
      await local.save(cachedConfig);
      final store = QuranSessionsPlatformConfigStore()..setConfig(cachedConfig);
      final repository = QuranSessionsPlatformConfigRepository(
        remoteDataSource: remote,
        localDataSource: local,
        store: store,
      );

      await repository.refreshRemoteConfig();

      check(store.config).isNull();
      check(await local.load()).isNull();
    },
  );
}

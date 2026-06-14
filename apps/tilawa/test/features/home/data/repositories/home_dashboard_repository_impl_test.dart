import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/domain/entities/auth_result.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';
import 'package:tilawa/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:tilawa/features/home/data/repositories/home_dashboard_repository_impl.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_settings_entity.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/get_current_location_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/get_prayer_times_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/load_prayer_settings_use_case.dart';

void main() {
  group('HomeDashboardRepositoryImpl', () {
    test(
      'uses saved prayer location without requesting current location',
      () async {
        final now = DateTime(2026, 6, 15, 10);
        final prayerRepository = _FakePrayerTimesRepository(
          settings: const PrayerSettingsEntity(
            savedLatitude: 30.0444,
            savedLongitude: 31.2357,
            savedLocationName: 'Cairo',
          ),
        );
        final repository = _createRepository(
          prayerRepository: prayerRepository,
          now: () => now,
        );

        final dashboard = await repository.getDashboard();

        expect(dashboard.displayName, 'Muhammad');
        expect(dashboard.locationLabel, 'Cairo');
        expect(dashboard.nextPrayer?.type, PrayerType.dhuhr);
        expect(dashboard.nextPrayer?.timeUntil, const Duration(hours: 2));
        expect(prayerRepository.currentLocationRequests, 0);
        expect(prayerRepository.permissionRequests, 0);
      },
    );

    test('does not prompt for location permission on passive load', () async {
      final prayerRepository = _FakePrayerTimesRepository(
        settings: const PrayerSettingsEntity(),
        locationPermissionGranted: false,
      );
      final repository = _createRepository(
        prayerRepository: prayerRepository,
        now: () => DateTime(2026, 6, 15, 10),
      );

      final dashboard = await repository.getDashboard();

      expect(dashboard.locationLabel, isNull);
      expect(dashboard.nextPrayer, isNull);
      expect(prayerRepository.permissionChecks, 1);
      expect(prayerRepository.permissionRequests, 0);
    });
  });
}

HomeDashboardRepositoryImpl _createRepository({
  required _FakePrayerTimesRepository prayerRepository,
  required DateTime Function() now,
}) {
  return HomeDashboardRepositoryImpl(
    getCurrentUser: GetCurrentUserUseCase(
      _FakeAuthRepository(
        UserEntity(
          id: 'user-1',
          email: 'user@example.test',
          displayName: 'Muhammad',
          createdAt: DateTime(2026),
        ),
      ),
    ),
    loadPrayerSettings: LoadPrayerSettingsUseCase(prayerRepository),
    getCurrentLocation: GetCurrentLocationUseCase(prayerRepository),
    getPrayerTimes: GetPrayerTimesUseCase(prayerRepository),
    now: now,
  );
}

final class _FakeAuthRepository implements AuthRepository {
  const _FakeAuthRepository(this._currentUser);

  final UserEntity? _currentUser;

  @override
  Stream<UserEntity?> get authStateChanges => Stream.value(_currentUser);

  @override
  UserEntity? get currentUser => _currentUser;

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> prepareGoogleSignIn() async {}

  @override
  Future<AuthResult> signInWithGoogle() async {
    final user = _currentUser;
    if (user == null) {
      return const AuthResult.cancelled();
    }
    return AuthResult.success(user: user);
  }

  @override
  Future<void> signOut() async {}
}

final class _FakePrayerTimesRepository implements PrayerTimesRepository {
  _FakePrayerTimesRepository({
    required this._settings,
    this.locationPermissionGranted = true,
  });

  PrayerSettingsEntity _settings;
  final bool locationPermissionGranted;
  int permissionChecks = 0;
  int permissionRequests = 0;
  int currentLocationRequests = 0;

  @override
  Future<PrayerTimeEntity> getPrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    required PrayerSettingsEntity settings,
  }) async {
    return PrayerTimeEntity(
      date: date,
      fajr: DateTime(date.year, date.month, date.day, 4),
      sunrise: DateTime(date.year, date.month, date.day, 5, 30),
      dhuhr: DateTime(date.year, date.month, date.day, 12),
      asr: DateTime(date.year, date.month, date.day, 15, 30),
      maghrib: DateTime(date.year, date.month, date.day, 18, 45),
      isha: DateTime(date.year, date.month, date.day, 20, 10),
      midnight: DateTime(date.year, date.month, date.day, 23, 40),
      lastThird: DateTime(date.year, date.month, date.day, 2),
      locationName: 'Cairo',
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<LocationResult> getCurrentLocation({bool forceRefresh = false}) async {
    currentLocationRequests += 1;
    return LocationResult(
      latitude: 30.0444,
      longitude: 31.2357,
      locationName: 'Cairo',
      countryCode: 'EG',
    );
  }

  @override
  Future<bool> hasLocationPermission() async {
    permissionChecks += 1;
    return locationPermissionGranted;
  }

  @override
  Future<PrayerSettingsEntity> loadSettings() async => _settings;

  @override
  Future<bool> requestLocationPermission({
    bool allowOpenSettings = false,
  }) async {
    permissionRequests += 1;
    return locationPermissionGranted;
  }

  @override
  Future<void> saveSettings(PrayerSettingsEntity settings) async {
    _settings = settings;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

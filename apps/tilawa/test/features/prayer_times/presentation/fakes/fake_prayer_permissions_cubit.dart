import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/features/prayer_times/presentation/bloc/prayer_permissions_cubit.dart';

/// No-op [PrayerPermissionsCubit] for prayer alerts permission tests.
class FakePrayerPermissionsCubit extends Cubit<PrayerPermissionsState>
    implements PrayerPermissionsCubit {
  FakePrayerPermissionsCubit(super.initial);

  @override
  Future<void> checkCapability() async {}

  @override
  Future<void> requestLocationPermission() async {}

  @override
  Future<void> requestExactAlarmPermission() async {}

  @override
  Future<void> requestNotificationPermission() async {}

  @override
  Future<void> requestIgnoreBatteryOptimizations() async {}
}

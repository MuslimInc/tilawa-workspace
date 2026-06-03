import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/core.dart';

import '../../../../core/services/android_adhan_alarm_player.dart';
import '../../domain/usecases/check_location_permission_use_case.dart';
import '../../domain/usecases/check_prayer_alarm_capability_use_case.dart';
import '../../domain/usecases/request_exact_alarm_permission_use_case.dart';
import '../../domain/usecases/request_location_permission_use_case.dart';
import '../../domain/usecases/request_notification_permission_use_case.dart';
import '../../domain/value_objects/prayer_alarm_capability.dart';

part 'prayer_permissions_cubit.freezed.dart';

@freezed
abstract class PrayerPermissionsState with _$PrayerPermissionsState {
  const factory PrayerPermissionsState({
    PrayerAlarmCapability? capability,
    @Default(true) bool hasLocationPermission,
  }) = _PrayerPermissionsState;
}

@injectable
class PrayerPermissionsCubit extends Cubit<PrayerPermissionsState> {
  PrayerPermissionsCubit(
    this._checkCapabilityUseCase,
    this._checkLocationPermissionUseCase,
    this._requestExactAlarmUseCase,
    this._requestNotificationUseCase,
    this._requestLocationPermissionUseCase,
    this._adhanPlayer,
  ) : super(const PrayerPermissionsState());

  final CheckPrayerAlarmCapabilityUseCase _checkCapabilityUseCase;
  final CheckLocationPermissionUseCase _checkLocationPermissionUseCase;
  final RequestExactAlarmPermissionUseCase _requestExactAlarmUseCase;
  final RequestNotificationPermissionUseCase _requestNotificationUseCase;
  final RequestLocationPermissionUseCase _requestLocationPermissionUseCase;
  final AndroidAdhanAlarmPlayer _adhanPlayer;

  Future<void> checkCapability() async {
    final PrayerAlarmCapability? capability = await _loadCapability();
    final bool hasLocationPermission = await _loadLocationPermission();
    emit(
      state.copyWith(
        capability: capability,
        hasLocationPermission: hasLocationPermission,
      ),
    );
  }

  Future<PrayerAlarmCapability?> _loadCapability() async {
    final Either<Failure, PrayerAlarmCapability> result =
        await _checkCapabilityUseCase.call();
    return result.fold((_) => null, (PrayerAlarmCapability c) => c);
  }

  Future<bool> _loadLocationPermission() async {
    final Either<Failure, bool> result =
        await _checkLocationPermissionUseCase.call();
    return result.fold((_) => false, (bool granted) => granted);
  }

  Future<void> requestLocationPermission() async {
    await _requestLocationPermissionUseCase.call();
    await checkCapability();
  }

  Future<void> requestExactAlarmPermission() async {
    await _requestExactAlarmUseCase.call();
    final result = await _checkCapabilityUseCase.call();
    result.fold(
      (_) {},
      (capability) => emit(state.copyWith(capability: capability)),
    );
  }

  Future<void> requestNotificationPermission() async {
    await _requestNotificationUseCase.call();
    final result = await _checkCapabilityUseCase.call();
    result.fold(
      (_) {},
      (capability) => emit(state.copyWith(capability: capability)),
    );
  }

  /// Opens the system dialog asking the user to whitelist the app from
  /// battery-optimisation Doze. The dialog is fire-and-forget; we re-check
  /// the capability when the user returns to the app.
  Future<void> requestIgnoreBatteryOptimizations() async {
    await _adhanPlayer.requestIgnoreBatteryOptimizations();
    final result = await _checkCapabilityUseCase.call();
    result.fold(
      (_) {},
      (capability) => emit(state.copyWith(capability: capability)),
    );
  }
}

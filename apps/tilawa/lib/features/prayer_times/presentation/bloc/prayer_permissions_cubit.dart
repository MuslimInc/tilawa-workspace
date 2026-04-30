import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/check_prayer_alarm_capability_use_case.dart';
import '../../domain/usecases/request_exact_alarm_permission_use_case.dart';
import '../../domain/usecases/request_notification_permission_use_case.dart';
import '../../domain/value_objects/prayer_alarm_capability.dart';

part 'prayer_permissions_cubit.freezed.dart';

@freezed
abstract class PrayerPermissionsState with _$PrayerPermissionsState {
  const factory PrayerPermissionsState({PrayerAlarmCapability? capability}) =
      _PrayerPermissionsState;
}

@injectable
class PrayerPermissionsCubit extends Cubit<PrayerPermissionsState> {
  PrayerPermissionsCubit(
    this._checkCapabilityUseCase,
    this._requestExactAlarmUseCase,
    this._requestNotificationUseCase,
  ) : super(const PrayerPermissionsState());

  final CheckPrayerAlarmCapabilityUseCase _checkCapabilityUseCase;
  final RequestExactAlarmPermissionUseCase _requestExactAlarmUseCase;
  final RequestNotificationPermissionUseCase _requestNotificationUseCase;

  Future<void> checkCapability() async {
    final result = await _checkCapabilityUseCase.call();
    result.fold(
      (_) {}, // Ignoring failure to fetch capability (defaults to null)
      (capability) => emit(state.copyWith(capability: capability)),
    );
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
}

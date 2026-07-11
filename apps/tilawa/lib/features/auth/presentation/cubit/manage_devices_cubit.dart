import 'package:equatable/equatable.dart';
// ignore_for_file: avoid_public_fields, prefer_void_public_methods_on_cubit
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/features/auth/domain/entities/registered_device.dart';
import 'package:tilawa/features/auth/domain/repositories/device_registry_repository.dart';

enum ManageDevicesStatus { initial, loading, loaded, error }

class ManageDevicesState extends Equatable {
  const ManageDevicesState({
    this.status = ManageDevicesStatus.initial,
    this.devices = const [],
    this.currentDeviceId,
    this.busyDeviceIds = const {},
    this.signingOutOthers = false,
  });

  final ManageDevicesStatus status;
  final List<RegisteredDevice> devices;
  final String? currentDeviceId;

  /// Device ids with an in-flight "sign out this device" action.
  final Set<String> busyDeviceIds;
  final bool signingOutOthers;

  bool isCurrent(RegisteredDevice device) => device.deviceId == currentDeviceId;

  /// Active (non-revoked) devices other than the current one.
  List<RegisteredDevice> get otherActiveDevices => devices
      .where((d) => !d.isRevoked && d.deviceId != currentDeviceId)
      .toList();

  bool get hasOtherActiveDevices => otherActiveDevices.isNotEmpty;

  ManageDevicesState copyWith({
    ManageDevicesStatus? status,
    List<RegisteredDevice>? devices,
    String? currentDeviceId,
    Set<String>? busyDeviceIds,
    bool? signingOutOthers,
  }) {
    return ManageDevicesState(
      status: status ?? this.status,
      devices: devices ?? this.devices,
      currentDeviceId: currentDeviceId ?? this.currentDeviceId,
      busyDeviceIds: busyDeviceIds ?? this.busyDeviceIds,
      signingOutOthers: signingOutOthers ?? this.signingOutOthers,
    );
  }

  @override
  List<Object?> get props => [
    status,
    devices,
    currentDeviceId,
    busyDeviceIds,
    signingOutOthers,
  ];
}

/// Drives the Manage Devices screen: loads the registry, signs out a single
/// device, or signs out all other devices. Reads are one-shot; every write is
/// followed by a refresh so the list reflects server truth.
@injectable
class ManageDevicesCubit extends Cubit<ManageDevicesState> {
  ManageDevicesCubit(this._repository) : super(const ManageDevicesState());

  final DeviceRegistryRepository _repository;

  Future<void> load(String userId) async {
    emit(state.copyWith(status: ManageDevicesStatus.loading));
    final currentId = await _repository.currentDeviceId();
    final result = await _repository.getDevices(userId);
    result.fold(
      (_) => emit(
        state.copyWith(
          status: ManageDevicesStatus.error,
          currentDeviceId: currentId,
        ),
      ),
      (devices) => emit(
        state.copyWith(
          status: ManageDevicesStatus.loaded,
          devices: devices,
          currentDeviceId: currentId,
        ),
      ),
    );
  }

  /// Signs out one device, then refreshes. Never targets the current device.
  Future<void> signOutDevice(String userId, String deviceId) async {
    if (deviceId == state.currentDeviceId) {
      return;
    }
    emit(state.copyWith(busyDeviceIds: {...state.busyDeviceIds, deviceId}));
    final result = await _repository.revokeDevice(deviceId);
    final busy = {...state.busyDeviceIds}..remove(deviceId);
    emit(state.copyWith(busyDeviceIds: busy));
    final succeeded = result.isRight();
    if (succeeded) {
      await load(userId);
    } else {
      emit(state.copyWith(status: ManageDevicesStatus.error));
    }
  }

  /// Signs out all other devices, then refreshes.
  Future<void> signOutOtherDevices(String userId) async {
    final currentId =
        state.currentDeviceId ?? await _repository.currentDeviceId();
    emit(state.copyWith(signingOutOthers: true, currentDeviceId: currentId));
    final result = await _repository.signOutOtherDevices(currentId);
    emit(state.copyWith(signingOutOthers: false));
    final succeeded = result.isRight();
    if (succeeded) {
      await load(userId);
    } else {
      emit(state.copyWith(status: ManageDevicesStatus.error));
    }
  }
}

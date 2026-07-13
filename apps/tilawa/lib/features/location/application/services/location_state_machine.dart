import '../../domain/models/location_state.dart';

class LocationStateMachine {
  LocationStateMachineState _state = const LocationStateMachineState(
    status: LocationStateStatus.permissionNotRequested,
    isManualOverride: false,
  );

  LocationStateMachineState get state => _state;

  void handlePermissionDenied() {
    _state = _state.copyWith(status: LocationStateStatus.denied);
  }

  void handlePermissionPermanentlyDenied() {
    _state = _state.copyWith(status: LocationStateStatus.permanentlyDenied);
  }

  void handleManualOverrideSelected() {
    _state = _state.copyWith(
      status: LocationStateStatus.manualLocationSelected,
      isManualOverride: true,
    );
  }

  void resetToAutomatic() {
    _state = _state.copyWith(
      status: LocationStateStatus.permissionNotRequested,
      isManualOverride: false,
    );
  }
}

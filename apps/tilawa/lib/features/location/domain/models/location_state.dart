enum LocationStateStatus {
  permissionNotRequested,
  grantedPrecise,
  grantedApproximate,
  denied,
  permanentlyDenied,
  locationServicesDisabled,
  lookupTimeout,
  cachedValidLocation,
  cachedStaleLocation,
  manualLocationSelected,
  offlineWithCachedLocation,
  offlineWithoutCachedLocation,
  timezoneMissingOrInvalid,
  cityNameAmbiguity,
}

class LocationStateMachineState {
  final LocationStateStatus status;
  final bool isManualOverride;

  const LocationStateMachineState({
    required this.status,
    required this.isManualOverride,
  });

  LocationStateMachineState copyWith({
    LocationStateStatus? status,
    bool? isManualOverride,
  }) {
    return LocationStateMachineState(
      status: status ?? this.status,
      isManualOverride: isManualOverride ?? this.isManualOverride,
    );
  }
}

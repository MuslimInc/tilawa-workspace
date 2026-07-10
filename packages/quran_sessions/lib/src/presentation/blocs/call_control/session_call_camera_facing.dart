/// Local camera lens direction during an in-app video call.
enum SessionCallCameraFacing {
  front,
  back;

  SessionCallCameraFacing get opposite => switch (this) {
    SessionCallCameraFacing.front => SessionCallCameraFacing.back,
    SessionCallCameraFacing.back => SessionCallCameraFacing.front,
  };
}

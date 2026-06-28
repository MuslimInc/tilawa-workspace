export type DevicePlatform = "android" | "ios" | "web";

export type DeviceRegistrationMode = "explicit_sign_in" | "passive_sync";

export type DeviceRegistrationStatus =
  | "registered"
  | "updated_same_device"
  | "stale_device_rejected"
  | "requires_explicit_sign_in";

export interface SessionState {
  epoch: number;
  activeDeviceId: string;
}

export interface RegisterDeviceInput {
  deviceId: string;
  fcmToken?: string;
  platform: DevicePlatform;
  appVersion?: string;
  registrationMode: DeviceRegistrationMode;
  signOut?: boolean;
}

export interface RegisterDevicePlan {
  status: DeviceRegistrationStatus;
  deviceChanged: boolean;
  nextEpoch: number;
  nextActiveDeviceId: string;
  clearActiveSession: boolean;
  writeActiveDevice: boolean;
  noOp: boolean;
}

export function planDeviceRegistration(
  session: SessionState | null,
  input: RegisterDeviceInput,
): RegisterDevicePlan {
  const currentEpoch = session?.epoch ?? 0;
  const currentDeviceId = session?.activeDeviceId ?? "";

  if (input.signOut === true) {
    return planSignOut(currentEpoch, currentDeviceId, input.deviceId);
  }

  if (input.registrationMode === "passive_sync") {
    return planPassiveSync(currentEpoch, currentDeviceId, input.deviceId);
  }

  return planExplicitSignIn(currentEpoch, currentDeviceId, input.deviceId);
}

function planSignOut(
  currentEpoch: number,
  currentDeviceId: string,
  requestingDeviceId: string,
): RegisterDevicePlan {
  if (currentDeviceId.length === 0) {
    return noOpPlan("requires_explicit_sign_in", currentEpoch, currentDeviceId);
  }

  if (requestingDeviceId.trim() !== currentDeviceId) {
    return noOpPlan("stale_device_rejected", currentEpoch, currentDeviceId);
  }

  return {
    status: "updated_same_device",
    deviceChanged: false,
    nextEpoch: currentEpoch,
    nextActiveDeviceId: currentDeviceId,
    clearActiveSession: true,
    writeActiveDevice: false,
    noOp: false,
  };
}

function planPassiveSync(
  currentEpoch: number,
  currentDeviceId: string,
  requestingDeviceId: string,
): RegisterDevicePlan {
  if (currentDeviceId.length === 0) {
    return noOpPlan("requires_explicit_sign_in", currentEpoch, currentDeviceId);
  }

  if (requestingDeviceId !== currentDeviceId) {
    return noOpPlan("stale_device_rejected", currentEpoch, currentDeviceId);
  }

  return {
    status: "updated_same_device",
    deviceChanged: false,
    nextEpoch: currentEpoch,
    nextActiveDeviceId: currentDeviceId,
    clearActiveSession: false,
    writeActiveDevice: true,
    noOp: false,
  };
}

function planExplicitSignIn(
  currentEpoch: number,
  currentDeviceId: string,
  requestingDeviceId: string,
): RegisterDevicePlan {
  const deviceChanged =
    currentDeviceId.length === 0 || requestingDeviceId !== currentDeviceId;

  return {
    status: deviceChanged ? "registered" : "updated_same_device",
    deviceChanged,
    nextEpoch: deviceChanged ? currentEpoch + 1 : currentEpoch,
    nextActiveDeviceId: requestingDeviceId,
    clearActiveSession: false,
    writeActiveDevice: true,
    noOp: false,
  };
}

function noOpPlan(
  status: DeviceRegistrationStatus,
  currentEpoch: number,
  currentDeviceId: string,
): RegisterDevicePlan {
  return {
    status,
    deviceChanged: false,
    nextEpoch: currentEpoch,
    nextActiveDeviceId: currentDeviceId,
    clearActiveSession: false,
    writeActiveDevice: false,
    noOp: true,
  };
}

export function readServerSessionEpoch(
  data: Record<string, unknown> | undefined,
): number {
  const session = data?.session as { epoch?: unknown } | undefined;
  const raw = session?.epoch;
  if (typeof raw === "number" && Number.isFinite(raw)) {
    return raw;
  }
  return 0;
}

export function assertClientSessionEpoch(
  clientEpoch: unknown,
  serverEpoch: number,
): void {
  const parsed =
    typeof clientEpoch === "number"
      ? clientEpoch
      : typeof clientEpoch === "string"
        ? Number(clientEpoch)
        : Number.NaN;

  if (!Number.isFinite(parsed)) {
    throw new Error("session_epoch_required");
  }

  if (parsed !== serverEpoch) {
    throw new Error("session_epoch_stale");
  }
}

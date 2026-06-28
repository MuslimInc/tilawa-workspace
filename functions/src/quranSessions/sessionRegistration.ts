export type DevicePlatform = "android" | "ios" | "web";

export interface SessionState {
  epoch: number;
  activeDeviceId: string;
}

export interface NotificationsState {
  activeFcmToken: string | null;
}

export interface RegisterDeviceInput {
  deviceId: string;
  fcmToken: string;
  platform: DevicePlatform;
  appVersion?: string;
  signOut?: boolean;
}

export interface RegisterDevicePlan {
  deviceChanged: boolean;
  nextEpoch: number;
  nextActiveDeviceId: string;
  clearTokenOnly: boolean;
  /** Stale-device sign-out or missing deviceId — leave server session untouched. */
  noOp: boolean;
}

export function planDeviceRegistration(
  session: SessionState | null,
  input: RegisterDeviceInput,
): RegisterDevicePlan {
  const currentEpoch = session?.epoch ?? 0;
  const currentDeviceId = session?.activeDeviceId ?? "";

  if (input.signOut === true) {
    const requestingDeviceId = input.deviceId.trim();
    const isActiveDevice =
      requestingDeviceId.length > 0 &&
      currentDeviceId.length > 0 &&
      requestingDeviceId === currentDeviceId;

    if (!isActiveDevice) {
      return {
        deviceChanged: false,
        nextEpoch: currentEpoch,
        nextActiveDeviceId: currentDeviceId,
        clearTokenOnly: false,
        noOp: true,
      };
    }

    return {
      deviceChanged: false,
      nextEpoch: currentEpoch,
      nextActiveDeviceId: currentDeviceId,
      clearTokenOnly: true,
      noOp: false,
    };
  }

  const deviceChanged =
    input.deviceId.length > 0 && input.deviceId !== currentDeviceId;

  return {
    deviceChanged,
    nextEpoch: deviceChanged ? currentEpoch + 1 : currentEpoch,
    nextActiveDeviceId: input.deviceId,
    clearTokenOnly: false,
    noOp: false,
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

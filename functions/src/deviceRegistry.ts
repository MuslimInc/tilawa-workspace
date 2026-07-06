import type { FieldValue } from "firebase-admin/firestore";

import type { DevicePlatform } from "./quranSessions/sessionRegistration";

/**
 * Non-exclusive device registry — ADR-008 Phase 0.
 *
 * Each signed-in device gets its own document at
 * `users/{uid}/devices/{deviceId}`. Unlike the legacy exclusive
 * `users/{uid}.session.activeDeviceId`, many device docs may exist concurrently
 * for the same user; this collection is the source of truth for FCM fan-out and
 * the future "Manage Devices" screen.
 *
 * Writes are **Cloud-Functions-only** (Admin SDK). Clients may read their own
 * devices but never write this collection — enforced by `firestore.rules`.
 *
 * This module is schema + pure helpers only. No Firestore writes happen here;
 * `registerActiveDevice` performs the actual upsert (behind
 * `deviceRegistryWriteEnabled`) in a later change.
 */

/**
 * Soft cap on concurrently registered devices per user. Reaching the cap does
 * **not** force a logout or block registration; the client surfaces the Manage
 * Devices flow so the user can remove an old device. Auto-eviction of the
 * oldest device is a possible future refinement, not the decided behavior.
 */
export const MAX_REGISTERED_DEVICES = 5;

/**
 * Minimum interval between `lastSeenAt` writes for a given device, to avoid
 * write churn on frequent passive syncs (see plan §9). Callers compare the
 * stored `lastSeenAt` against `now` before writing.
 */
export const DEVICE_LAST_SEEN_MIN_INTERVAL_MS = 6 * 60 * 60 * 1000; // 6 hours

/** Firestore subcollection name under `users/{uid}`. */
export const DEVICES_SUBCOLLECTION = "devices";

/**
 * Shape of a `users/{uid}/devices/{deviceId}` document.
 *
 * `deviceInfo` carries only the sanitized allowlist produced by
 * `sanitizeDeviceInfo` (`registerActiveDevice.ts`) — never raw identifiers.
 * Timestamp fields are `FieldValue` (server timestamps) on write and
 * `Timestamp` on read; typed loosely here to serve both.
 */
export interface DeviceRegistryDoc {
  platform: DevicePlatform;
  fcmToken?: string;
  appVersion?: string;
  deviceInfo?: Record<string, string>;
  lastSeenAt: unknown; // Timestamp on read, FieldValue.serverTimestamp() on write
  createdAt: unknown; // set once, on first registration
  revokedAt?: unknown | null; // set by "sign out this device"; null/absent when active
}

/** Relative Firestore path to a device doc; joins to the `users/{uid}` ref. */
export function deviceDocPath(deviceId: string): string {
  return `${DEVICES_SUBCOLLECTION}/${deviceId}`;
}

export interface BuildDeviceRegistryDocInput {
  platform: DevicePlatform;
  fcmToken?: string;
  appVersion?: string;
  /** Already sanitized via `sanitizeDeviceInfo`. */
  deviceInfo?: Record<string, string>;
  /** Whether the device doc already exists (controls `createdAt`). */
  existing: boolean;
}

/**
 * Builds the merge payload for a `users/{uid}/devices/{deviceId}` upsert.
 *
 * Pure: takes the server-timestamp sentinel `now` and returns the object to
 * `set(..., { merge: true })`. Only sets `createdAt` on first registration and
 * clears any prior `revokedAt` so re-registering reactivates a device. Optional
 * fields are omitted when absent so they never overwrite existing values with
 * `undefined`.
 */
export function buildDeviceRegistryDoc(
  input: BuildDeviceRegistryDocInput,
  now: FieldValue,
): Record<string, unknown> {
  const doc: Record<string, unknown> = {
    platform: input.platform,
    lastSeenAt: now,
    revokedAt: null,
  };
  if (!input.existing) {
    doc.createdAt = now;
  }
  if (input.fcmToken) {
    doc.fcmToken = input.fcmToken;
  }
  if (input.appVersion) {
    doc.appVersion = input.appVersion;
  }
  if (input.deviceInfo) {
    doc.deviceInfo = input.deviceInfo;
  }
  return doc;
}

/**
 * Whether adding `candidateDeviceId` would exceed {@link MAX_REGISTERED_DEVICES}.
 * `existingDeviceIds` are the caller's currently active (non-revoked) device ids.
 * Re-registering an already-known device never counts as exceeding the cap.
 */
export function isDeviceCapExceeded(
  existingDeviceIds: readonly string[],
  candidateDeviceId: string,
): boolean {
  if (existingDeviceIds.includes(candidateDeviceId)) {
    return false;
  }
  return existingDeviceIds.length >= MAX_REGISTERED_DEVICES;
}

/**
 * Whether a `lastSeenAt` write should be skipped because the last one is more
 * recent than {@link DEVICE_LAST_SEEN_MIN_INTERVAL_MS}. Returns `false` (i.e.
 * do write) when there is no prior timestamp.
 */
export function shouldSkipLastSeenWrite(
  previousLastSeenMs: number | null,
  nowMs: number,
): boolean {
  if (previousLastSeenMs == null) {
    return false;
  }
  return nowMs - previousLastSeenMs < DEVICE_LAST_SEEN_MIN_INTERVAL_MS;
}

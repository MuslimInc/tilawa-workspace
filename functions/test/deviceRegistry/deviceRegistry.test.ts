import test from "node:test";
import assert from "node:assert/strict";
import type { FieldValue } from "firebase-admin/firestore";

import {
  buildDeviceRegistryDoc,
  DEVICE_LAST_SEEN_MIN_INTERVAL_MS,
  isDeviceCapExceeded,
  MAX_REGISTERED_DEVICES,
  shouldSkipLastSeenWrite,
} from "../../src/deviceRegistry";

// Sentinel standing in for FieldValue.serverTimestamp() — buildDeviceRegistryDoc
// is pure and only stores the reference, so identity comparison is enough.
const NOW = { __serverTimestamp: true } as unknown as FieldValue;

test("buildDeviceRegistryDoc: new device sets createdAt and clears revokedAt", () => {
  const doc = buildDeviceRegistryDoc(
    { platform: "android", existing: false },
    NOW,
  );
  assert.equal(doc.platform, "android");
  assert.equal(doc.lastSeenAt, NOW);
  assert.equal(doc.createdAt, NOW);
  assert.equal(doc.revokedAt, null);
});

test("buildDeviceRegistryDoc: existing device omits createdAt", () => {
  const doc = buildDeviceRegistryDoc(
    { platform: "ios", existing: true },
    NOW,
  );
  assert.equal("createdAt" in doc, false);
  assert.equal(doc.lastSeenAt, NOW);
  // Re-registering always clears revokedAt (reactivates a signed-out device).
  assert.equal(doc.revokedAt, null);
});

test("buildDeviceRegistryDoc: omits absent optional fields", () => {
  const doc = buildDeviceRegistryDoc(
    { platform: "android", existing: false },
    NOW,
  );
  assert.equal("fcmToken" in doc, false);
  assert.equal("appVersion" in doc, false);
  assert.equal("deviceInfo" in doc, false);
});

test("buildDeviceRegistryDoc: includes provided optional fields", () => {
  const doc = buildDeviceRegistryDoc(
    {
      platform: "android",
      existing: false,
      fcmToken: "tok-a",
      appVersion: "2.0.0",
      deviceInfo: { manufacturer: "OPPO", model: "A98" },
    },
    NOW,
  );
  assert.equal(doc.fcmToken, "tok-a");
  assert.equal(doc.appVersion, "2.0.0");
  assert.deepEqual(doc.deviceInfo, { manufacturer: "OPPO", model: "A98" });
});

test("isDeviceCapExceeded: false below the cap", () => {
  assert.equal(isDeviceCapExceeded(["a", "b", "c"], "d"), false);
});

test("isDeviceCapExceeded: true when adding a new device at the cap", () => {
  const atCap = Array.from(
    { length: MAX_REGISTERED_DEVICES },
    (_unused, i) => `d${i}`,
  );
  assert.equal(isDeviceCapExceeded(atCap, "new-device"), true);
});

test("isDeviceCapExceeded: re-registering a known device never exceeds", () => {
  const atCap = Array.from(
    { length: MAX_REGISTERED_DEVICES },
    (_unused, i) => `d${i}`,
  );
  assert.equal(isDeviceCapExceeded(atCap, "d0"), false);
});

test("shouldSkipLastSeenWrite: never skips when there is no prior timestamp", () => {
  assert.equal(shouldSkipLastSeenWrite(null, 1_000_000), false);
});

test("shouldSkipLastSeenWrite: skips within the min interval", () => {
  const now = 10_000_000;
  const recent = now - (DEVICE_LAST_SEEN_MIN_INTERVAL_MS - 1);
  assert.equal(shouldSkipLastSeenWrite(recent, now), true);
});

test("shouldSkipLastSeenWrite: writes once the interval has elapsed", () => {
  const now = 10_000_000;
  const old = now - DEVICE_LAST_SEEN_MIN_INTERVAL_MS;
  assert.equal(shouldSkipLastSeenWrite(old, now), false);
});

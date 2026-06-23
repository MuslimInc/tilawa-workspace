import test from "node:test";
import assert from "node:assert/strict";

import {
  decideFcmTokenMigration,
  resolveRaceWinnerDevice,
} from "../../src/migration/fcmTokenMigration";
import {
  planDeviceRegistration,
  readServerSessionEpoch,
} from "../../src/quranSessions/sessionRegistration";

test("decideFcmTokenMigration skips when embedded token already exists", () => {
  const decision = decideFcmTokenMigration({
    existingActiveToken: "tok-live",
    legacyDocs: [{ id: "legacy", createdAtMillis: 100 }],
  });

  assert.equal(decision.action, "skip");
  assert.equal(decision.reason, "embedded_token_already_set");
});

test("decideFcmTokenMigration picks newest legacy token", () => {
  const decision = decideFcmTokenMigration({
    legacyDocs: [
      { id: "old", token: "tok-old", platform: "ios", createdAtMillis: 10 },
      { id: "new", token: "tok-new", platform: "android", createdAtMillis: 99 },
    ],
  });

  assert.equal(decision.action, "set");
  assert.equal(decision.selectedToken, "tok-new");
  assert.equal(decision.platform, "android");
  assert.equal(decision.legacyDocCount, 2);
});

test("decideFcmTokenMigration skips users without legacy tokens", () => {
  const decision = decideFcmTokenMigration({ legacyDocs: [] });
  assert.equal(decision.action, "skip");
  assert.equal(decision.reason, "no_legacy_tokens");
});

test("decideFcmTokenMigration is idempotent for same input", () => {
  const input = {
    legacyDocs: [
      { id: "a", token: "tok-a", createdAtMillis: 1 },
      { id: "b", token: "tok-b", createdAtMillis: 2 },
    ],
  };
  assert.deepEqual(
    decideFcmTokenMigration(input),
    decideFcmTokenMigration(input),
  );
});

test("resolveRaceWinnerDevice keeps last registration", () => {
  assert.equal(
    resolveRaceWinnerDevice([
      { deviceId: "device-a", order: 1 },
      { deviceId: "device-b", order: 2 },
    ]),
    "device-b",
  );
});

test("planDeviceRegistration first device bumps epoch from zero to one", () => {
  const plan = planDeviceRegistration(null, {
    deviceId: "device-a",
    fcmToken: "tok-a",
    platform: "android",
  });

  assert.equal(plan.nextEpoch, 1);
  assert.equal(plan.deviceChanged, true);
});

test("planDeviceRegistration re-login same device after supersede", () => {
  const first = planDeviceRegistration(null, {
    deviceId: "device-a",
    fcmToken: "tok-a",
    platform: "android",
  });
  const second = planDeviceRegistration(
    { epoch: first.nextEpoch, activeDeviceId: first.nextActiveDeviceId },
    {
      deviceId: "device-b",
      fcmToken: "tok-b",
      platform: "ios",
    },
  );
  const third = planDeviceRegistration(
    { epoch: second.nextEpoch, activeDeviceId: second.nextActiveDeviceId },
    {
      deviceId: "device-a",
      fcmToken: "tok-a2",
      platform: "android",
    },
  );

  assert.equal(first.nextEpoch, 1);
  assert.equal(second.nextEpoch, 2);
  assert.equal(third.nextEpoch, 3);
  assert.equal(third.nextActiveDeviceId, "device-a");
});

test("readServerSessionEpoch handles invalid epoch values", () => {
  assert.equal(readServerSessionEpoch({ session: { epoch: "bad" } }), 0);
  assert.equal(readServerSessionEpoch({ session: { epoch: Number.NaN } }), 0);
});

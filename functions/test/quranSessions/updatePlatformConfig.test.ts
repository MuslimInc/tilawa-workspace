import test from "node:test";
import assert from "node:assert/strict";
import { HttpsError } from "firebase-functions/v2/https";

import { validateUpdatePlatformConfig, UpdatePlatformConfigRequest } from "../../src/quranSessions/updatePlatformConfig";

test("validateUpdatePlatformConfig rejects missing booleans", () => {
  assert.throws(
    () => validateUpdatePlatformConfig({} as any),
    (err: unknown) => {
      assert.ok(err instanceof HttpsError);
      assert.equal((err as HttpsError).code, "invalid-argument");
      return true;
    }
  );
});

test("validateUpdatePlatformConfig accepts valid config", () => {
  const validData: UpdatePlatformConfigRequest = {
    quranSessionsEnabled: true,
    studentEntryEnabled: true,
    bookingEnabled: true,
    sessionMode: "videoOnly",
    bookingMode: "autoConfirm",
    defaultJoinWindowLeadMs: 300000,
    defaultTutorApprovalSlaMs: 3600000,
    defaultMinBookingNoticeMs: 1800000,
    defaultMaxUpcomingPerStudent: 3,
  };
  
  assert.doesNotThrow(() => validateUpdatePlatformConfig(validData));
});

test("validateUpdatePlatformConfig accepts legacy booking mode alias", () => {
  const validData: Omit<UpdatePlatformConfigRequest, "bookingMode"> = {
    quranSessionsEnabled: true,
    studentEntryEnabled: true,
    bookingEnabled: true,
    sessionMode: "videoOnly",
    defaultBookingMode: "autoConfirm",
    defaultJoinWindowLeadMs: 300000,
    defaultTutorApprovalSlaMs: 3600000,
    defaultMinBookingNoticeMs: 1800000,
    defaultMaxUpcomingPerStudent: 3,
  };

  assert.doesNotThrow(() => validateUpdatePlatformConfig(validData));
});

test("validateUpdatePlatformConfig rejects invalid sessionMode", () => {
  const data: any = {
    quranSessionsEnabled: true,
    studentEntryEnabled: true,
    bookingEnabled: true,
    sessionMode: "audioOnly", // Invalid
    bookingMode: "autoConfirm",
    defaultJoinWindowLeadMs: 300000,
    defaultTutorApprovalSlaMs: 3600000,
    defaultMinBookingNoticeMs: 1800000,
    defaultMaxUpcomingPerStudent: 3,
  };
  
  assert.throws(
    () => validateUpdatePlatformConfig(data),
    /sessionMode must be 'videoOnly'/
  );
});

test("validateUpdatePlatformConfig rejects negative defaultJoinWindowLeadMs", () => {
  const data: any = {
    quranSessionsEnabled: true,
    studentEntryEnabled: true,
    bookingEnabled: true,
    sessionMode: "videoOnly",
    bookingMode: "autoConfirm",
    defaultJoinWindowLeadMs: -1, // Invalid
    defaultTutorApprovalSlaMs: 3600000,
    defaultMinBookingNoticeMs: 1800000,
    defaultMaxUpcomingPerStudent: 3,
  };
  
  assert.throws(
    () => validateUpdatePlatformConfig(data),
    /defaultJoinWindowLeadMs must be a finite number >= 0/
  );
});

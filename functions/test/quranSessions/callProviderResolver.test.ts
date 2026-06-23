import test from "node:test";
import assert from "node:assert/strict";
import { HttpsError } from "firebase-functions/v2/https";

import {
  mapCallProviderResolverError,
  resolveCallProviderForBooking,
} from "../../src/quranSessions/callProviderResolver";

test("resolveCallProviderForBooking external uses teacher externalMeetingUrl", () => {
  const resolved = resolveCallProviderForBooking({
    callType: "externalMeeting",
    sessionId: "session1",
    teacherProfile: {
      externalMeetingUrl: "https://meet.example.com/teacher",
    },
    platformConfig: {},
  });
  assert.equal(resolved.callProvider, "external");
  assert.equal(resolved.meetingLink, "https://meet.example.com/teacher");
  assert.equal(resolved.providerSessionId, null);
});

test("resolveCallProviderForBooking external reads legacy meeting_link field", () => {
  const resolved = resolveCallProviderForBooking({
    callType: "externalMeeting",
    sessionId: "session1",
    teacherProfile: {
      meeting_link: "https://meet.example.com/legacy",
    },
    platformConfig: {},
  });
  assert.equal(resolved.meetingLink, "https://meet.example.com/legacy");
});

test("resolveCallProviderForBooking voice uses mock when enabledCallProviders missing", () => {
  const resolved = resolveCallProviderForBooking({
    callType: "voiceCall",
    sessionId: "session1",
    teacherProfile: {},
    platformConfig: {},
  });
  assert.equal(resolved.callProvider, "mock");
  assert.equal(resolved.providerSessionId, "session1");
});

test("resolveCallProviderForBooking voice rejects malformed enabledCallProviders", () => {
  assert.throws(
    () =>
      resolveCallProviderForBooking({
        callType: "videoCall",
        sessionId: "session1",
        teacherProfile: {},
        platformConfig: { enabledCallProviders: "external,mock" },
      }),
    (error: unknown) =>
      error instanceof Error && error.message === "invalid_enabled_call_providers",
  );
});

test("mapCallProviderResolverError maps malformed config to unsupported_call_provider", () => {
  assert.throws(
    () =>
      mapCallProviderResolverError(
        new Error("invalid_enabled_call_providers"),
        "mock",
      ),
    (error: unknown) => {
      assert.ok(error instanceof HttpsError);
      assert.equal(error.code, "failed-precondition");
      assert.deepEqual(error.details, {
        code: "unsupported_call_provider",
        callProvider: "mock",
      });
      return true;
    },
  );
});

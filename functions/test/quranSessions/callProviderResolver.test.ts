import test from "node:test";
import assert from "node:assert/strict";

import {
  agoraUidForFirebaseUser,
  buildAgoraRtcToken,
  readAgoraRtcCredentials,
} from "../../src/quranSessions/agoraTokenService";
import {
  parseEnabledCallProviders,
  resolveCallProviderForBooking,
  resolveRtcProviderForBooking,
} from "../../src/quranSessions/callProviderResolver";

test("resolveCallProviderForBooking voice picks agora when enabled", () => {
  const resolved = resolveCallProviderForBooking({
    callType: "voiceCall",
    sessionId: "session_agora",
    teacherProfile: {},
    platformConfig: {
      enabledCallProviders: ["external", "mock", "agora"],
    },
  });
  assert.equal(resolved.callProvider, "agora");
  assert.equal(resolved.providerSessionId, "session_agora");
  assert.equal(resolved.joinToken, null);
});

test("resolveCallProviderForBooking voice keeps mock when agora disabled", () => {
  const resolved = resolveCallProviderForBooking({
    callType: "videoCall",
    sessionId: "session_mock",
    teacherProfile: {},
    platformConfig: {
      enabledCallProviders: ["external", "mock"],
    },
  });
  assert.equal(resolved.callProvider, "mock");
});

test("resolveCallProviderForBooking honors enabled client rtc hint", () => {
  const resolved = resolveCallProviderForBooking({
    callType: "voiceCall",
    sessionId: "session_webrtc",
    teacherProfile: {},
    platformConfig: {
      enabledCallProviders: ["external", "mock", "agora", "webrtc"],
    },
    clientCallProvider: "webrtc",
  });
  assert.equal(resolved.callProvider, "webrtc");
});

test("resolveCallProviderForBooking rejects disabled client rtc hint", () => {
  assert.throws(
    () =>
      resolveCallProviderForBooking({
        callType: "voiceCall",
        sessionId: "session1",
        teacherProfile: {},
        platformConfig: { enabledCallProviders: ["external", "mock"] },
        clientCallProvider: "agora",
      }),
    (error: unknown) =>
      error instanceof Error && error.message === "unsupported_call_provider",
  );
});

test("parseEnabledCallProviders accepts agora and webrtc entries", () => {
  const enabled = parseEnabledCallProviders([
    "external",
    "mock",
    "agora",
    "webrtc",
  ]);
  assert.equal(enabled.has("agora"), true);
  assert.equal(enabled.has("webrtc"), true);
});

test("resolveRtcProviderForBooking prefers agora over mock by default", () => {
  const provider = resolveRtcProviderForBooking({
    enabledRtcProviders: new Set(["mock", "agora"]),
  });
  assert.equal(provider, "agora");
});

test("agoraUidForFirebaseUser is stable and non-zero", () => {
  const uid = agoraUidForFirebaseUser("student_abc");
  assert.equal(uid, agoraUidForFirebaseUser("student_abc"));
  assert.notEqual(uid, 0);
});

test("buildAgoraRtcToken returns string for test credentials", () => {
  const credentials = {
    appId: "0123456789abcdef0123456789abcdef",
    appCertificate: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
  };
  const token = buildAgoraRtcToken({
    credentials,
    channelName: "session_test",
    uid: 42,
  });
  assert.equal(typeof token, "string");
});

test("readAgoraRtcCredentials returns null when env missing", () => {
  const originalAppId = process.env.AGORA_APP_ID;
  const originalCert = process.env.AGORA_APP_CERTIFICATE;
  delete process.env.AGORA_APP_ID;
  delete process.env.AGORA_APP_CERTIFICATE;
  assert.equal(readAgoraRtcCredentials(), null);
  if (originalAppId != null) {
    process.env.AGORA_APP_ID = originalAppId;
  }
  if (originalCert != null) {
    process.env.AGORA_APP_CERTIFICATE = originalCert;
  }
});

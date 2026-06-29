import test from "node:test";
import assert from "node:assert/strict";

import {
  agoraUidForFirebaseUser,
  buildAgoraRtcToken,
  readAgoraRtcCredentials,
} from "../../src/quranSessions/agoraTokenService";
import {
  buildLiveKitRtcToken,
  readLiveKitRtcCredentials,
} from "../../src/quranSessions/livekitTokenService";
import {
  parseEnabledCallProviders,
  resolveCallProviderForBooking,
  resolveRtcProviderForBooking,
} from "../../src/quranSessions/callProviderResolver";

test("resolveCallProviderForBooking voice picks livekit when enabled", () => {
  const resolved = resolveCallProviderForBooking({
    callType: "voiceCall",
    sessionId: "session_livekit",
    teacherProfile: {},
    platformConfig: {
      enabledCallProviders: ["external", "mock", "livekit"],
    },
  });
  assert.equal(resolved.callProvider, "livekit");
  assert.equal(resolved.providerSessionId, "session_livekit");
  assert.equal(resolved.joinToken, null);
});

test("resolveCallProviderForBooking voice picks agora when livekit disabled", () => {
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
});

test("resolveCallProviderForBooking videoCall picks agora when enabled", () => {
  const resolved = resolveCallProviderForBooking({
    callType: "videoCall",
    sessionId: "session_agora_video",
    teacherProfile: {},
    platformConfig: {
      enabledCallProviders: ["external", "mock", "agora"],
    },
  });
  assert.equal(resolved.callProvider, "agora");
  assert.equal(resolved.providerSessionId, "session_agora_video");
});

test("resolveCallProviderForBooking voice keeps mock when rtc disabled", () => {
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

test("resolveCallProviderForBooking maps legacy webrtc hint to livekit", () => {
  const resolved = resolveCallProviderForBooking({
    callType: "voiceCall",
    sessionId: "session_livekit",
    teacherProfile: {},
    platformConfig: {
      enabledCallProviders: ["external", "mock", "livekit"],
    },
    clientCallProvider: "webrtc",
  });
  assert.equal(resolved.callProvider, "livekit");
});

test("resolveCallProviderForBooking honors enabled client agora hint", () => {
  const resolved = resolveCallProviderForBooking({
    callType: "voiceCall",
    sessionId: "session_agora",
    teacherProfile: {},
    platformConfig: {
      enabledCallProviders: ["external", "mock", "agora", "livekit"],
    },
    clientCallProvider: "agora",
  });
  assert.equal(resolved.callProvider, "agora");
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

test("parseEnabledCallProviders accepts agora and livekit entries", () => {
  const enabled = parseEnabledCallProviders([
    "external",
    "mock",
    "agora",
    "livekit",
  ]);
  assert.equal(enabled.has("agora"), true);
  assert.equal(enabled.has("livekit"), true);
});

test("parseEnabledCallProviders maps legacy webrtc to livekit", () => {
  const enabled = parseEnabledCallProviders([
    "external",
    "mock",
    "webrtc",
  ]);
  assert.equal(enabled.has("livekit"), true);
  assert.equal(enabled.has("webrtc" as never), false);
});

test("resolveRtcProviderForBooking prefers livekit over agora by default", () => {
  const provider = resolveRtcProviderForBooking({
    enabledRtcProviders: new Set(["mock", "agora", "livekit"]),
  });
  assert.equal(provider, "livekit");
});

test("resolveRtcProviderForBooking prefers agora over mock when livekit disabled", () => {
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

test("buildLiveKitRtcToken returns string for test credentials", async () => {
  const credentials = {
    apiKey: "APIKEY123",
    apiSecret: "secret123456789012345678901234567890",
    serverUrl: "wss://project.livekit.cloud",
  };
  const token = await buildLiveKitRtcToken({
    credentials,
    roomName: "session_test",
    identity: "student_abc",
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

test("readLiveKitRtcCredentials returns null when env missing", () => {
  const originalKey = process.env.LIVEKIT_API_KEY;
  const originalSecret = process.env.LIVEKIT_API_SECRET;
  const originalUrl = process.env.LIVEKIT_URL;
  delete process.env.LIVEKIT_API_KEY;
  delete process.env.LIVEKIT_API_SECRET;
  delete process.env.LIVEKIT_URL;
  assert.equal(readLiveKitRtcCredentials(), null);
  if (originalKey != null) {
    process.env.LIVEKIT_API_KEY = originalKey;
  }
  if (originalSecret != null) {
    process.env.LIVEKIT_API_SECRET = originalSecret;
  }
  if (originalUrl != null) {
    process.env.LIVEKIT_URL = originalUrl;
  }
});

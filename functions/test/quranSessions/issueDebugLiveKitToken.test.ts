import test from "node:test";
import assert from "node:assert/strict";

import { buildLiveKitRtcToken } from "../../src/quranSessions/livekitTokenService";
import {
  DEBUG_LIVEKIT_ROOM_NAME,
  issueDebugLiveKitTokenForRequest,
} from "../../src/quranSessions/issueDebugLiveKitToken";

const LIVEKIT_CREDENTIALS = {
  apiKey: "APIKEY123",
  apiSecret: "secret_that_is_at_least_thirty_two_chars_long",
  serverUrl: "wss://project.livekit.cloud",
};

function authRequest(uid: string) {
  return {
    auth: { uid, token: {} },
    data: {},
  };
}

test("issueDebugLiveKitTokenForRequest rejects production distribution", async () => {
  const previous = process.env.TILAWA_DISTRIBUTION;
  process.env.TILAWA_DISTRIBUTION = "play_production";
  try {
    await assert.rejects(
      () =>
        issueDebugLiveKitTokenForRequest(authRequest("user_1"), () =>
          LIVEKIT_CREDENTIALS,
        ),
      (error: { code?: string }) => error.code === "permission-denied",
    );
  } finally {
    if (previous === undefined) {
      delete process.env.TILAWA_DISTRIBUTION;
    } else {
      process.env.TILAWA_DISTRIBUTION = previous;
    }
  }
});

test("issueDebugLiveKitTokenForRequest rejects unauthenticated callers", async () => {
  await assert.rejects(
    () =>
      issueDebugLiveKitTokenForRequest({ auth: null }, () => LIVEKIT_CREDENTIALS),
    (error: { code?: string }) => error.code === "unauthenticated",
  );
});

test("issueDebugLiveKitTokenForRequest returns LiveKit credentials", async () => {
  const previous = process.env.TILAWA_DISTRIBUTION;
  process.env.TILAWA_DISTRIBUTION = "staging";
  try {
    const uid = "qa_user_1";
    const result = await issueDebugLiveKitTokenForRequest(
      authRequest(uid),
      () => LIVEKIT_CREDENTIALS,
    );

    assert.equal(result.callProvider, "livekit");
    assert.equal(result.channelId, DEBUG_LIVEKIT_ROOM_NAME);
    assert.equal(result.uid, 0);
    assert.equal(result.appId, LIVEKIT_CREDENTIALS.serverUrl);
    assert.equal(
      result.token,
      await buildLiveKitRtcToken({
        credentials: LIVEKIT_CREDENTIALS,
        roomName: DEBUG_LIVEKIT_ROOM_NAME,
        identity: uid,
      }),
    );
  } finally {
    if (previous === undefined) {
      delete process.env.TILAWA_DISTRIBUTION;
    } else {
      process.env.TILAWA_DISTRIBUTION = previous;
    }
  }
});

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";

import {
  buildLiveKitRtcToken,
  readLiveKitRtcCredentials,
} from "./livekitTokenService";
import { lifecycleError } from "./lifecycleErrors";
import { requireAuthenticatedUid } from "./sessionAuth";
import { sessionCallableHttpsOptions } from "./sessionCallableOptions";

/** Fixed LiveKit room for QA smoke tests — must match client [kDebugLiveKitRoomName]. */
export const DEBUG_LIVEKIT_ROOM_NAME = "debug-livekit-test";

/**
 * Deploy after first add or secret changes (same project/region as issueSessionRtcToken):
 *
 * ```sh
 * firebase deploy --only functions:issueDebugLiveKitToken --project quran-playera-app
 * ```
 *
 * Requires secrets: LIVEKIT_API_KEY, LIVEKIT_API_SECRET, LIVEKIT_URL.
 */

const LIVEKIT_API_KEY = defineSecret("LIVEKIT_API_KEY");
const LIVEKIT_API_SECRET = defineSecret("LIVEKIT_API_SECRET");
const LIVEKIT_URL = defineSecret("LIVEKIT_URL");

function assertDebugLiveKitAllowed(): void {
  const distribution = process.env.TILAWA_DISTRIBUTION ?? "local";
  if (distribution === "play_production") {
    throw new HttpsError(
      "permission-denied",
      "Debug LiveKit tokens are disabled in production.",
    );
  }
}

export async function issueDebugLiveKitTokenForRequest(
  request: { auth?: { uid?: string } | null },
  readLiveKitCredentials = readLiveKitRtcCredentials,
): Promise<{
  token: string;
  channelId: string;
  uid: number;
  appId: string;
  callProvider: "livekit";
}> {
  assertDebugLiveKitAllowed();
  const uid = requireAuthenticatedUid(request as never);

  const credentials = readLiveKitCredentials();
  if (credentials == null) {
    throw lifecycleError(
      "unsupported_call_provider",
      "LiveKit credentials are not configured on the server.",
      { callProvider: "livekit" },
    );
  }

  const token = await buildLiveKitRtcToken({
    credentials,
    roomName: DEBUG_LIVEKIT_ROOM_NAME,
    identity: uid,
  });

  return {
    token,
    channelId: DEBUG_LIVEKIT_ROOM_NAME,
    uid: 0,
    appId: credentials.serverUrl,
    callProvider: "livekit",
  };
}

export const issueDebugLiveKitToken = onCall(
  {
    ...sessionCallableHttpsOptions,
    // QA-only callable: debug/staging clients often skip App Check activation
    // (see AppStartupTasks._activateAppCheck). Auth uid + non-production gate
    // are sufficient here.
    enforceAppCheck: false,
    secrets: [LIVEKIT_API_KEY, LIVEKIT_API_SECRET, LIVEKIT_URL],
  },
  async (request) => issueDebugLiveKitTokenForRequest(request),
);

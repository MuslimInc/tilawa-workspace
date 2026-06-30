import { onCall } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { getFirestore } from "firebase-admin/firestore";

import { issueSessionRtcTokenForRequest } from "./issueSessionRtcTokenService";
import { sessionCallableHttpsOptions } from "./sessionCallableOptions";

// Set via: firebase functions:secrets:set LIVEKIT_API_KEY LIVEKIT_API_SECRET LIVEKIT_URL
// Staging LiveKit project ID (console only): p_2n1vvcqjfqy
// LIVEKIT_API_SECRET is required (LiveKit Cloud → Settings → Keys; shown once at creation).
// LIVEKIT_URL for staging: wss://tilawa-7whzug8z.livekit.cloud
// Set via: firebase functions:secrets:set AGORA_APP_ID AGORA_APP_CERTIFICATE
const AGORA_APP_ID = defineSecret("AGORA_APP_ID");
const AGORA_APP_CERTIFICATE = defineSecret("AGORA_APP_CERTIFICATE");
const LIVEKIT_API_KEY = defineSecret("LIVEKIT_API_KEY");
const LIVEKIT_API_SECRET = defineSecret("LIVEKIT_API_SECRET");
const LIVEKIT_URL = defineSecret("LIVEKIT_URL");

export const issueSessionRtcToken = onCall(
  {
    ...sessionCallableHttpsOptions,
    secrets: [
      AGORA_APP_ID,
      AGORA_APP_CERTIFICATE,
      LIVEKIT_API_KEY,
      LIVEKIT_API_SECRET,
      LIVEKIT_URL,
    ],
  },
  async (request) =>
    issueSessionRtcTokenForRequest(request, { db: getFirestore() }),
);

export { issueSessionRtcTokenForRequest } from "./issueSessionRtcTokenService";

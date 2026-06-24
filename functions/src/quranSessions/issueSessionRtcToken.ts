import { onCall } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { getFirestore } from "firebase-admin/firestore";

import { issueSessionRtcTokenForRequest } from "./issueSessionRtcTokenService";
import { sessionCallableHttpsOptions } from "./sessionCallableOptions";

// Set via: firebase functions:secrets:set AGORA_APP_ID AGORA_APP_CERTIFICATE
const AGORA_APP_ID = defineSecret("AGORA_APP_ID");
const AGORA_APP_CERTIFICATE = defineSecret("AGORA_APP_CERTIFICATE");

export const issueSessionRtcToken = onCall(
  {
    ...sessionCallableHttpsOptions,
    secrets: [AGORA_APP_ID, AGORA_APP_CERTIFICATE],
  },
  async (request) =>
    issueSessionRtcTokenForRequest(request, { db: getFirestore() }),
);

export { issueSessionRtcTokenForRequest } from "./issueSessionRtcTokenService";

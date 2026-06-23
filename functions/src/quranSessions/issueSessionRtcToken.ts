import { onCall } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import { issueSessionRtcTokenForRequest } from "./issueSessionRtcTokenService";
import { sessionCallableHttpsOptions } from "./sessionCallableOptions";

export const issueSessionRtcToken = onCall(
  sessionCallableHttpsOptions,
  async (request) =>
    issueSessionRtcTokenForRequest(request, { db: getFirestore() }),
);

export { issueSessionRtcTokenForRequest } from "./issueSessionRtcTokenService";

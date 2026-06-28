import { CallableRequest, HttpsError } from "firebase-functions/v2/https";
import type { Firestore } from "firebase-admin/firestore";

import {
  agoraUidForFirebaseUser,
  AgoraRtcCredentials,
  buildAgoraRtcToken,
  readAgoraRtcCredentials,
} from "./agoraTokenService";
import { lifecycleError } from "./lifecycleErrors";
import {
  isAdmin,
  requireAuthenticatedUid,
  requireValidSessionEpoch,
  resolveActorRole,
} from "./sessionAuth";
import { resolveTeacherProfileUserId, teacherUserIdFromDenormalizedSessionData } from "./teacherProfileUserId";

interface IssueSessionRtcTokenRequest {
  sessionId: string;
}

export interface IssueSessionRtcTokenResult {
  token: string;
  channelId: string;
  uid: number;
  appId: string;
  callProvider: "agora";
}

export interface IssueSessionRtcTokenDeps {
  db: Firestore;
  readCredentials?: () => AgoraRtcCredentials | null;
}

const JOINABLE_STATUSES = new Set([
  "scheduled",
  "in_progress",
  "reschedule_pending",
]);

export async function issueSessionRtcTokenForRequest(
  request: CallableRequest<IssueSessionRtcTokenRequest>,
  deps: IssueSessionRtcTokenDeps,
): Promise<IssueSessionRtcTokenResult> {
  const uid = requireAuthenticatedUid(request);
  if (!isAdmin(request)) {
    await requireValidSessionEpoch(request, uid, deps.db);
  }

  const data = request.data;
  if (!data.sessionId?.trim()) {
    throw new HttpsError("invalid-argument", "sessionId required.");
  }

  const sessionRef = deps.db.collection("quran_sessions").doc(data.sessionId);
  const sessionSnap = await sessionRef.get();
  if (!sessionSnap.exists) {
    throw new HttpsError("not-found", "Session not found.");
  }

  const session = sessionSnap.data() ?? {};
  const callProvider = session.callProvider as string | undefined;
  if (callProvider !== "agora") {
    throw lifecycleError(
      "unsupported_call_provider",
      "Session is not configured for Agora RTC.",
      { callProvider: callProvider ?? "unknown" },
    );
  }

  const lifecycleStatus = session.lifecycleStatus as string | undefined;
  if (lifecycleStatus == null || !JOINABLE_STATUSES.has(lifecycleStatus)) {
    throw lifecycleError(
      "invalid_transition",
      "Session cannot be joined in its current state.",
      { reasonCode: "join_not_allowed" },
    );
  }

  const bookingId = session.bookingId as string;
  const bookingSnap = await deps.db
    .collection("quran_bookings")
    .doc(bookingId)
    .get();
  if (!bookingSnap.exists) {
    throw new HttpsError("not-found", "Booking not found.");
  }
  const booking = bookingSnap.data() ?? {};
  const participants = {
    studentId: (booking.studentId as string) ?? "",
    teacherId: (booking.teacherId as string) ?? "",
  };

  const teacherUserId =
    teacherUserIdFromDenormalizedSessionData(booking) ??
    (await resolveTeacherProfileUserId(deps.db, participants.teacherId));
  resolveActorRole(request, undefined, participants, teacherUserId);

  const readCredentials = deps.readCredentials ?? readAgoraRtcCredentials;
  const credentials = readCredentials();
  if (credentials == null) {
    throw lifecycleError(
      "unsupported_call_provider",
      "Agora credentials are not configured on the server.",
      { callProvider: "agora" },
    );
  }

  const channelName =
    (session.providerSessionId as string | undefined)?.trim()
    || data.sessionId;
  const agoraUid = agoraUidForFirebaseUser(uid);
  const token = buildAgoraRtcToken({
    credentials,
    channelName,
    uid: agoraUid,
  });

  return {
    token,
    channelId: channelName,
    uid: agoraUid,
    appId: credentials.appId,
    callProvider: "agora",
  };
}

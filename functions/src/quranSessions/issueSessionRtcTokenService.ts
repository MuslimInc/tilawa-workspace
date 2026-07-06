import { CallableRequest, HttpsError } from "firebase-functions/v2/https";
import type { Firestore } from "firebase-admin/firestore";

import {
  agoraUidForFirebaseUser,
  AgoraRtcCredentials,
  buildAgoraRtcToken,
  readAgoraRtcCredentials,
} from "./agoraTokenService";
import { lifecycleError } from "./lifecycleErrors";
import { isWithinJoinWindowOrQaBypass } from "./sessionJoinWindowPolicy";
import { JOIN_WINDOW_LEAD_MS } from "./platformSchedulingPolicy";
import {
  buildLiveKitRtcToken,
  LiveKitRtcCredentials,
  readLiveKitRtcCredentials,
} from "./livekitTokenService";
import {
  isAdmin,
  requireAuthenticatedUid,
  requireValidSessionEpoch,
  resolveActorRole,
} from "./sessionAuth";
import { resolveTeacherProfileUserId, teacherUserIdFromDenormalizedSessionData } from "./teacherProfileUserId";
import { isLiveSessionDeviceLockEnabled } from "../liveSessionDeviceLock";
import { acquireLiveLock } from "./liveSessionLockService";
import {
  LIVE_LOCK_LEASE_TTL_MS,
  liveKitIdentity,
} from "./liveSessionLock";
import {
  evictLiveKitParticipant,
  type LiveKitEvictionFn,
} from "./liveKitEviction";
import {
  sendSessionTakenOverPush,
  type TakeoverPushFn,
} from "./liveSessionTakeoverPush";

interface IssueSessionRtcTokenRequest {
  sessionId: string;
  /**
   * Stable device id (from the device registry). Required when the live lock is
   * enabled so the per-participant lease can be keyed by device. Ignored on the
   * legacy path. ADR-008 Phase 2.
   */
  deviceId?: string;
  /**
   * User-initiated takeover of the caller's own other device. When true, the
   * server grants the lease, evicts the previous LiveKit identity, and sends a
   * device-targeted `session_taken_over` push to the old device.
   */
  forceTakeover?: boolean;
}

export interface IssueSessionRtcTokenResult {
  token: string;
  channelId: string;
  uid: number;
  appId: string;
  callProvider: "agora" | "livekit";
}

export interface IssueSessionRtcTokenDeps {
  db: Firestore;
  readAgoraCredentials?: () => AgoraRtcCredentials | null;
  readLiveKitCredentials?: () => LiveKitRtcCredentials | null;
  /** Override for unit tests; defaults to the LiveKit RoomServiceClient impl. */
  evictLiveKitParticipant?: LiveKitEvictionFn;
  /** Override for unit tests; defaults to the FCM `session_taken_over` impl. */
  sendTakeoverPush?: TakeoverPushFn;
}

const JOINABLE_STATUSES = new Set([
  "scheduled",
  "confirmed",
  "in_progress",
  "rescheduled",
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
  if (callProvider !== "agora" && callProvider !== "livekit") {
    throw lifecycleError(
      "unsupported_call_provider",
      "Session is not configured for in-app RTC.",
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
  const startsAtRaw = (session.startsAt ?? booking.startsAt) as
    | FirebaseFirestore.Timestamp
    | undefined;
  const endsAtRaw = (session.endsAt ?? booking.endsAt) as
    | FirebaseFirestore.Timestamp
    | undefined;
  if (startsAtRaw == null || endsAtRaw == null) {
    throw lifecycleError(
      "invalid_transition",
      "Session schedule is incomplete.",
      { reasonCode: "join_not_allowed" },
    );
  }
  const joinLeadMs =
    (booking.joinWindowLeadMs as number | undefined) ?? JOIN_WINDOW_LEAD_MS;
  if (
    !isWithinJoinWindowOrQaBypass({
      startsAt: startsAtRaw.toDate(),
      endsAt: endsAtRaw.toDate(),
      now: new Date(),
      leadTimeMs: joinLeadMs,
      uid,
    })
  ) {
    throw lifecycleError(
      "join_window_closed",
      "Session join window is not open.",
      { reasonCode: "join_window_closed" },
    );
  }

  const participants = {
    studentId: (booking.studentId as string) ?? "",
    teacherId: (booking.teacherId as string) ?? "",
  };

  const teacherUserId =
    teacherUserIdFromDenormalizedSessionData(booking) ??
    (await resolveTeacherProfileUserId(deps.db, participants.teacherId));
  resolveActorRole(request, undefined, participants, teacherUserId);

  const channelName =
    (session.providerSessionId as string | undefined)?.trim()
    || data.sessionId;

  const lockEnabled = isLiveSessionDeviceLockEnabled();
  const deviceId = data.deviceId?.trim();
  const forceTakeover = data.forceTakeover === true;

  // ADR-008 Phase 2: acquire a per-participant lease before minting the token.
  // When the flag is off, the legacy path is unchanged (no lock, identity = uid).
  if (lockEnabled) {
    if (!deviceId) {
      throw new HttpsError(
        "invalid-argument",
        "deviceId is required to join a live session.",
      );
    }
    const lockOutcome = await acquireLiveLock({
      db: deps.db,
      sessionRef,
      uid,
      deviceId,
      forceTakeover,
    });

    if (lockOutcome.evictIdentity) {
      if (callProvider === "livekit") {
        const readLiveKitCredentials =
          deps.readLiveKitCredentials ?? readLiveKitRtcCredentials;
        const credentials = readLiveKitCredentials();
        if (credentials) {
          const evict = deps.evictLiveKitParticipant ?? evictLiveKitParticipant;
          await evict({
            credentials,
            roomName: channelName,
            identity: lockOutcome.evictIdentity,
          });
        }
      }
      if (lockOutcome.previousDeviceId) {
        const sendPush = deps.sendTakeoverPush ?? sendSessionTakenOverPush;
        await sendPush({
          db: deps.db,
          uid,
          deviceId: lockOutcome.previousDeviceId,
          sessionId: data.sessionId,
        });
      }
    }
  }

  const leaseTtlSeconds = lockEnabled
    ? LIVE_LOCK_LEASE_TTL_MS / 1000
    : undefined;
  const identityForToken = lockEnabled && deviceId
    ? liveKitIdentity(uid, deviceId)
    : uid;

  if (callProvider === "livekit") {
    const readLiveKitCredentials =
      deps.readLiveKitCredentials ?? readLiveKitRtcCredentials;
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
      roomName: channelName,
      identity: identityForToken,
      ttlSeconds: leaseTtlSeconds,
    });

    return {
      token,
      channelId: channelName,
      uid: 0,
      appId: credentials.serverUrl,
      callProvider: "livekit",
    };
  }

  const readAgoraCredentials =
    deps.readAgoraCredentials ?? readAgoraRtcCredentials;
  const credentials = readAgoraCredentials();
  if (credentials == null) {
    throw lifecycleError(
      "unsupported_call_provider",
      "Agora credentials are not configured on the server.",
      { callProvider: "agora" },
    );
  }

  const agoraUid = agoraUidForFirebaseUser(uid);
  const token = buildAgoraRtcToken({
    credentials,
    channelName,
    uid: agoraUid,
    ttlSeconds: leaseTtlSeconds,
  });

  return {
    token,
    channelId: channelName,
    uid: agoraUid,
    appId: credentials.appId,
    callProvider: "agora",
  };
}

import test from "node:test";
import assert from "node:assert/strict";

import {
  agoraUidForFirebaseUser,
  buildAgoraRtcToken,
} from "../../src/quranSessions/agoraTokenService";
import { buildLiveKitRtcToken } from "../../src/quranSessions/livekitTokenService";
import { issueSessionRtcTokenForRequest } from "../../src/quranSessions/issueSessionRtcTokenService";
import {
  MAESTRO_STUDENT_UID,
} from "../../src/quranSessions/maestroStagingAccounts";

const TEST_CREDENTIALS = {
  appId: "test-agora-app-id",
  appCertificate: "test-agora-app-cert",
};

function timestampFromDate(date: Date) {
  return {
    toDate: () => date,
    toMillis: () => date.getTime(),
  };
}

function joinWindowSchedule() {
  const now = new Date();
  return {
    startsAt: timestampFromDate(new Date(now.getTime() + 5 * 60 * 1000)),
    endsAt: timestampFromDate(new Date(now.getTime() + 65 * 60 * 1000)),
  };
}

function createDb(docs: Record<string, Record<string, unknown>>) {
  return {
    collection(name: string) {
      return {
        doc(id: string) {
          return {
            async get() {
              const data = docs[`${name}/${id}`];
              return {
                exists: data != null,
                data: () => data,
              };
            },
          };
        },
      };
    },
  } as unknown as FirebaseFirestore.Firestore;
}

function authRequest(
  uid: string,
  options: {
    admin?: boolean;
    data?: Record<string, unknown>;
  } = {},
) {
  return {
    auth: {
      uid,
      token: options.admin ? { admin: true } : {},
    },
    data: { sessionEpoch: 1, ...options.data },
  } as never;
}

function agoraSessionDocs(
  overrides: {
    sessionId?: string;
    bookingId?: string;
    lifecycleStatus?: string;
    callProvider?: string;
    studentId?: string;
    teacherId?: string;
    teacherUserId?: string;
    providerSessionId?: string;
    includeBooking?: boolean;
  } = {},
) {
  const sessionId = overrides.sessionId ?? "session_1";
  const bookingId = overrides.bookingId ?? "booking_1";
  const studentId = overrides.studentId ?? "student_1";
  const teacherId = overrides.teacherId ?? "teacher_profile_1";
  const schedule = joinWindowSchedule();
  const docs: Record<string, Record<string, unknown>> = {
    [`quran_sessions/${sessionId}`]: {
      callProvider: overrides.callProvider ?? "agora",
      lifecycleStatus: overrides.lifecycleStatus ?? "scheduled",
      bookingId,
      providerSessionId: overrides.providerSessionId,
      ...schedule,
    },
    [`quran_teacher_profiles/${teacherId}`]: {
      userId: overrides.teacherUserId ?? "teacher_auth_1",
    },
    [`users/${studentId}`]: { session: { epoch: 1 } },
    [`users/${overrides.teacherUserId ?? "teacher_auth_1"}`]: {
      session: { epoch: 1 },
    },
  };
  if (overrides.includeBooking !== false) {
    docs[`quran_bookings/${bookingId}`] = {
      studentId,
      teacherId,
      ...schedule,
    };
  }
  docs["users/stranger_1"] = { session: { epoch: 1 } };
  return { sessionId, bookingId, studentId, docs };
}

test("issueSessionRtcTokenForRequest rejects non-participant callers", async () => {
  const { sessionId, docs } = agoraSessionDocs();
  const db = createDb(docs);

  await assert.rejects(
    () =>
      issueSessionRtcTokenForRequest(
        authRequest("stranger_1", { data: { sessionId } }),
        { db, readAgoraCredentials: () => TEST_CREDENTIALS },
      ),
    (error: { code?: string; details?: { code?: string } }) =>
      error.code === "permission-denied" &&
      error.details?.code === "not_participant",
  );
});

test("issueSessionRtcTokenForRequest rejects non-joinable lifecycle", async () => {
  const { sessionId, docs } = agoraSessionDocs({
    lifecycleStatus: "completed",
  });
  const db = createDb(docs);

  await assert.rejects(
    () =>
      issueSessionRtcTokenForRequest(
        authRequest("student_1", { data: { sessionId } }),
        { db, readAgoraCredentials: () => TEST_CREDENTIALS },
      ),
    (error: { details?: { code?: string; reasonCode?: string } }) =>
      error.details?.code === "invalid_transition" &&
      error.details?.reasonCode === "join_not_allowed",
  );
});

test("issueSessionRtcTokenForRequest rejects non-rtc sessions", async () => {
  const { sessionId, docs } = agoraSessionDocs({ callProvider: "mock" });
  const db = createDb(docs);

  await assert.rejects(
    () =>
      issueSessionRtcTokenForRequest(
        authRequest("student_1", { data: { sessionId } }),
        { db, readAgoraCredentials: () => TEST_CREDENTIALS },
      ),
    (error: { details?: { code?: string } }) =>
      error.details?.code === "unsupported_call_provider",
  );
});

test("issueSessionRtcTokenForRequest rejects missing booking", async () => {
  const { sessionId, docs } = agoraSessionDocs({ includeBooking: false });
  const db = createDb(docs);

  await assert.rejects(
    () =>
      issueSessionRtcTokenForRequest(
        authRequest("student_1", { data: { sessionId } }),
        { db, readAgoraCredentials: () => TEST_CREDENTIALS },
      ),
    (error: { code?: string }) => error.code === "not-found",
  );
});

test("issueSessionRtcTokenForRequest returns Agora credentials for participant", async () => {
  const { sessionId, docs } = agoraSessionDocs({
    providerSessionId: "agora_channel_1",
  });
  const db = createDb(docs);
  const uid = "student_1";
  const agoraUid = agoraUidForFirebaseUser(uid);

  const result = await issueSessionRtcTokenForRequest(
    authRequest(uid, { data: { sessionId } }),
    { db, readAgoraCredentials: () => TEST_CREDENTIALS },
  );

  assert.equal(result.callProvider, "agora");
  assert.equal(result.channelId, "agora_channel_1");
  assert.equal(result.uid, agoraUid);
  assert.equal(result.appId, TEST_CREDENTIALS.appId);
  assert.equal(
    result.token,
    buildAgoraRtcToken({
      credentials: TEST_CREDENTIALS,
      channelName: "agora_channel_1",
      uid: agoraUid,
    }),
  );
});

test("issueSessionRtcTokenForRequest allows teacher auth uid via profile mapping", async () => {
  const { sessionId, docs } = agoraSessionDocs();
  const db = createDb(docs);

  const result = await issueSessionRtcTokenForRequest(
    authRequest("teacher_auth_1", { data: { sessionId } }),
    { db, readAgoraCredentials: () => TEST_CREDENTIALS },
  );

  assert.equal(result.uid, agoraUidForFirebaseUser("teacher_auth_1"));
  assert.equal(result.channelId, sessionId);
});

test("issueSessionRtcTokenForRequest allows admin without epoch bypassing participant check", async () => {
  const { sessionId, docs } = agoraSessionDocs();
  const db = createDb(docs);
  const adminUid = "admin_support_1";

  const result = await issueSessionRtcTokenForRequest(
    authRequest(adminUid, {
      admin: true,
      data: { sessionId },
    }),
    { db, readAgoraCredentials: () => TEST_CREDENTIALS },
  );

  assert.equal(result.callProvider, "agora");
  assert.equal(result.uid, agoraUidForFirebaseUser(adminUid));
  assert.equal(result.channelId, sessionId);
  assert.equal(
    result.token,
    buildAgoraRtcToken({
      credentials: TEST_CREDENTIALS,
      channelName: sessionId,
      uid: agoraUidForFirebaseUser(adminUid),
    }),
  );
});

test("issueSessionRtcTokenForRequest returns LiveKit credentials for participant", async () => {
  const { sessionId, docs } = agoraSessionDocs({
    callProvider: "livekit",
    providerSessionId: "livekit_room_1",
  });
  const db = createDb(docs);
  const uid = "student_1";
  const liveKitCredentials = {
    apiKey: "APIKEY123",
    apiSecret: "secret123456789012345678901234567890",
    serverUrl: "wss://project.livekit.cloud",
  };

  const result = await issueSessionRtcTokenForRequest(
    authRequest(uid, { data: { sessionId } }),
    {
      db,
      readLiveKitCredentials: () => liveKitCredentials,
    },
  );

  assert.equal(result.callProvider, "livekit");
  assert.equal(result.channelId, "livekit_room_1");
  assert.equal(result.uid, 0);
  assert.equal(result.appId, liveKitCredentials.serverUrl);
  assert.equal(
    result.token,
    await buildLiveKitRtcToken({
      credentials: liveKitCredentials,
      roomName: "livekit_room_1",
      identity: uid,
    }),
  );
});

function outsideJoinWindowSchedule() {
  const now = new Date();
  return {
    startsAt: timestampFromDate(new Date(now.getTime() + 2 * 60 * 60 * 1000)),
    endsAt: timestampFromDate(new Date(now.getTime() + 3 * 60 * 60 * 1000)),
  };
}

test("issueSessionRtcTokenForRequest rejects join outside window for normal users", async () => {
  const schedule = outsideJoinWindowSchedule();
  const { sessionId, docs } = agoraSessionDocs({
    studentId: "student_outside_window",
  });
  docs[`quran_sessions/${sessionId}`] = {
    ...docs[`quran_sessions/${sessionId}`],
    ...schedule,
  };
  docs[`quran_bookings/booking_1`] = {
    ...docs[`quran_bookings/booking_1`],
    ...schedule,
    studentId: "student_outside_window",
  };
  const db = createDb(docs);
  const previous = process.env.TILAWA_DISTRIBUTION;
  process.env.TILAWA_DISTRIBUTION = "staging";

  try {
    await assert.rejects(
      () =>
        issueSessionRtcTokenForRequest(
          authRequest("student_outside_window", { data: { sessionId } }),
          { db, readAgoraCredentials: () => TEST_CREDENTIALS },
        ),
      (error: { details?: { code?: string; reasonCode?: string } }) =>
        error.details?.code === "join_window_closed" &&
        error.details?.reasonCode === "join_window_closed",
    );
  } finally {
    if (previous == null) {
      delete process.env.TILAWA_DISTRIBUTION;
    } else {
      process.env.TILAWA_DISTRIBUTION = previous;
    }
  }
});

test("issueSessionRtcTokenForRequest allows QA uid outside join window on staging", async () => {
  const schedule = outsideJoinWindowSchedule();
  const { sessionId, docs } = agoraSessionDocs({
    studentId: MAESTRO_STUDENT_UID,
  });
  docs[`quran_sessions/${sessionId}`] = {
    ...docs[`quran_sessions/${sessionId}`],
    ...schedule,
  };
  docs[`quran_bookings/booking_1`] = {
    ...docs[`quran_bookings/booking_1`],
    ...schedule,
    studentId: MAESTRO_STUDENT_UID,
  };
  docs[`users/${MAESTRO_STUDENT_UID}`] = { session: { epoch: 1 } };
  const db = createDb(docs);
  const previous = process.env.TILAWA_DISTRIBUTION;
  process.env.TILAWA_DISTRIBUTION = "staging";

  try {
    const result = await issueSessionRtcTokenForRequest(
      authRequest(MAESTRO_STUDENT_UID, { data: { sessionId } }),
      { db, readAgoraCredentials: () => TEST_CREDENTIALS },
    );
    assert.equal(result.callProvider, "agora");
  } finally {
    if (previous == null) {
      delete process.env.TILAWA_DISTRIBUTION;
    } else {
      process.env.TILAWA_DISTRIBUTION = previous;
    }
  }
});

test("issueSessionRtcTokenForRequest still blocks completed session for QA uid", async () => {
  const { sessionId, docs } = agoraSessionDocs({
    studentId: MAESTRO_STUDENT_UID,
    lifecycleStatus: "completed",
  });
  docs[`users/${MAESTRO_STUDENT_UID}`] = { session: { epoch: 1 } };
  const db = createDb(docs);
  const previous = process.env.TILAWA_DISTRIBUTION;
  process.env.TILAWA_DISTRIBUTION = "staging";

  try {
    await assert.rejects(
      () =>
        issueSessionRtcTokenForRequest(
          authRequest(MAESTRO_STUDENT_UID, { data: { sessionId } }),
          { db, readAgoraCredentials: () => TEST_CREDENTIALS },
        ),
      (error: { details?: { code?: string; reasonCode?: string } }) =>
        error.details?.code === "invalid_transition" &&
        error.details?.reasonCode === "join_not_allowed",
    );
  } finally {
    if (previous == null) {
      delete process.env.TILAWA_DISTRIBUTION;
    } else {
      process.env.TILAWA_DISTRIBUTION = previous;
    }
  }
});

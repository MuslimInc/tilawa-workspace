import test from "node:test";
import assert from "node:assert/strict";

import {
  agoraUidForFirebaseUser,
  buildAgoraRtcToken,
} from "../../src/quranSessions/agoraTokenService";
import { buildLiveKitRtcToken } from "../../src/quranSessions/livekitTokenService";
import { issueSessionRtcTokenForRequest } from "../../src/quranSessions/issueSessionRtcTokenService";
import {
  LIVE_LOCK_LEASE_TTL_MS,
  liveKitIdentity,
} from "../../src/quranSessions/liveSessionLock";
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

// ---------------------------------------------------------------------------
// ADR-008 Phase 2 — per-session live device lock (flag-gated path).
// ---------------------------------------------------------------------------

const LIVE_LOCK_FLAG = "LIVE_SESSION_DEVICE_LOCK_ENABLED";

async function withLiveLockFlag<T>(
  enabled: boolean,
  fn: () => Promise<T>,
): Promise<T> {
  const previous = process.env[LIVE_LOCK_FLAG];
  if (enabled) {
    process.env[LIVE_LOCK_FLAG] = "true";
  } else {
    delete process.env[LIVE_LOCK_FLAG];
  }
  try {
    return await fn();
  } finally {
    if (previous == null) {
      delete process.env[LIVE_LOCK_FLAG];
    } else {
      process.env[LIVE_LOCK_FLAG] = previous;
    }
  }
}

function isDataObject(v: unknown): v is Record<string, unknown> {
  return (
    typeof v === "object"
    && v !== null
    && !Array.isArray(v)
    && Object.getPrototypeOf(v) === Object.prototype
  );
}

function deepMerge(
  target: Record<string, unknown>,
  src: Record<string, unknown>,
): Record<string, unknown> {
  const out: Record<string, unknown> = { ...target };
  for (const [k, v] of Object.entries(src)) {
    if (isDataObject(v) && isDataObject(out[k])) {
      out[k] = deepMerge(out[k] as Record<string, unknown>, v);
    } else {
      out[k] = v;
    }
  }
  return out;
}

/** Fake Firestore that supports `runTransaction` with `tx.get` / `tx.set`. */
function createTxnDb(docs: Record<string, Record<string, unknown>>) {
  const store = new Map<string, Record<string, unknown>>(
    Object.entries(docs),
  );
  const txnWrites: Array<{
    key: string;
    data: Record<string, unknown>;
  }> = [];

  function docRef(name: string, id: string) {
    const key = `${name}/${id}`;
    return {
      collection: name,
      id,
      path: key,
      async get() {
        const data = store.get(key);
        return { exists: data != null, data: () => data ?? {} };
      },
    };
  }

  const db = {
    collection(name: string) {
      return { doc: (id: string) => docRef(name, id) };
    },
    async runTransaction<T2>(
      fn: (tx: {
        get: (ref: { collection: string; id: string }) => Promise<{
          exists: boolean;
          data: () => Record<string, unknown>;
        }>;
        set: (
          ref: { collection: string; id: string },
          data: Record<string, unknown>,
          opts?: { merge?: boolean },
        ) => void;
      }) => Promise<T2>,
    ): Promise<T2> {
      const tx = {
        get: async (ref: { collection: string; id: string }) => {
          const key = `${ref.collection}/${ref.id}`;
          const data = store.get(key) ?? {};
          return { exists: store.has(key), data: () => data };
        },
        set: (
          ref: { collection: string; id: string },
          data: Record<string, unknown>,
        ) => {
          const key = `${ref.collection}/${ref.id}`;
          txnWrites.push({ key, data });
          const existing = store.get(key) ?? {};
          store.set(key, deepMerge(existing, data));
        },
      };
      return fn(tx);
    },
  } as unknown as FirebaseFirestore.Firestore;

  return { db, txnWrites, store };
}

const LIVEKIT_CREDENTIALS = {
  apiKey: "APIKEY123",
  apiSecret: "secret123456789012345678901234567890",
  serverUrl: "wss://project.livekit.cloud",
};

function liveLockEntry(
  deviceId: string,
  uid: string,
  leaseUntilMs: number,
  lockEpoch: number,
) {
  return {
    deviceId,
    identity: liveKitIdentity(uid, deviceId),
    leaseUntil: timestampFromDate(new Date(leaseUntilMs)),
    lockEpoch,
    updatedAt: timestampFromDate(new Date(leaseUntilMs - 60_000)),
  };
}

test("live lock: rejects when deviceId is missing while the flag is on", async () => {
  const { sessionId, docs } = agoraSessionDocs({ callProvider: "livekit" });
  const { db } = createTxnDb(docs);

  await withLiveLockFlag(true, async () => {
    await assert.rejects(
      () =>
        issueSessionRtcTokenForRequest(
          authRequest("student_1", { data: { sessionId } }),
          {
            db,
            readLiveKitCredentials: () => LIVEKIT_CREDENTIALS,
          },
        ),
      (error: { code?: string }) => error.code === "invalid-argument",
    );
  });
});

test("live lock: grants a fresh LiveKit lease with identity = uid#deviceId", async () => {
  const { sessionId, docs } = agoraSessionDocs({
    callProvider: "livekit",
    providerSessionId: "livekit_room_1",
  });
  const { db } = createTxnDb(docs);
  const uid = "student_1";
  const deviceId = "device_A";
  const ttlSeconds = LIVE_LOCK_LEASE_TTL_MS / 1000;

  const result = await withLiveLockFlag(true, () =>
    issueSessionRtcTokenForRequest(
      authRequest(uid, { data: { sessionId, deviceId } }),
      {
        db,
        readLiveKitCredentials: () => LIVEKIT_CREDENTIALS,
        evictLiveKitParticipant: async () => {},
        sendTakeoverPush: async () => {},
      },
    ),
  );

  assert.equal(result.callProvider, "livekit");
  assert.equal(
    result.token,
    await buildLiveKitRtcToken({
      credentials: LIVEKIT_CREDENTIALS,
      roomName: "livekit_room_1",
      identity: liveKitIdentity(uid, deviceId),
      ttlSeconds,
    }),
  );
});

test("live lock: grants a fresh Agora lease with the lease TTL on the token", async () => {
  const { sessionId, docs } = agoraSessionDocs();
  const { db } = createTxnDb(docs);
  const uid = "student_1";
  const deviceId = "device_A";
  const agoraUid = agoraUidForFirebaseUser(uid);
  const ttlSeconds = LIVE_LOCK_LEASE_TTL_MS / 1000;

  const result = await withLiveLockFlag(true, () =>
    issueSessionRtcTokenForRequest(
      authRequest(uid, { data: { sessionId, deviceId } }),
      {
        db,
        readAgoraCredentials: () => TEST_CREDENTIALS,
        evictLiveKitParticipant: async () => {},
        sendTakeoverPush: async () => {},
      },
    ),
  );

  assert.equal(result.callProvider, "agora");
  assert.equal(
    result.token,
    buildAgoraRtcToken({
      credentials: TEST_CREDENTIALS,
      channelName: sessionId,
      uid: agoraUid,
      ttlSeconds,
    }),
  );
});

test("live lock: renews without eviction when the same device reclaims", async () => {
  const { sessionId, docs } = agoraSessionDocs({ callProvider: "livekit" });
  const uid = "student_1";
  const deviceId = "device_A";
  const future = Date.now() + LIVE_LOCK_LEASE_TTL_MS;
  docs[`quran_sessions/${sessionId}`].liveLocks = {
    [uid]: liveLockEntry(deviceId, uid, future, 1),
  };
  const { db } = createTxnDb(docs);

  let evictCalls = 0;
  let pushCalls = 0;

  await withLiveLockFlag(true, () =>
    issueSessionRtcTokenForRequest(
      authRequest(uid, { data: { sessionId, deviceId } }),
      {
        db,
        readLiveKitCredentials: () => LIVEKIT_CREDENTIALS,
        evictLiveKitParticipant: async () => {
          evictCalls += 1;
        },
        sendTakeoverPush: async () => {
          pushCalls += 1;
        },
      },
    ),
  );

  assert.equal(evictCalls, 0);
  assert.equal(pushCalls, 0);
});

test("live lock: denies a second device without takeover", async () => {
  const { sessionId, docs } = agoraSessionDocs({ callProvider: "livekit" });
  const uid = "student_1";
  const future = Date.now() + LIVE_LOCK_LEASE_TTL_MS;
  docs[`quran_sessions/${sessionId}`].liveLocks = {
    [uid]: liveLockEntry("device_A", uid, future, 1),
  };
  const { db } = createTxnDb(docs);

  await withLiveLockFlag(true, async () => {
    await assert.rejects(
      () =>
        issueSessionRtcTokenForRequest(
          authRequest(uid, { data: { sessionId, deviceId: "device_B" } }),
          {
            db,
            readLiveKitCredentials: () => LIVEKIT_CREDENTIALS,
            evictLiveKitParticipant: async () => {},
            sendTakeoverPush: async () => {},
          },
        ),
      (error: { details?: { code?: string; activeDeviceId?: string } }) =>
        error.details?.code === "already_active_on_other_device"
        && error.details?.activeDeviceId === "device_A",
    );
  });
});

test("live lock: forceTakeover evicts the old identity and pushes to the old device", async () => {
  const { sessionId, docs } = agoraSessionDocs({
    callProvider: "livekit",
    providerSessionId: "livekit_room_1",
  });
  const uid = "student_1";
  const future = Date.now() + LIVE_LOCK_LEASE_TTL_MS;
  docs[`quran_sessions/${sessionId}`].liveLocks = {
    [uid]: liveLockEntry("device_A", uid, future, 1),
  };
  const { db } = createTxnDb(docs);

  const evictCalls: Array<{ roomName: string; identity: string }> = [];
  const pushCalls: Array<{ uid: string; deviceId: string; sessionId: string }> = [];

  await withLiveLockFlag(true, () =>
    issueSessionRtcTokenForRequest(
      authRequest(uid, {
        data: { sessionId, deviceId: "device_B", forceTakeover: true },
      }),
      {
        db,
        readLiveKitCredentials: () => LIVEKIT_CREDENTIALS,
        evictLiveKitParticipant: async (input) => {
          evictCalls.push({ roomName: input.roomName, identity: input.identity });
        },
        sendTakeoverPush: async (input) => {
          pushCalls.push({
            uid: input.uid,
            deviceId: input.deviceId,
            sessionId: input.sessionId,
          });
        },
      },
    ),
  );

  assert.deepEqual(evictCalls, [
    { roomName: "livekit_room_1", identity: liveKitIdentity(uid, "device_A") },
  ]);
  assert.deepEqual(pushCalls, [
    { uid, deviceId: "device_A", sessionId },
  ]);
});

test("live lock: teacher and student hold independent locks (both granted)", async () => {
  const { sessionId, docs } = agoraSessionDocs({ callProvider: "livekit" });
  const future = Date.now() + LIVE_LOCK_LEASE_TTL_MS;
  const studentUid = "student_1";
  const teacherUid = "teacher_auth_1";
  docs[`quran_sessions/${sessionId}`].liveLocks = {
    [studentUid]: liveLockEntry("device_s", studentUid, future, 1),
  };
  const { db } = createTxnDb(docs);

  const result = await withLiveLockFlag(true, () =>
    issueSessionRtcTokenForRequest(
      authRequest(teacherUid, { data: { sessionId, deviceId: "device_t" } }),
      {
        db,
        readLiveKitCredentials: () => LIVEKIT_CREDENTIALS,
        evictLiveKitParticipant: async () => {},
        sendTakeoverPush: async () => {},
      },
    ),
  );

  assert.equal(result.callProvider, "livekit");
  assert.equal(
    result.token,
    await buildLiveKitRtcToken({
      credentials: LIVEKIT_CREDENTIALS,
      roomName: sessionId,
      identity: liveKitIdentity(teacherUid, "device_t"),
      ttlSeconds: LIVE_LOCK_LEASE_TTL_MS / 1000,
    }),
  );
});

test("live lock: with flag off, legacy path ignores deviceId and uses identity = uid", async () => {
  const { sessionId, docs } = agoraSessionDocs({
    callProvider: "livekit",
    providerSessionId: "livekit_room_1",
  });
  const { db } = createTxnDb(docs);
  const uid = "student_1";

  const result = await withLiveLockFlag(false, () =>
    issueSessionRtcTokenForRequest(
      authRequest(uid, { data: { sessionId, deviceId: "device_A" } }),
      {
        db,
        readLiveKitCredentials: () => LIVEKIT_CREDENTIALS,
        evictLiveKitParticipant: async () => {
          throw new Error("eviction must not run with the flag off");
        },
        sendTakeoverPush: async () => {
          throw new Error("push must not run with the flag off");
        },
      },
    ),
  );

  assert.equal(
    result.token,
    await buildLiveKitRtcToken({
      credentials: LIVEKIT_CREDENTIALS,
      roomName: "livekit_room_1",
      identity: uid,
    }),
  );
});

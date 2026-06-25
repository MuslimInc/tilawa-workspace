import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

import { appendAuditEvent } from "./aggregateWriteService";
import {
  buildOperationKey,
  runIdempotentOperation,
} from "./idempotencyService";
import { lifecycleError } from "./lifecycleErrors";
import { requireAdmin } from "./sessionAuth";
import { validateTransition } from "./sessionLifecycleGuard";
import {
  assertValidCallType,
  mapCallProviderResolverError,
  resolveCallProviderForBooking,
} from "./callProviderResolver";
import { buildIndividualParticipants } from "./sessionParticipants";
import {
  resolveTeacherProfileUserId,
  teacherProfileUserIdFromData,
} from "./teacherProfileUserId";
import {
  legacyStatusForLifecycle,
  nowServer,
} from "./sessionLifecycleService";
import { sessionCallableHttpsOptions } from "./sessionCallableOptions";
import { recordTerminalTransition } from "./metricsAggregationService";
import { enqueueSessionNotification } from "./notificationOutboxService";

/// Allowed manual session durations in minutes. 60 min is included because the
/// booking/slot domain already supports it. Any other duration (e.g. 12h) is
/// rejected unless an explicit test-only domain mode is introduced later.
const ALLOWED_MANUAL_SESSION_DURATION_MINUTES = new Set([15, 30, 45, 60]);

export function assertAllowedSessionDuration(
  startsAtRaw: string,
  endsAtRaw: string,
): void {
  const start = new Date(startsAtRaw);
  const end = new Date(endsAtRaw);
  if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) {
    throw new HttpsError(
      "invalid-argument",
      "Invalid startsAt or endsAt.",
      { code: "invalid_timestamp" },
    );
  }
  const durationMs = end.getTime() - start.getTime();
  if (durationMs <= 0) {
    throw new HttpsError(
      "invalid-argument",
      "endsAt must be after startsAt.",
      { code: "invalid_duration", durationMs },
    );
  }
  const durationMinutes = Math.round(durationMs / 60000);
  if (
    !ALLOWED_MANUAL_SESSION_DURATION_MINUTES.has(durationMinutes)
  ) {
    throw new HttpsError(
      "invalid-argument",
      `Unsupported session duration: ${durationMinutes} min. Allowed: 15, 30, 45, 60.`,
      {
        code: "unsupported_duration",
        durationMinutes,
        allowed: [...ALLOWED_MANUAL_SESSION_DURATION_MINUTES],
      },
    );
  }
}

interface CreateAdminTestSessionRequest {
  studentId: string;
  teacherId: string;
  slotId: string;
  startsAt: string;
  endsAt: string;
  callType: "externalMeeting" | "voiceCall" | "videoCall";
  callProvider?: string;
  idempotencyKey?: string;
}

interface CreateBookingResult {
  bookingId: string;
  sessionId: string;
  lifecycleStatus: string;
  status: string;
  teacherUserId: string;
}

function parseBookingTimestamp(
  raw: string,
  field: "startsAt" | "endsAt",
): Timestamp {
  const date = new Date(raw);
  if (Number.isNaN(date.getTime())) {
    throw new HttpsError(
      "invalid-argument",
      `Invalid ${field}.`,
      { code: "invalid_timestamp", field },
    );
  }
  try {
    return Timestamp.fromDate(date);
  } catch (error) {
    const reason = error instanceof Error ? error.message : String(error);
    throw new HttpsError(
      "invalid-argument",
      `Invalid ${field}.`,
      { code: "invalid_timestamp", field, reason },
    );
  }
}

async function runPostBookingSideEffects(
  db: FirebaseFirestore.Firestore,
  input: {
    teacherProfileId: string;
    studentId: string;
    sessionId: string;
    bookingId: string;
  },
): Promise<void> {
  try {
    const teacherUserId = await resolveTeacherProfileUserId(
      db,
      input.teacherProfileId,
    );
    await recordTerminalTransition(db, {
      type: "booking_confirmed",
      teacherId: teacherUserId,
      studentId: input.studentId,
    });
    await enqueueSessionNotification(db, {
      sessionId: input.sessionId,
      aggregateId: input.bookingId,
      kind: "bookingConfirmed",
      recipientUserIds: [teacherUserId, input.studentId],
    });
  } catch (error) {
    console.error(
      `createAdminTestQuranSession post-effects failed bookingId=${input.bookingId}:`,
      error,
    );
  }
}

export const createAdminTestQuranSession = onCall(
  sessionCallableHttpsOptions,
  async (request) => {
    try {
      return await handleCreateAdminTestSession(request);
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }
      console.error("createAdminTestQuranSession unhandled error:", error);
      throw new HttpsError("internal", "Test session creation failed.");
    }
  },
);

async function handleCreateAdminTestSession(
  request: CallableRequest<unknown>,
): Promise<CreateBookingResult> {
  // 1. Require Admin
  const adminId = requireAdmin(request);

  const data = request.data as CreateAdminTestSessionRequest;
  if (!data.studentId || !data.teacherId || !data.slotId || !data.startsAt || !data.endsAt) {
    throw new HttpsError("invalid-argument", "Missing required fields.");
  }

  // 1b. Validate session duration is in the allowed set (15/30/45/60 min).
  // Rejects invalid durations like 12h before any Firestore work happens.
  assertAllowedSessionDuration(data.startsAt, data.endsAt);

  // 2. Validate Call Type
  try {
    assertValidCallType(data.callType);
  } catch {
    throw lifecycleError(
      "unsupported_session_mode",
      "Unsupported session mode.",
      { callType: data.callType },
    );
  }

  const db = getFirestore();

  const idempotencyKey =
    data.idempotencyKey?.trim() ||
    `admin_test:${data.studentId}:${data.slotId}:${data.startsAt}`;

  const operationKey = buildOperationKey(
    "create_test_session",
    `${data.studentId}:${data.slotId}`,
    idempotencyKey,
  );

  const platformSnap = await db
    .collection("quran_session_platform_config")
    .doc("global")
    .get();
  const platformConfig = platformSnap.data() ?? {};

  const { result, replayed } = await runIdempotentOperation(
    {
      db,
      operationKey,
      actorId: adminId,
      action: "create_test_session",
    },
    async (tx) => {
      const startsAt = parseBookingTimestamp(data.startsAt, "startsAt");
      const endsAt = parseBookingTimestamp(data.endsAt, "endsAt");
      const bookingRef = db.collection("quran_bookings").doc();
      const sessionRef = db.collection("quran_sessions").doc();
      const lockRef = db.collection("quran_slot_locks").doc(data.slotId);
      const now = nowServer();

      // Free individual booking
      const bookingType = "individual";
      const serverPricingType = "free";
      const paymentStatus = "not_required";

      const draftGuard = validateTransition({
        currentStatus: null,
        action: "create_draft",
        actor: "student",
      });
      const nextGuard = validateTransition({
        currentStatus: draftGuard.to,
        action: "confirm_free_booking",
        actor: "student",
      });
      const lifecycleStatus = nextGuard.to;

      // 3. Verify Student Exists
      const studentSnap = await tx.get(db.collection("users").doc(data.studentId));
      if (!studentSnap.exists) {
        throw new HttpsError("not-found", "Student not found.");
      }

      // 4. Verify Teacher Exists & Approved
      const teacherSnap = await tx.get(
        db.collection("quran_teacher_profiles").doc(data.teacherId),
      );
      if (!teacherSnap.exists) {
        throw new HttpsError("not-found", "Teacher profile not found.");
      }
      const teacherData = teacherSnap.data() ?? {};
      
      if (teacherData.verificationStatus !== "verified") {
         throw new HttpsError("failed-precondition", "Teacher is not approved.");
      }
      if (teacherData.isActive !== true) {
         throw new HttpsError("failed-precondition", "Teacher is suspended or inactive.");
      }

      // Check slot lock
      const lockSnap = await tx.get(lockRef);
      if (lockSnap.exists) {
        throw new HttpsError("already-exists", "Slot unavailable. Duplicate or conflicting session.");
      }

      let resolvedCall;
      try {
        resolvedCall = resolveCallProviderForBooking({
          callType: data.callType,
          sessionId: sessionRef.id,
          teacherProfile: teacherData,
          platformConfig,
          clientCallProvider: data.callProvider,
        });
      } catch (error) {
        mapCallProviderResolverError(error, data.callProvider);
      }

      if (
        data.callType === "externalMeeting" &&
        resolvedCall.meetingLink == null
      ) {
        throw lifecycleError(
          "meeting_link_required",
          "Teacher has no external meeting URL configured.",
          { teacherId: data.teacherId },
        );
      }

      const participants = buildIndividualParticipants(
        data.teacherId,
        data.studentId,
      );
      const meetingLink = resolvedCall.meetingLink;
      const teacherUserId = teacherProfileUserIdFromData(
        data.teacherId,
        teacherData,
      );

      // Lock slot
      tx.set(lockRef, {
        lockId: data.slotId,
        slotId: data.slotId,
        teacherId: data.teacherId,
        aggregateId: bookingRef.id,
        lockType: "hard",
        lockedAt: now,
        expiresAt: Timestamp.fromDate(new Date("2099-01-01T00:00:00.000Z")),
      });

      tx.set(bookingRef, {
        bookingId: bookingRef.id,
        aggregateId: bookingRef.id,
        sessionId: sessionRef.id,
        studentId: data.studentId,
        teacherId: data.teacherId,
        teacherUserId,
        slotId: data.slotId,
        startsAt,
        endsAt,
        bookingType,
        callType: data.callType,
        callProvider: resolvedCall.callProvider,
        pricingType: serverPricingType,
        priceAmount: 0,
        priceCurrency: "USD",
        amountPaidUsd: null,
        paymentStatus,
        paymentProvider: "none",
        paymentReference: null,
        studentNote: "Admin Test Session",
        lifecycleStatus,
        status: legacyStatusForLifecycle(lifecycleStatus),
        createdAt: now,
        updatedAt: now,
      });

      tx.set(sessionRef, {
        sessionId: sessionRef.id,
        bookingId: bookingRef.id,
        aggregateId: bookingRef.id,
        studentId: data.studentId,
        teacherId: data.teacherId,
        teacherUserId,
        startsAt,
        endsAt,
        bookingType,
        callType: data.callType,
        callProvider: resolvedCall.callProvider,
        providerSessionId: resolvedCall.providerSessionId,
        joinToken: resolvedCall.joinToken,
        participants,
        lifecycleStatus,
        status: legacyStatusForLifecycle(lifecycleStatus),
        meetingLink,
        paymentReference: null,
        createdAt: now,
        updatedAt: now,
      });

      appendAuditEvent(tx, db, {
        aggregateId: bookingRef.id,
        bookingId: bookingRef.id,
        sessionId: sessionRef.id,
        actorId: adminId,
        actorRole: "admin",
        action: "create_booking",
        previousStatus: null,
        newStatus: lifecycleStatus,
        source: "admin_test",
        reason: "Manually created by admin for testing/support",
      });

      const bookingResult: CreateBookingResult = {
        bookingId: bookingRef.id,
        sessionId: sessionRef.id,
        lifecycleStatus,
        status: legacyStatusForLifecycle(lifecycleStatus),
        teacherUserId,
      };
      return bookingResult;
    },
  );

  if (!replayed && result.lifecycleStatus === "scheduled") {
    await runPostBookingSideEffects(db, {
      teacherProfileId: data.teacherId,
      studentId: data.studentId,
      sessionId: result.sessionId,
      bookingId: result.bookingId,
    });
  }

  return result;
}

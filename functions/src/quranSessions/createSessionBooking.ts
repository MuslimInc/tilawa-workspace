import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

import { appendAuditEvent } from "./aggregateWriteService";
import {
  assertBookingEligible,
  loadBookingEligibilityContext,
} from "./bookingEligibilityService";
import {
  buildOperationKey,
  runIdempotentOperation,
} from "./idempotencyService";
import { lifecycleError } from "./lifecycleErrors";
import { recordTerminalTransition } from "./metricsAggregationService";
import { enqueueSessionNotification } from "./notificationOutboxService";
import {
  assertPaidBookingAllowed,
  PAYMENT_PROVIDER_ENABLED,
} from "./paymentProviderStatus";
import { requireAuthenticatedUid } from "./sessionAuth";
import { validateTransition } from "./sessionLifecycleGuard";
import { resolveMeetingLink } from "./meetingLinkResolver";
import {
  legacyStatusForLifecycle,
  nowServer,
} from "./sessionLifecycleService";

interface CreateSessionBookingRequest {
  teacherId: string;
  slotId: string;
  startsAt: string;
  endsAt: string;
  callType: "externalMeeting" | "voiceCall" | "videoCall";
  pricingType: "free" | "fixedPerSession" | "subscription";
  paymentReference?: string;
  studentNote?: string;
  idempotencyKey?: string;
}

interface CreateBookingResult {
  bookingId: string;
  sessionId: string;
  lifecycleStatus: string;
  status: string;
}

function defaultCreateBookingIdempotencyKey(
  studentId: string,
  slotId: string,
  startsAt: string,
): string {
  return `${studentId}:${slotId}:${startsAt}`;
}

export const createSessionBooking = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const studentId = requireAuthenticatedUid(request);
    const data = request.data as CreateSessionBookingRequest;
    if (!data.teacherId || !data.slotId || !data.startsAt || !data.endsAt) {
      throw new HttpsError("invalid-argument", "Missing required fields.");
    }

    const db = getFirestore();

    const eligibility = await loadBookingEligibilityContext(
      db,
      studentId,
      data.teacherId,
    );
    const pricing = assertBookingEligible(eligibility, new Date());
    const serverPricingType = pricing.isPaid ? "fixedPerSession" : "free";

    try {
      assertPaidBookingAllowed(serverPricingType);
    } catch {
      throw lifecycleError(
        "payment_provider_unavailable",
        "Paid bookings are disabled until payment provider is configured.",
        { pricingType: serverPricingType },
      );
    }

    if (
      pricing.isPaid &&
      !data.paymentReference?.trim() &&
      PAYMENT_PROVIDER_ENABLED
    ) {
      throw new HttpsError(
        "invalid-argument",
        "paymentReference required for paid bookings.",
      );
    }

    const idempotencyKey =
      data.idempotencyKey?.trim() ||
      defaultCreateBookingIdempotencyKey(
        studentId,
        data.slotId,
        data.startsAt,
      );
    const operationKey = buildOperationKey(
      "create_booking",
      `${studentId}:${data.slotId}`,
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
        actorId: studentId,
        action: "create_booking",
      },
      async (tx) => {
        const startsAt = Timestamp.fromDate(new Date(data.startsAt));
        const endsAt = Timestamp.fromDate(new Date(data.endsAt));
        const bookingRef = db.collection("quran_bookings").doc();
        const sessionRef = db.collection("quran_sessions").doc();
        const lockRef = db.collection("quran_slot_locks").doc(data.slotId);
        const now = nowServer();

        const isFree = !pricing.isPaid;
        const bookingAction = isFree ? "confirm_free_booking" : "initiate_payment";
        const draftGuard = validateTransition({
          currentStatus: null,
          action: "create_draft",
          actor: "student",
        });
        const nextGuard = validateTransition({
          currentStatus: draftGuard.to,
          action: bookingAction,
          actor: "student",
        });
        const lifecycleStatus = nextGuard.to;
        const sessionLifecycleStatus = lifecycleStatus;

        const lockSnap = await tx.get(lockRef);
        if (lockSnap.exists) {
          throw new HttpsError("already-exists", "Slot unavailable.");
        }

        const teacherSnap = await tx.get(
          db.collection("quran_teacher_profiles").doc(data.teacherId),
        );
        const meetingLink = resolveMeetingLink(
          data.callType,
          teacherSnap.data() ?? {},
          platformConfig,
        );
        if (data.callType === "externalMeeting" && meetingLink == null) {
          throw lifecycleError(
            "meeting_link_required",
            "Teacher has no external meeting URL configured.",
            { teacherId: data.teacherId },
          );
        }

        tx.set(lockRef, {
          lockId: data.slotId,
          slotId: data.slotId,
          teacherId: data.teacherId,
          aggregateId: bookingRef.id,
          lockType: lifecycleStatus === "scheduled" ? "hard" : "soft",
          lockedAt: now,
          expiresAt:
            lifecycleStatus === "scheduled"
              ? Timestamp.fromDate(new Date("2099-01-01T00:00:00.000Z"))
              : Timestamp.fromMillis(Date.now() + 10 * 60 * 1000),
        });

        tx.set(bookingRef, {
          bookingId: bookingRef.id,
          aggregateId: bookingRef.id,
          sessionId: sessionRef.id,
          studentId,
          teacherId: data.teacherId,
          slotId: data.slotId,
          startsAt,
          endsAt,
          callType: data.callType,
          pricingType: serverPricingType,
          priceAmount: pricing.amount,
          priceCurrency: pricing.currencyCode,
          amountPaidUsd: null,
          paymentReference: data.paymentReference ?? null,
          studentNote: data.studentNote ?? null,
          lifecycleStatus,
          status: legacyStatusForLifecycle(lifecycleStatus),
          createdAt: now,
          updatedAt: now,
        });

        tx.set(sessionRef, {
          sessionId: sessionRef.id,
          bookingId: bookingRef.id,
          aggregateId: bookingRef.id,
          studentId,
          teacherId: data.teacherId,
          startsAt,
          endsAt,
          callType: data.callType,
          lifecycleStatus: sessionLifecycleStatus,
          status: legacyStatusForLifecycle(sessionLifecycleStatus),
          meetingLink,
          createdAt: now,
          updatedAt: now,
        });

        appendAuditEvent(tx, db, {
          aggregateId: bookingRef.id,
          bookingId: bookingRef.id,
          sessionId: sessionRef.id,
          actorId: studentId,
          actorRole: "student",
          action: "create_booking",
          previousStatus: null,
          newStatus: lifecycleStatus,
          source: "mobileApp",
        });

        return {
          bookingId: bookingRef.id,
          sessionId: sessionRef.id,
          lifecycleStatus,
          status: legacyStatusForLifecycle(lifecycleStatus),
        } satisfies CreateBookingResult;
      },
    );

    if (!replayed && result.lifecycleStatus === "scheduled") {
      await recordTerminalTransition(db, {
        type: "booking_confirmed",
        teacherId: data.teacherId,
        studentId,
      });
      await enqueueSessionNotification(db, {
        sessionId: result.sessionId,
        aggregateId: result.bookingId,
        kind: "bookingConfirmed",
        recipientUserIds: [data.teacherId, studentId],
      });
    }

    return result;
  },
);

import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

import { appendAuditEvent } from "./aggregateWriteService";
import {
  assertBookingEligible,
  countStudentUpcomingBookings,
  loadBookingEligibilityContext,
} from "./bookingEligibilityService";
import {
  buildOperationKey,
  runIdempotentOperation,
} from "./idempotencyService";
import { lifecycleError } from "./lifecycleErrors";
import { generateManualPaymentReference } from "./manualPaymentReference";
import { recordTerminalTransition } from "./metricsAggregationService";
import { enqueueSessionNotification } from "./notificationOutboxService";
import { isPaymentProviderEnabled } from "./payment/envGate";
import {
  computePlatformFee,
  computeTeacherAmount,
  resolvePaymentProvider,
} from "./payment/paymentProviderRegistry";
import { assertPaidBookingAllowedForMarket } from "./paymentProviderStatus";
import { requireAuthenticatedUid, requireValidSessionEpoch } from "./sessionAuth";
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
import { buildAllowedActionsDenorm } from "./sessionAllowedActionsService";
import {
  BOOKING_IDEMPOTENCY_DEDUPE_MS,
  MANUAL_PAYMENT_SLOT_HOLD_MS,
  PENDING_PAYMENT_SLOT_HOLD_MS,
} from "./platformSchedulingPolicy";

interface CreateSessionBookingRequest {
  teacherId: string;
  slotId: string;
  startsAt: string;
  endsAt: string;
  callType: "externalMeeting" | "voiceCall" | "videoCall";
  bookingType?: "individual" | "group";
  callProvider?: string;
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
  paymentReference?: string;
  clientConfirmToken?: string;
  paymentIntentId?: string;
}

function defaultCreateBookingIdempotencyKey(
  studentId: string,
  slotId: string,
  startsAt: string,
): string {
  return `${studentId}:${slotId}:${startsAt}`;
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
    lifecycleStatus: string;
  },
): Promise<void> {
  try {
    const teacherUserId = await resolveTeacherProfileUserId(
      db,
      input.teacherProfileId,
    );
    if (input.lifecycleStatus === "scheduled") {
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
      return;
    }
    if (input.lifecycleStatus === "pending_tutor_approval") {
      await enqueueSessionNotification(db, {
        sessionId: input.sessionId,
        aggregateId: input.bookingId,
        kind: "bookingRequestReceived",
        recipientUserIds: [teacherUserId],
      });
    }
  } catch (error) {
    console.error(
      `createSessionBooking post-effects failed bookingId=${input.bookingId}:`,
      error,
    );
  }
}

export const createSessionBooking = onCall(
  sessionCallableHttpsOptions,
  async (request) => {
    try {
      return await handleCreateSessionBooking(request);
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }
      console.error("createSessionBooking unhandled error:", error);
      throw new HttpsError("internal", "Booking failed.");
    }
  },
);

async function handleCreateSessionBooking(
  request: CallableRequest<unknown>,
): Promise<CreateBookingResult> {
  const studentId = requireAuthenticatedUid(request);
    await requireValidSessionEpoch(request, studentId);
    const data = request.data as CreateSessionBookingRequest;
    if (!data.teacherId || !data.slotId || !data.startsAt || !data.endsAt) {
      throw new HttpsError("invalid-argument", "Missing required fields.");
    }

    const bookingType = data.bookingType ?? "individual";
    if (bookingType !== "individual") {
      throw lifecycleError(
        "group_booking_not_supported",
        "Only individual 1:1 bookings are supported in Free Beta.",
        { bookingType },
      );
    }

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

    const startsAtDate = new Date(data.startsAt);
    const endsAtDate = new Date(data.endsAt);
    if (Number.isNaN(startsAtDate.getTime()) || Number.isNaN(endsAtDate.getTime())) {
      throw new HttpsError("invalid-argument", "Invalid session timestamps.");
    }

    const eligibility = await loadBookingEligibilityContext(
      db,
      studentId,
      data.teacherId,
    );

    if (eligibility.market.sessionMode === "videoOnly") {
      if (data.callType !== "videoCall") {
        throw lifecycleError(
          "unsupported_session_mode",
          "Only in-app video sessions are allowed in this market.",
          { callType: data.callType },
        );
      }
    }

    const upcomingCount = await countStudentUpcomingBookings(db, studentId);
    const pricing = assertBookingEligible(eligibility, new Date(), {
      teacherId: data.teacherId,
      startsAt: startsAtDate,
      upcomingCount,
    });
    const serverPricingType = pricing.isPaid ? "fixedPerSession" : "free";

    const paymentProviderEnabled = isPaymentProviderEnabled();
    const useManualPayment =
      pricing.isPaid &&
      eligibility.market.manualPaymentEnabled &&
      !paymentProviderEnabled;

    try {
      assertPaidBookingAllowedForMarket(serverPricingType, {
        manualPaymentEnabled: eligibility.market.manualPaymentEnabled,
        paymentProviderEnabled,
      });
    } catch {
      throw lifecycleError(
        "payment_provider_unavailable",
        "Paid bookings are disabled until payment provider is configured.",
        { pricingType: serverPricingType },
      );
    }

    if (pricing.isPaid && data.paymentReference?.trim() && !paymentProviderEnabled) {
      throw new HttpsError(
        "invalid-argument",
        "paymentReference not accepted when payment provider is disabled.",
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
        dedupeWindowMs: BOOKING_IDEMPOTENCY_DEDUPE_MS,
      },
      async (tx) => {
        const startsAt = parseBookingTimestamp(data.startsAt, "startsAt");
        const endsAt = parseBookingTimestamp(data.endsAt, "endsAt");
        const bookingRef = db.collection("quran_bookings").doc();
        const sessionRef = db.collection("quran_sessions").doc();
        const lockRef = db.collection("quran_slot_locks").doc(data.slotId);
        const now = nowServer();

        const isFree = !pricing.isPaid;
        const bookingMode = eligibility.market.bookingMode;
        const bookingAction = isFree
          ? bookingMode === "requiresTutorApproval"
            ? "submit_booking_request"
            : "confirm_free_booking"
          : "initiate_payment";
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
        const paymentStatus = isFree ? "not_required" : "pending";

        const lockSnap = await tx.get(lockRef);
        if (lockSnap.exists) {
          const lockData = lockSnap.data() ?? {};
          const lockExpiresAt = lockData.expiresAt as Timestamp | undefined;
          if (
            lockExpiresAt == null ||
            lockExpiresAt.toMillis() > Date.now()
          ) {
            throw new HttpsError("already-exists", "Slot unavailable.");
          }
        }

        const teacherSnap = await tx.get(
          db.collection("quran_teacher_profiles").doc(data.teacherId),
        );
        const teacherData = teacherSnap.data() ?? {};
        let resolvedCall;
        try {
          resolvedCall = resolveCallProviderForBooking({
            callType: data.callType,
            sessionId: sessionRef.id,
            teacherProfile: teacherData,
            platformConfig,
            clientCallProvider: data.callProvider,
            sessionMode: eligibility.market.sessionMode,
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

        const paymentHoldMs = useManualPayment
          ? MANUAL_PAYMENT_SLOT_HOLD_MS
          : PENDING_PAYMENT_SLOT_HOLD_MS;
        const approvalSlaMs = eligibility.market.tutorApprovalSlaMs;
        const teacherUserId = teacherProfileUserIdFromData(
          data.teacherId,
          teacherData,
        );
        const participants = buildIndividualParticipants(
          data.teacherId,
          studentId,
        );
        const meetingLink = resolvedCall.meetingLink;
        const manualPaymentReference = useManualPayment
          ? generateManualPaymentReference(bookingRef.id)
          : null;
        const allowedActionsDenorm = buildAllowedActionsDenorm({
          studentId,
          teacherUserId,
          lifecycleStatus,
          startsAt: startsAt.toDate(),
          endsAt: endsAt.toDate(),
          joinWindowLeadMs: eligibility.market.joinWindowLeadMs,
        });

        tx.set(lockRef, {
          lockId: data.slotId,
          slotId: data.slotId,
          teacherId: data.teacherId,
          aggregateId: bookingRef.id,
          lockType:
            lifecycleStatus === "scheduled" ||
            lifecycleStatus === "pending_tutor_approval"
              ? "hard"
              : "soft",
          lockedAt: now,
          expiresAt:
            lifecycleStatus === "scheduled"
              ? Timestamp.fromDate(new Date("2099-01-01T00:00:00.000Z"))
              : lifecycleStatus === "pending_tutor_approval"
                ? Timestamp.fromMillis(Date.now() + approvalSlaMs)
                : Timestamp.fromMillis(Date.now() + paymentHoldMs),
        });

        const feeSnapshot = {
          amount: pricing.amount,
          currencyCode: pricing.currencyCode,
          pricingType: serverPricingType,
          pricingSource: eligibility.pricingSource,
          policyVersion: eligibility.market.policyVersion,
          capturedAt: now,
        };

        const bookingDoc: Record<string, unknown> = {
          bookingId: bookingRef.id,
          aggregateId: bookingRef.id,
          sessionId: sessionRef.id,
          studentId,
          teacherId: data.teacherId,
          teacherUserId,
          slotId: data.slotId,
          startsAt,
          endsAt,
          bookingType,
          callType: data.callType,
          callProvider: resolvedCall.callProvider,
          pricingType: serverPricingType,
          priceAmount: pricing.amount,
          priceCurrency: pricing.currencyCode,
          feeSnapshot,
          countryCode: eligibility.student.countryCode,
          cityId: eligibility.student.cityId,
          joinWindowLeadMs: eligibility.market.joinWindowLeadMs,
          amountPaidUsd: null,
          paymentStatus,
          paymentProvider: isFree
            ? "none"
            : useManualPayment
              ? "manual_off_app"
              : resolvePaymentProvider().kind,
          paymentReference: manualPaymentReference,
          studentNote: data.studentNote ?? null,
          lifecycleStatus,
          status: legacyStatusForLifecycle(lifecycleStatus),
          createdAt: now,
          updatedAt: now,
          ...allowedActionsDenorm,
        };
        if (lifecycleStatus === "pending_tutor_approval") {
          bookingDoc.approvalRequestedAt = now;
          bookingDoc.approvalExpiresAt = Timestamp.fromMillis(
            Date.now() + approvalSlaMs,
          );
        }
        if (lifecycleStatus === "pending_payment") {
          bookingDoc.paymentExpiresAt = Timestamp.fromMillis(
            Date.now() + paymentHoldMs,
          );
        }
        if (isFree) {
          bookingDoc.bookingModeAtCreation = bookingMode;
        }
        tx.set(bookingRef, bookingDoc);

        tx.set(sessionRef, {
          sessionId: sessionRef.id,
          bookingId: bookingRef.id,
          aggregateId: bookingRef.id,
          studentId,
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
          lifecycleStatus: sessionLifecycleStatus,
          status: legacyStatusForLifecycle(sessionLifecycleStatus),
          meetingLink,
          paymentReference: manualPaymentReference,
          createdAt: now,
          updatedAt: now,
          feeSnapshot,
          ...allowedActionsDenorm,
        });

        let paymentReference: string | undefined;
        let clientConfirmToken: string | undefined;
        let paymentIntentId: string | undefined;

        if (useManualPayment) {
          paymentReference = manualPaymentReference ?? undefined;
        } else if (!isFree) {
          const provider = resolvePaymentProvider();
          const platformFee = computePlatformFee(pricing.amount);
          const tax = 0;
          const teacherAmount = computeTeacherAmount(
            pricing.amount,
            platformFee,
            tax,
          );
          const intent = await provider.createPaymentIntent({
            db,
            tx,
            bookingId: bookingRef.id,
            aggregateId: bookingRef.id,
            studentId,
            amount: pricing.amount,
            currency: pricing.currencyCode,
            platformFee,
            teacherAmount,
            tax,
            idempotencyKey,
            expiresAt: new Date(Date.now() + paymentHoldMs),
          });
          paymentReference = intent.paymentReference;
          clientConfirmToken = intent.clientConfirmToken;
          paymentIntentId = intent.paymentIntentId;

          tx.set(
            bookingRef,
            {
              paymentReference: intent.paymentReference,
              providerTransactionId: intent.providerIntentId,
            },
            { merge: true },
          );
          tx.set(
            sessionRef,
            { paymentReference: intent.paymentReference },
            { merge: true },
          );
        }

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

        const bookingResult: CreateBookingResult = {
          bookingId: bookingRef.id,
          sessionId: sessionRef.id,
          lifecycleStatus,
          status: legacyStatusForLifecycle(lifecycleStatus),
        };
        if (paymentReference !== undefined) {
          bookingResult.paymentReference = paymentReference;
        }
        if (clientConfirmToken !== undefined) {
          bookingResult.clientConfirmToken = clientConfirmToken;
        }
        if (paymentIntentId !== undefined) {
          bookingResult.paymentIntentId = paymentIntentId;
        }
        return bookingResult;
      },
    );

    if (
      !replayed &&
      (result.lifecycleStatus === "scheduled" ||
        result.lifecycleStatus === "pending_tutor_approval")
    ) {
      await runPostBookingSideEffects(db, {
        teacherProfileId: data.teacherId,
        studentId,
        sessionId: result.sessionId,
        bookingId: result.bookingId,
        lifecycleStatus: result.lifecycleStatus,
      });
    }

  return result;
}

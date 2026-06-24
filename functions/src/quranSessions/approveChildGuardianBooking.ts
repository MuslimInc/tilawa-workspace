import { onCall } from "firebase-functions/v2/https";
import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";

import { isChild } from "./bookingEligibilityService";
import { lifecycleError } from "./lifecycleErrors";
import {
  requireAuthenticatedUid,
  requireValidSessionEpoch,
} from "./sessionAuth";
import { sessionCallableHttpsOptions } from "./sessionCallableOptions";

interface ApproveChildGuardianBookingRequest {
  studentId: string;
  sessionEpoch?: number;
}

interface ApproveChildGuardianBookingResponse {
  studentId: string;
  guardianId: string;
  approvedAt: string;
}

/**
 * Records guardian consent for a child student's Quran Sessions bookings.
 */
export const approveChildGuardianBooking = onCall(
  sessionCallableHttpsOptions,
  async (request): Promise<ApproveChildGuardianBookingResponse> => {
    const guardianId = requireAuthenticatedUid(request);
    await requireValidSessionEpoch(request, guardianId);

    const data = request.data as ApproveChildGuardianBookingRequest;
    const studentId = data?.studentId?.trim();
    if (!studentId) {
      throw lifecycleError(
        "guardian_approval_invalid",
        "Student id is required.",
      );
    }
    if (studentId === guardianId) {
      throw lifecycleError(
        "guardian_approval_invalid",
        "A child account cannot approve its own bookings.",
      );
    }

    const db = getFirestore();
    const now = new Date();
    const [studentSnap, policySnap, guardianSnap] = await Promise.all([
      db.collection("users").doc(studentId).get(),
      db.collection("quran_session_platform_config").doc("global").get(),
      db.collection("users").doc(guardianId).get(),
    ]);

    const studentProfile =
      (studentSnap.data()?.quranSessionsProfile as Record<string, unknown>) ??
      {};
    if (!studentSnap.exists || studentSnap.data()?.quranSessionsProfile == null) {
      throw lifecycleError(
        "profile_incomplete",
        "Student profile not found.",
        { missingFields: ["profile"] },
      );
    }

    const childAgeThreshold =
      (policySnap.data()?.childAgeThreshold as number) ?? 14;
    const studentDob = parseDate(studentProfile.dateOfBirth);
    if (!isChild(studentDob, childAgeThreshold, now)) {
      throw lifecycleError(
        "guardian_approval_invalid",
        "Guardian approval applies only to child student profiles.",
      );
    }

    const guardianProfile = guardianSnap.data()?.quranSessionsProfile as
      | Record<string, unknown>
      | undefined;
    const guardianDob = parseDate(guardianProfile?.dateOfBirth);
    if (guardianDob != null && isChild(guardianDob, childAgeThreshold, now)) {
      throw lifecycleError(
        "guardian_approval_invalid",
        "Guardian must be an adult account.",
      );
    }

    const approvedAt = Timestamp.now();
    await db.collection("users").doc(studentId).set(
      {
        quranSessionsProfile: {
          guardianId,
          guardianChildBookingApprovedAt: approvedAt,
          updatedAt: FieldValue.serverTimestamp(),
        },
      },
      { merge: true },
    );

    return {
      studentId,
      guardianId,
      approvedAt: approvedAt.toDate().toISOString(),
    };
  },
);

function parseDate(raw: unknown): Date | null {
  if (raw instanceof Timestamp) {
    return raw.toDate();
  }
  if (raw instanceof Date) {
    return raw;
  }
  if (typeof raw === "string" && raw.length > 0) {
    const parsed = new Date(raw);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }
  return null;
}

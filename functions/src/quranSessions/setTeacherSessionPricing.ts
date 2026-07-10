import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { requireAdmin } from "./sessionAuth";
import { sessionCallableHttpsOptions } from "./sessionCallableOptions";

/**
 * Admin-only: sets or clears a teacher's session price override.
 *
 * Pricing is admin-controlled — a teacher can never set their own price (see
 * `teacherProfileTrustFieldsUnchanged` in firestore.rules). When enabled with
 * `amount: 0` the teacher teaches for free even in a paid market; a positive
 * amount overrides the market default. Clearing (`enabled: false`) falls back
 * to the market price. The value is consumed by
 * `loadBookingEligibilityContext`, so it flows into both the pricing quote and
 * the booking's recorded fee snapshot.
 */

export interface SetTeacherSessionPricingRequest {
  teacherId: string;
  enabled: boolean;
  amount?: number;
  currencyCode?: string;
}

/**
 * Pure validation + document shape. Throws `HttpsError('invalid-argument')`
 * on bad input. Returned map is merged onto the teacher profile doc.
 */
export function buildSessionPriceOverrideWrite(
  data: SetTeacherSessionPricingRequest,
  adminUid: string,
): Record<string, unknown> {
  if (!data.teacherId || typeof data.teacherId !== "string") {
    throw new HttpsError("invalid-argument", "teacherId required.");
  }
  if (typeof data.enabled !== "boolean") {
    throw new HttpsError("invalid-argument", "enabled (boolean) required.");
  }

  if (!data.enabled) {
    return {
      sessionPriceOverride: {
        enabled: false,
        updatedAt: FieldValue.serverTimestamp(),
        updatedBy: adminUid,
      },
    };
  }

  const amount = data.amount;
  if (typeof amount !== "number" || !Number.isFinite(amount) || amount < 0) {
    throw new HttpsError(
      "invalid-argument",
      "amount must be a finite number >= 0 (0 = free).",
    );
  }
  const currencyCode =
    typeof data.currencyCode === "string" && data.currencyCode.trim().length > 0
      ? data.currencyCode.trim().toUpperCase()
      : null;

  return {
    sessionPriceOverride: {
      enabled: true,
      amount,
      currencyCode,
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: adminUid,
    },
  };
}

export const setTeacherSessionPricing = onCall(
  sessionCallableHttpsOptions,
  async (request) => {
    const adminUid = requireAdmin(request);
    const data = request.data as SetTeacherSessionPricingRequest;
    const patch = buildSessionPriceOverrideWrite(data, adminUid);

    const db = getFirestore();
    const profileRef = db
      .collection("quran_teacher_profiles")
      .doc(data.teacherId);
    const snap = await profileRef.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "Teacher profile not found.");
    }

    await profileRef.set(patch, { merge: true });

    const override = patch.sessionPriceOverride as Record<string, unknown>;
    await db.collection("quran_session_events").add({
      timestamp: FieldValue.serverTimestamp(),
      aggregateId: data.teacherId,
      teacherId: data.teacherId,
      actorId: adminUid,
      actorRole: "admin",
      action: "set_teacher_session_pricing",
      source: "adminPanel",
      overrideEnabled: override.enabled,
      overrideAmount: override.amount ?? null,
      overrideCurrencyCode: override.currencyCode ?? null,
    });

    return {
      teacherId: data.teacherId,
      enabled: override.enabled,
      amount: override.amount ?? null,
      currencyCode: override.currencyCode ?? null,
    };
  },
);

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { requireAdmin } from "./sessionAuth";
import { sessionCallableHttpsOptions } from "./sessionCallableOptions";

export interface CityPricingOverride {
  cityId: string;
  isEnabled: boolean;
  minSessionPrice?: number | null;
}

export interface UpdateMarketPricingConfigRequest {
  countryCode: string;
  isEnabled: boolean;
  minSessionPrice: number;
  currencyCode: string;
  studentBookingEnabled: boolean;
  teacherDiscoveryEnabled: boolean;
  bookingMode: "requiresTutorApproval" | "autoConfirm";
  minBookingNoticeMs: number;
  maxConcurrentUpcomingPerStudent: number;
  joinWindowLeadMs: number;
  tutorApprovalSlaMs: number;
  genderMatchingEnabled: boolean;
  teacherWhitelist: string[] | null;
  paymentProviderEnabled: boolean;
  cities: CityPricingOverride[];
}

export function validateUpdateMarketPricingConfig(data: Partial<UpdateMarketPricingConfigRequest>): void {
  if (!data.countryCode || typeof data.countryCode !== "string") {
    throw new HttpsError("invalid-argument", "countryCode required.");
  }
  if (typeof data.isEnabled !== "boolean") {
    throw new HttpsError("invalid-argument", "isEnabled (boolean) required.");
  }
  if (typeof data.minSessionPrice !== "number" || !Number.isFinite(data.minSessionPrice) || data.minSessionPrice < 0) {
    throw new HttpsError("invalid-argument", "minSessionPrice must be a finite number >= 0.");
  }
  if (!data.currencyCode || typeof data.currencyCode !== "string") {
    throw new HttpsError("invalid-argument", "currencyCode required.");
  }
  
  // Validate new policy fields
  if (typeof data.studentBookingEnabled !== "boolean") {
    throw new HttpsError("invalid-argument", "studentBookingEnabled (boolean) required.");
  }
  if (typeof data.teacherDiscoveryEnabled !== "boolean") {
    throw new HttpsError("invalid-argument", "teacherDiscoveryEnabled (boolean) required.");
  }
  if (data.bookingMode !== "requiresTutorApproval" && data.bookingMode !== "autoConfirm") {
    throw new HttpsError("invalid-argument", "bookingMode must be 'requiresTutorApproval' or 'autoConfirm'.");
  }
  if (typeof data.minBookingNoticeMs !== "number" || !Number.isFinite(data.minBookingNoticeMs) || data.minBookingNoticeMs < 0) {
    throw new HttpsError("invalid-argument", "minBookingNoticeMs must be a finite number >= 0.");
  }
  if (typeof data.maxConcurrentUpcomingPerStudent !== "number" || !Number.isFinite(data.maxConcurrentUpcomingPerStudent) || data.maxConcurrentUpcomingPerStudent < 0) {
    throw new HttpsError("invalid-argument", "maxConcurrentUpcomingPerStudent must be a finite number >= 0.");
  }
  if (typeof data.joinWindowLeadMs !== "number" || !Number.isFinite(data.joinWindowLeadMs) || data.joinWindowLeadMs < 0) {
    throw new HttpsError("invalid-argument", "joinWindowLeadMs must be a finite number >= 0.");
  }
  if (typeof data.tutorApprovalSlaMs !== "number" || !Number.isFinite(data.tutorApprovalSlaMs) || data.tutorApprovalSlaMs < 0) {
    throw new HttpsError("invalid-argument", "tutorApprovalSlaMs must be a finite number >= 0.");
  }
  if (typeof data.genderMatchingEnabled !== "boolean") {
    throw new HttpsError("invalid-argument", "genderMatchingEnabled (boolean) required.");
  }
  if (data.teacherWhitelist !== null && !Array.isArray(data.teacherWhitelist)) {
    throw new HttpsError("invalid-argument", "teacherWhitelist must be an array or null.");
  }
  if (typeof data.paymentProviderEnabled !== "boolean") {
    throw new HttpsError("invalid-argument", "paymentProviderEnabled (boolean) required.");
  }

  if (data.cities !== undefined) {
    if (!Array.isArray(data.cities)) {
      throw new HttpsError("invalid-argument", "cities must be an array.");
    }
    for (const city of data.cities) {
      if (!city.cityId || typeof city.cityId !== "string") {
        throw new HttpsError("invalid-argument", "city.cityId required.");
      }
      if (typeof city.isEnabled !== "boolean") {
        throw new HttpsError("invalid-argument", "city.isEnabled required.");
      }
      if (
        city.minSessionPrice !== undefined &&
        city.minSessionPrice !== null &&
        (typeof city.minSessionPrice !== "number" || !Number.isFinite(city.minSessionPrice) || city.minSessionPrice < 0)
      ) {
        throw new HttpsError("invalid-argument", "city.minSessionPrice must be a finite number >= 0 or null.");
      }
    }
  }
}

export const updateMarketPricingConfig = onCall(
  sessionCallableHttpsOptions,
  async (request) => {
    const adminUid = requireAdmin(request);
    const data = request.data as Partial<UpdateMarketPricingConfigRequest>;

    validateUpdateMarketPricingConfig(data);

    const marketDataPatch = {
      isEnabled: data.isEnabled,
      minSessionPrice: data.minSessionPrice,
      currencyCode: data.currencyCode!.trim().toUpperCase(),
      studentBookingEnabled: data.studentBookingEnabled,
      teacherDiscoveryEnabled: data.teacherDiscoveryEnabled,
      bookingMode: data.bookingMode,
      minBookingNoticeMs: data.minBookingNoticeMs,
      maxConcurrentUpcomingPerStudent: data.maxConcurrentUpcomingPerStudent,
      joinWindowLeadMs: data.joinWindowLeadMs,
      tutorApprovalSlaMs: data.tutorApprovalSlaMs,
      genderMatchingEnabled: data.genderMatchingEnabled,
      teacherWhitelist: data.teacherWhitelist,
      paymentProviderEnabled: data.paymentProviderEnabled,
      updatedBy: adminUid,
      updatedAt: FieldValue.serverTimestamp(),
    };

    if (data.cities) {
      for (const city of data.cities) {
        if (!city.cityId || typeof city.cityId !== "string") {
          throw new HttpsError("invalid-argument", "cityId must be a valid string.");
        }
        if (typeof city.isEnabled !== "boolean") {
          throw new HttpsError("invalid-argument", `isEnabled must be boolean for city ${city.cityId}.`);
        }
        if (city.minSessionPrice != null && (typeof city.minSessionPrice !== "number" || !Number.isFinite(city.minSessionPrice) || city.minSessionPrice < 0)) {
          throw new HttpsError("invalid-argument", `minSessionPrice must be a finite number >= 0 for city ${city.cityId}.`);
        }
      }
    }

    const db = getFirestore();
    const batch = db.batch();

    const countryRef = db.collection("quran_session_market_configs").doc(data.countryCode!);
    batch.set(countryRef, marketDataPatch, { merge: true });

    if (data.cities) {
      for (const city of data.cities) {
        const cityRef = countryRef.collection("cities").doc(city.cityId);
        batch.set(
          cityRef,
          {
            isEnabled: city.isEnabled,
            minSessionPrice: city.minSessionPrice ?? null,
          },
          { merge: true }
        );
      }
    }

    batch.set(db.collection("quran_session_events").doc(), {
      timestamp: FieldValue.serverTimestamp(),
      aggregateId: data.countryCode,
      countryCode: data.countryCode,
      actorId: adminUid,
      actorRole: "admin",
      action: "update_market_pricing",
      source: "adminPanel",
      ...marketDataPatch,
    });

    await batch.commit();

    return { success: true };
  }
);

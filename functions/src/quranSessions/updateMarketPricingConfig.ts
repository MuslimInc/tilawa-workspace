import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { requireAdmin } from "./sessionAuth";
import { sessionCallableHttpsOptions } from "./sessionCallableOptions";
import { validateMarketConfigForBooking } from "./sessionPolicyResolver";

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
  cities: CityPricingOverride[];
}

export const updateMarketPricingConfig = onCall(
  sessionCallableHttpsOptions,
  async (request) => {
    const adminUid = requireAdmin(request);
    const data = request.data as UpdateMarketPricingConfigRequest;

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
    if (!Array.isArray(data.cities)) {
      throw new HttpsError("invalid-argument", "cities array required.");
    }

    const marketDataPatch = {
      isEnabled: data.isEnabled,
      minSessionPrice: data.minSessionPrice,
      currencyCode: data.currencyCode.trim().toUpperCase(),
    };

    // Before writing, validate each city (to fail closed).
    for (const city of data.cities) {
      const cityData = {
        isEnabled: city.isEnabled,
        minSessionPrice: city.minSessionPrice ?? null,
      };
      const validation = validateMarketConfigForBooking(marketDataPatch, cityData, city.cityId);
      if (!validation.valid) {
        throw new HttpsError(
          "failed-precondition",
          `Validation failed for city ${city.cityId}: ${validation.invalidFields.join(", ")} ${validation.missingFields.join(", ")}`
        );
      }
    }

    const db = getFirestore();
    const batch = db.batch();

    const countryRef = db.collection("quran_session_market_configs").doc(data.countryCode);
    batch.set(countryRef, marketDataPatch, { merge: true });

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

    batch.set(db.collection("quran_session_events").doc(), {
      timestamp: FieldValue.serverTimestamp(),
      aggregateId: data.countryCode,
      countryCode: data.countryCode,
      actorId: adminUid,
      actorRole: "admin",
      action: "update_market_pricing",
      source: "adminPanel",
      isEnabled: data.isEnabled,
      minSessionPrice: data.minSessionPrice,
      currencyCode: data.currencyCode,
    });

    await batch.commit();

    return { success: true };
  }
);

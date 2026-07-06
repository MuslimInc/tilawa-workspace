import test from "node:test";
import assert from "node:assert/strict";

import { validateUpdateMarketPricingConfig, UpdateMarketPricingConfigRequest } from "../../src/quranSessions/updateMarketPricingConfig";

test("validateUpdateMarketPricingConfig rejects missing paymentProviderEnabled", () => {
  const data: any = {
    countryCode: "eg",
    isEnabled: true,
    minSessionPrice: 100,
    currencyCode: "egp",
    studentBookingEnabled: true,
    teacherDiscoveryEnabled: true,
    bookingMode: "autoConfirm",
    minBookingNoticeMs: 0,
    maxConcurrentUpcomingPerStudent: 3,
    joinWindowLeadMs: 0,
    tutorApprovalSlaMs: 0,
    genderMatchingEnabled: true,
    teacherWhitelist: null,
    cities: [],
  };
  assert.throws(
    () => validateUpdateMarketPricingConfig(data),
    /paymentProviderEnabled \(boolean\) required/
  );
});

test("validateUpdateMarketPricingConfig accepts valid config", () => {
  const validData: UpdateMarketPricingConfigRequest = {
    countryCode: "eg",
    isEnabled: true,
    minSessionPrice: 100,
    currencyCode: "egp",
    studentBookingEnabled: true,
    teacherDiscoveryEnabled: true,
    bookingMode: "autoConfirm",
    minBookingNoticeMs: 0,
    maxConcurrentUpcomingPerStudent: 3,
    joinWindowLeadMs: 0,
    tutorApprovalSlaMs: 0,
    genderMatchingEnabled: true,
    teacherWhitelist: null,
    paymentProviderEnabled: true,
    cities: [],
  };
  
  assert.doesNotThrow(() => validateUpdateMarketPricingConfig(validData));
});

test("validateUpdateMarketPricingConfig rejects invalid bookingMode", () => {
  const data: any = {
    countryCode: "eg",
    isEnabled: true,
    minSessionPrice: 100,
    currencyCode: "egp",
    studentBookingEnabled: true,
    teacherDiscoveryEnabled: true,
    bookingMode: "invalidMode", // Invalid
    minBookingNoticeMs: 0,
    maxConcurrentUpcomingPerStudent: 3,
    joinWindowLeadMs: 0,
    tutorApprovalSlaMs: 0,
    genderMatchingEnabled: true,
    teacherWhitelist: null,
    paymentProviderEnabled: true,
    cities: [],
  };
  
  assert.throws(
    () => validateUpdateMarketPricingConfig(data),
    /bookingMode must be 'requiresTutorApproval' or 'autoConfirm'/
  );
});

test("validateUpdateMarketPricingConfig rejects invalid city", () => {
  const data: any = {
    countryCode: "eg",
    isEnabled: true,
    minSessionPrice: 100,
    currencyCode: "egp",
    studentBookingEnabled: true,
    teacherDiscoveryEnabled: true,
    bookingMode: "autoConfirm",
    minBookingNoticeMs: 0,
    maxConcurrentUpcomingPerStudent: 3,
    joinWindowLeadMs: 0,
    tutorApprovalSlaMs: 0,
    genderMatchingEnabled: true,
    teacherWhitelist: null,
    paymentProviderEnabled: true,
    cities: [
      {
        cityId: "cairo",
        isEnabled: true,
        minSessionPrice: -10, // Invalid
      }
    ],
  };
  
  assert.throws(
    () => validateUpdateMarketPricingConfig(data),
    /city.minSessionPrice must be a finite number >= 0/
  );
});

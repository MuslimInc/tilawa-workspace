import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { requireAdmin } from "./sessionAuth";
import { sessionCallableHttpsOptions } from "./sessionCallableOptions";
import { loadBookingEligibilityContext } from "./bookingEligibilityService";
import { isMarketEnabled } from "./marketGate";

export interface GetResolvedSessionConfigRequest {
  studentId: string;
  teacherId: string;
}

export function resolveSessionConfigWarnings(context: any): string[] {
  const warnings: string[] = [];
  if (!context.marketEnabled) {
    warnings.push("market_disabled");
  }
  if (
    context.pricing.isPaid &&
    !context.market.paymentProviderEnabled &&
    !context.market.manualPaymentEnabled
  ) {
    warnings.push("paid_but_payment_disabled");
  }
  if (context.market.manualPaymentEnabled && !context.pricing.isPaid) {
    warnings.push("free_blocked_while_manual_payment_enabled");
  }
  if (
    typeof context.student?.countryCode === "string" &&
    context.platform?.marketGate != null &&
    !isMarketEnabled(context.platform.marketGate, context.student.countryCode)
  ) {
    warnings.push("market_not_supported");
  }
  if (!context.teacher.exists || context.teacher.verificationStatus !== "verified") {
    warnings.push("teacher_not_verified");
  }
  if (
    context.market.teacherWhitelist != null &&
    !context.market.teacherWhitelist.includes(context.teacher.id)
  ) {
    warnings.push("teacher_not_whitelisted");
  }
  if (!context.student.exists || context.student.accountStatus !== "active") {
    warnings.push("student_not_active");
  }
  return warnings;
}

export const getResolvedSessionConfig = onCall(
  sessionCallableHttpsOptions,
  async (request) => {
    requireAdmin(request);
    const data = request.data as Partial<GetResolvedSessionConfigRequest>;

    if (!data.studentId || typeof data.studentId !== "string") {
      throw new HttpsError("invalid-argument", "studentId required.");
    }
    if (!data.teacherId || typeof data.teacherId !== "string") {
      throw new HttpsError("invalid-argument", "teacherId required.");
    }

    const db = getFirestore();
    const context = await loadBookingEligibilityContext(db, data.studentId, data.teacherId);

    const resolvedContext = {
      ...context,
      teacher: {
        ...context.teacher,
        id: data.teacherId,
      }
    };
    const warnings = resolveSessionConfigWarnings(resolvedContext);

    return {
      context,
      warnings,
    };
  }
);

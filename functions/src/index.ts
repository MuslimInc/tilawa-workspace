export { verifySupportPurchase } from "./verifySupportPurchase";
export { crashlyticsToGithubIssue } from "./crashlyticsToGithubIssue";
export { verifyRecitationAudio } from "./verifyRecitationAudio";
export { reviewTeacherApplication } from "./reviewTeacherApplication";
export { registerActiveDevice } from "./registerActiveDevice";
export { revokeDevice, signOutOtherDevices } from "./deviceManagement";
export { moderateTeacherProfile } from "./moderateTeacherProfile";
export { moderateQuranSessionsUser } from "./moderateQuranSessionsUser";
export { setTeacherApplicationAccess } from "./setTeacherApplicationAccess";
export { syncTeacherProfileVisibility } from "./syncTeacherProfileVisibility";
export { createSessionBooking } from "./quranSessions/createSessionBooking";
export { respondToBookingRequest } from "./quranSessions/respondToBookingRequest";
export { createAdminTestQuranSession } from "./quranSessions/createAdminTestQuranSession";
export { cancelSessionBooking } from "./quranSessions/cancelSessionBooking";
export { requestSessionReschedule } from "./quranSessions/requestSessionReschedule";
export { confirmSessionReschedule } from "./quranSessions/confirmSessionReschedule";
export { markSessionNoShow } from "./quranSessions/markSessionNoShow";
export { completeSession } from "./quranSessions/completeSession";
export { issueSessionCompensation } from "./quranSessions/issueSessionCompensation";
export { approveSessionRefund } from "./quranSessions/approveSessionRefund";
export {
  openSessionDispute,
  resolveSessionDispute,
} from "./quranSessions/sessionDisputeCallables";
export {
  reportSessionConcern,
  resolveSessionReport,
} from "./quranSessions/sessionReportCallables";
export { expirePendingReservations } from "./quranSessions/expirePendingReservations";
export { finalizeElapsedSessions } from "./quranSessions/finalizeElapsedSessions";
export { deliverSessionNotification } from "./quranSessions/deliverSessionNotification";
export { getWallet, postWalletCredit } from "./quranSessions/walletCallables";
export { confirmBookingPayment } from "./quranSessions/confirmBookingPayment";
export { confirmManualBookingPayment } from "./quranSessions/confirmManualBookingPayment";
export { rejectManualBookingPayment } from "./quranSessions/rejectManualBookingPayment";
export { getBookingPricingQuote } from "./quranSessions/getBookingPricingQuote";
export { getBookingPricingQuotes } from "./quranSessions/getBookingPricingQuotes";
export { setTeacherSessionPricing } from "./quranSessions/setTeacherSessionPricing";
export { updateMarketPricingConfig } from "./quranSessions/updateMarketPricingConfig";
export { issueSessionRtcToken } from "./quranSessions/issueSessionRtcToken";
export { issueDebugLiveKitToken } from "./quranSessions/issueDebugLiveKitToken";
export { recordCallTelemetryEvent } from "./quranSessions/recordCallTelemetryEvent";
export { updatePlatformConfig } from "./quranSessions/updatePlatformConfig";
export { getResolvedSessionConfig } from "./quranSessions/getResolvedSessionConfig";
export { sessionReminders } from "./quranSessions/sessionReminders";
export {
  projectDashboardOnSessionWrite,
  projectDashboardOnScheduleWrite,
  projectDashboardOnOverrideWrite,
  projectDashboardOnTeacherProfileWrite,
  projectDashboardOnUserCountryChange,
  pruneDashboardSummaries,
} from "./quranSessions/dashboardProjection/projectTeacherDashboard";
export { requestUserDeletion } from "./userDeletion/requestUserDeletion";
export { requestSelfAccountDeletion } from "./userDeletion/requestSelfAccountDeletion";
export { cancelUserDeletion } from "./userDeletion/cancelUserDeletion";
export {
  purgeDeletedUsers,
  forcePurgeUser,
} from "./userDeletion/purgeDeletedUsers";
export { lookupDuplicateAccountsByEmail } from "./userDeletion/lookupDuplicateAccountsByEmail";
export { lookupUserAdminClaims } from "./userDeletion/lookupUserAdminClaims";
export { requestDuplicateAccountsDeletion } from "./userDeletion/requestDuplicateAccountsDeletion";
export { purgeFirestoreOrphanUser } from "./userDeletion/purgeFirestoreOrphanUser";

import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging, MulticastMessage } from "firebase-admin/messaging";

import {
  clearInvalidActiveFcmTokens,
  collectActiveFcmTokens,
} from "./quranSessions/fcmTokenService";
import { resolveUserIds } from "./notifications/resolveUserIds";

initializeApp();

interface NotificationDoc {
  title: string;
  body: string;
  targetType: "all" | "single" | "selected";
  targetUserIds: string[];
  actionType: string;
  actionData?: string;
  status: "pending" | "sent" | "failed";
}

/** FCM sendEachForMulticast accepts at most 500 tokens per request. */
const FCM_MULTICAST_LIMIT = 500;

/**
 * Triggered when a new notification document is created in Firestore.
 * Reads the target users' FCM tokens and sends push notifications.
 */
export const sendNotification = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const notification = snapshot.data() as NotificationDoc;
    const notificationRef = snapshot.ref;

    if (notification.status !== "pending") return;

    const db = getFirestore();

    try {
      // 1. Resolve target user IDs
      const userIds = await resolveUserIds(db, notification);
      if (userIds.length === 0) {
        await notificationRef.update({ status: "failed", error: "No target users found" });
        return;
      }

      // 2. Collect active FCM tokens for target users
      const tokenEntries = await collectActiveFcmTokens(db, userIds);
      if (tokenEntries.length === 0) {
        await notificationRef.update({ status: "failed", error: "No FCM tokens found" });
        return;
      }

      // 3. Build shared payload and send in FCM-sized chunks
      const dataPayload: Record<string, string> = {
        title: notification.title,
        body: notification.body,
        actionType: notification.actionType,
      };
      if (notification.actionData) {
        dataPayload.actionData = notification.actionData;
      }

      let successCount = 0;
      let failureCount = 0;

      for (let i = 0; i < tokenEntries.length; i += FCM_MULTICAST_LIMIT) {
        const chunk = tokenEntries.slice(i, i + FCM_MULTICAST_LIMIT);
        const message: MulticastMessage = {
          tokens: chunk.map((entry) => entry.token),
          notification: {
            title: notification.title,
            body: notification.body,
          },
          data: dataPayload,
          android: {
            priority: "high",
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        };

        const response = await getMessaging().sendEachForMulticast(message);
        await clearInvalidActiveFcmTokens(db, chunk, response);
        successCount += response.successCount;
        failureCount += response.failureCount;
      }

      // 4. Update notification status
      await notificationRef.update({
        status: "sent",
        sentAt: Date.now(),
        successCount,
        failureCount,
      });
    } catch (error) {
      console.error("Failed to send notification:", error);
      await notificationRef.update({
        status: "failed",
        error: error instanceof Error ? error.message : "Unknown error",
      });
    }
  }
);



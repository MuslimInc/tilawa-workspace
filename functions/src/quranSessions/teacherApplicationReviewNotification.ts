import { readUserLanguageCode } from "./userLocale";

export const TEACHER_APPLICATION_REVIEWED_ACTION =
  "teacher_application_reviewed";

export interface TeacherApplicationReviewNotificationCopy {
  title: string;
  body: string;
  actionType: string;
}

type SupportedLocale = "ar" | "en";

function resolveLocale(
  localeOrUserData: string | Record<string, unknown> | undefined | null,
): SupportedLocale {
  if (typeof localeOrUserData === "string") {
    return localeOrUserData === "ar" ? "ar" : "en";
  }
  return readUserLanguageCode(localeOrUserData);
}

export function buildTeacherApplicationReviewNotificationCopy(
  status: string,
  localeOrUserData: string | Record<string, unknown> | undefined | null = "en",
): TeacherApplicationReviewNotificationCopy {
  const locale = resolveLocale(localeOrUserData);

  switch (status) {
    case "approved":
      return locale === "ar"
        ? {
            title: "تمت الموافقة على طلب المحفظ",
            body: "تمت الموافقة على طلبك. افتح الإعدادات للمتابعة.",
            actionType: TEACHER_APPLICATION_REVIEWED_ACTION,
          }
        : {
            title: "Teacher application approved",
            body:
              "Your teacher application was approved. Open Settings to continue.",
            actionType: TEACHER_APPLICATION_REVIEWED_ACTION,
          };
    case "rejected":
      return locale === "ar"
        ? {
            title: "تحديث طلب المحفظ",
            body: "تمت مراجعة طلبك. افتح الإعدادات للتفاصيل.",
            actionType: TEACHER_APPLICATION_REVIEWED_ACTION,
          }
        : {
            title: "Teacher application update",
            body:
              "Your teacher application was reviewed. Open Settings for details.",
            actionType: TEACHER_APPLICATION_REVIEWED_ACTION,
          };
    case "suspended":
      return locale === "ar"
        ? {
            title: "تم تعليق حساب المحفظ",
            body: "تم تعليق صلاحية المحفظ. افتح الإعدادات للتفاصيل.",
            actionType: TEACHER_APPLICATION_REVIEWED_ACTION,
          }
        : {
            title: "Teacher account suspended",
            body: "Your teacher access was suspended. Open Settings for details.",
            actionType: TEACHER_APPLICATION_REVIEWED_ACTION,
          };
    case "revoked":
      return locale === "ar"
        ? {
            title: "تم إلغاء صلاحية المحفظ",
            body: "تم إلغاء صلاحية المحفظ. افتح الإعدادات للتفاصيل.",
            actionType: TEACHER_APPLICATION_REVIEWED_ACTION,
          }
        : {
            title: "Teacher access revoked",
            body: "Your teacher access was revoked. Open Settings for details.",
            actionType: TEACHER_APPLICATION_REVIEWED_ACTION,
          };
    default:
      return locale === "ar"
        ? {
            title: "تحديث طلب المحفظ",
            body: "تغيّرت حالة طلبك.",
            actionType: TEACHER_APPLICATION_REVIEWED_ACTION,
          }
        : {
            title: "Teacher application update",
            body: "Your teacher application status changed.",
            actionType: TEACHER_APPLICATION_REVIEWED_ACTION,
          };
  }
}

import { readUserLanguageCode } from "./userLocale";

export interface SessionRevokedNotificationCopy {
  title: string;
  body: string;
}

export function buildSessionRevokedNotificationCopy(
  userData: Record<string, unknown> | undefined | null,
): SessionRevokedNotificationCopy {
  const locale = readUserLanguageCode(userData);
  if (locale === "ar") {
    return {
      title: "تم تسجيل الدخول من جهاز آخر",
      body:
        "تم فتح حسابك على جهاز آخر. سجّل الدخول مرة أخرى للمتابعة على هذا الجهاز.",
    };
  }

  return {
    title: "Signed in on another device",
    body:
      "Your account was opened on another device. Sign in again to continue on this device.",
  };
}

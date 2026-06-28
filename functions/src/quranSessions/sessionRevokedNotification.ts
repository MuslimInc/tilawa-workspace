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
      body: "تم تسجيل خروجك لأن الحساب تم استخدامه على جهاز آخر.",
    };
  }

  return {
    title: "Signed in on another device",
    body:
      "You were signed out because this account was used on another device.",
  };
}

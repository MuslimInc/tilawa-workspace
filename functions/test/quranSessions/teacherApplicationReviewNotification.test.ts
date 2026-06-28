import test from "node:test";
import assert from "node:assert/strict";

import {
  TEACHER_APPLICATION_REVIEWED_ACTION,
  buildTeacherApplicationReviewNotificationCopy,
} from "../../src/quranSessions/teacherApplicationReviewNotification";
import { readUserLanguageCode } from "../../src/quranSessions/userLocale";
import { buildSessionRevokedNotificationCopy } from "../../src/quranSessions/sessionRevokedNotification";

test("readUserLanguageCode reads top-level languageCode", () => {
  assert.equal(readUserLanguageCode({ languageCode: "ar" }), "ar");
  assert.equal(readUserLanguageCode({ languageCode: "en" }), "en");
});

test("readUserLanguageCode falls back to preferences.languageCode", () => {
  assert.equal(
    readUserLanguageCode({ preferences: { languageCode: "ar" } }),
    "ar",
  );
});

test("readUserLanguageCode defaults unknown locale to en", () => {
  assert.equal(readUserLanguageCode({ languageCode: "fr" }), "en");
  assert.equal(readUserLanguageCode(undefined), "en");
});

test("buildTeacherApplicationReviewNotificationCopy approved en", () => {
  const copy = buildTeacherApplicationReviewNotificationCopy("approved", "en");

  assert.equal(copy.actionType, TEACHER_APPLICATION_REVIEWED_ACTION);
  assert.equal(copy.title, "Teacher application approved");
  assert.match(copy.body, /Settings/i);
});

test("buildTeacherApplicationReviewNotificationCopy approved ar", () => {
  const copy = buildTeacherApplicationReviewNotificationCopy("approved", "ar");

  assert.equal(copy.actionType, TEACHER_APPLICATION_REVIEWED_ACTION);
  assert.equal(copy.title, "تمت الموافقة على طلب المحفظ");
  assert.match(copy.body, /الإعدادات/);
});

test("buildTeacherApplicationReviewNotificationCopy uses user doc locale", () => {
  const copy = buildTeacherApplicationReviewNotificationCopy("approved", {
    languageCode: "ar",
  });

  assert.equal(copy.title, "تمت الموافقة على طلب المحفظ");
});

test("buildTeacherApplicationReviewNotificationCopy unknown locale falls back to en", () => {
  const copy = buildTeacherApplicationReviewNotificationCopy(
    "approved",
    "fr",
  );

  assert.equal(copy.title, "Teacher application approved");
});

test("buildTeacherApplicationReviewNotificationCopy covers moderation statuses", () => {
  for (const status of ["rejected", "suspended", "revoked"]) {
    const enCopy = buildTeacherApplicationReviewNotificationCopy(status, "en");
    const arCopy = buildTeacherApplicationReviewNotificationCopy(status, "ar");

    assert.equal(enCopy.actionType, TEACHER_APPLICATION_REVIEWED_ACTION);
    assert.equal(arCopy.actionType, TEACHER_APPLICATION_REVIEWED_ACTION);
    assert.ok(enCopy.title.length > 0);
    assert.ok(arCopy.title.length > 0);
    assert.notEqual(enCopy.title, arCopy.title);
  }
});

test("buildSessionRevokedNotificationCopy localizes by user languageCode", () => {
  const enCopy = buildSessionRevokedNotificationCopy({ languageCode: "en" });
  const arCopy = buildSessionRevokedNotificationCopy({ languageCode: "ar" });

  assert.equal(enCopy.title, "Signed in on another device");
  assert.equal(arCopy.title, "تم تسجيل الدخول من جهاز آخر");
  assert.equal(
    enCopy.body,
    "You were signed out because this account was used on another device.",
  );
  assert.equal(
    arCopy.body,
    "تم تسجيل خروجك لأن الحساب تم استخدامه على جهاز آخر.",
  );
  assert.notEqual(enCopy.body, arCopy.body);
});

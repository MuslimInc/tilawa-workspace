/**
 * Seeds verified staging teachers with browse-complete profiles, weekly
 * schedules, and external meeting URLs for Free Beta.
 *
 * Idempotent: merge-writes profile + schedule docs (safe to re-run).
 *
 * Usage (from functions/):
 *   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
 *   npm run seed:staging-teachers              # dry run
 *   npm run seed:staging-teachers:apply        # write to Firestore
 */
import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";

import { FIREBASE_PROJECT_ID } from "../src/github";

const APPLY = process.argv.includes("--apply");
const COLLECTION = "quran_teacher_profiles";
const SCHEDULE_DOC = "schedule";
const AVAILABILITY_CONFIG = "availability_config";

/** Fixed createdAt so re-apply does not drift browse ordering. */
const STAGING_CREATED_AT = Timestamp.fromDate(
  new Date("2026-01-01T00:00:00.000Z"),
);

interface TeacherSeed {
  id: string;
  displayName: string;
  externalMeetingUrl: string;
  gender: "male" | "female";
  publicBio: string;
  specializations: string[];
}

const TEACHERS: TeacherSeed[] = [
  {
    id: "staging_teacher_01",
    displayName: "أحمد المحفظ",
    externalMeetingUrl: "https://meet.google.com/staging-teacher-01",
    gender: "male",
    publicBio:
      "محفظ قرآن متخصص في التجويد والتلاوة — حساب تجريبي للاختبار.",
    specializations: ["tajweed"],
  },
  {
    id: "staging_teacher_02",
    displayName: "فاطمة المحفظة",
    externalMeetingUrl: "https://meet.google.com/staging-teacher-02",
    gender: "female",
    publicBio:
      "معلمة قرآن متخصصة في الحفظ والتجويد — حساب تجريبي للاختبار.",
    specializations: ["hifz"],
  },
  {
    id: "staging_teacher_03",
    displayName: "محمد المحفظ",
    externalMeetingUrl: "https://meet.google.com/staging-teacher-03",
    gender: "male",
    publicBio:
      "محفظ قرآن يركز على التلاوة والإقراء — حساب تجريبي للاختبار.",
    specializations: ["recitation"],
  },
  {
    id: "staging_teacher_04",
    displayName: "نور المحفظة",
    externalMeetingUrl: "https://meet.google.com/staging-teacher-04",
    gender: "female",
    publicBio:
      "معلمة قرآن للأطفال والكبار — حساب تجريبي للاختبار.",
    specializations: ["tajweed", "hifz"],
  },
  {
    id: "staging_teacher_05",
    displayName: "يوسف المحفظ",
    externalMeetingUrl: "https://meet.google.com/staging-teacher-05",
    gender: "male",
    publicBio:
      "محفظ قرآن متخصص في التجويد — حساب تجريبي للاختبار.",
    specializations: ["tajweed"],
  },
];

const DEFAULT_WEEKLY_RULES: Record<
  string,
  Array<{ start: string; end: string }>
> = {
  sat: [],
  sun: [{ start: "09:00", end: "12:00" }],
  mon: [{ start: "09:00", end: "12:00" }],
  tue: [{ start: "09:00", end: "12:00" }],
  wed: [{ start: "09:00", end: "12:00" }],
  thu: [{ start: "09:00", end: "12:00" }],
  fri: [],
};

function teacherDoc(seed: TeacherSeed): Record<string, unknown> {
  return {
    userId: seed.id,
    displayName: seed.displayName,
    verificationStatus: "verified",
    profileCompleteness: "complete",
    gender: seed.gender,
    allowedStudentGender: "both",
    canTeachChildren: true,
    requiresGuardianApprovalForChildren: false,
    isPubliclyVisible: true,
    isActive: true,
    publicBio: seed.publicBio,
    teachingLanguages: ["ar"],
    specializations: seed.specializations,
    averageRating: 0,
    reviewCount: 0,
    externalMeetingUrl: seed.externalMeetingUrl,
    countryCode: "EG",
    cityId: "cairo",
    pricingType: "free",
    createdAt: STAGING_CREATED_AT,
    updatedAt: FieldValue.serverTimestamp(),
  };
}

function scheduleDoc(teacherId: string): Record<string, unknown> {
  return {
    teacherId,
    timezone: "Africa/Cairo",
    slotDurationMinutes: 30,
    minNoticeMinutes: 120,
    maxHorizonDays: 30,
    bufferBeforeMinutes: 0,
    bufferAfterMinutes: 0,
    weeklyRules: DEFAULT_WEEKLY_RULES,
    version: 1,
    updatedAt: FieldValue.serverTimestamp(),
  };
}

async function main(): Promise<void> {
  initializeApp({
    projectId: process.env.FIREBASE_PROJECT_ID ?? FIREBASE_PROJECT_ID,
  });
  const db = getFirestore();

  console.log(
    APPLY
      ? `Applying ${TEACHERS.length} verified teachers to ${COLLECTION}…`
      : `Dry run — would seed ${TEACHERS.length} teachers (pass --apply to write)`,
  );

  for (const seed of TEACHERS) {
    const payload = teacherDoc(seed);
    const schedule = scheduleDoc(seed.id);
    console.log(
      `  ${seed.id}: ${seed.displayName} → ${seed.externalMeetingUrl}`,
    );
    console.log(
      `    profileCompleteness=complete, schedule=availability_config/${SCHEDULE_DOC}`,
    );
    if (APPLY) {
      await db.collection(COLLECTION).doc(seed.id).set(payload, { merge: true });
      await db
        .collection(COLLECTION)
        .doc(seed.id)
        .collection(AVAILABILITY_CONFIG)
        .doc(SCHEDULE_DOC)
        .set(schedule, { merge: true });
    }
  }

  if (!APPLY) {
    console.log("\nNo writes performed. Re-run with --apply to seed staging.");
  } else {
    console.log(
      `\nSeeded ${TEACHERS.length} teachers with profiles + weekly schedules.`,
    );
  }
}

void main();

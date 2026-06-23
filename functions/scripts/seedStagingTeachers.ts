/**
 * Seeds verified staging teachers with external meeting URLs for Free Beta.
 *
 * Usage (from functions/):
 *   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
 *   npm run seed:staging-teachers              # dry run
 *   npm run seed:staging-teachers:apply        # write to Firestore
 */
import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

import { FIREBASE_PROJECT_ID } from "../src/github";

const APPLY = process.argv.includes("--apply");
const COLLECTION = "quran_teacher_profiles";

interface TeacherSeed {
  id: string;
  displayName: string;
  externalMeetingUrl: string;
  gender: "male" | "female";
}

const TEACHERS: TeacherSeed[] = [
  {
    id: "staging_teacher_01",
    displayName: "أحمد المحفظ",
    externalMeetingUrl: "https://meet.google.com/staging-teacher-01",
    gender: "male",
  },
  {
    id: "staging_teacher_02",
    displayName: "فاطمة المحفظة",
    externalMeetingUrl: "https://meet.google.com/staging-teacher-02",
    gender: "female",
  },
  {
    id: "staging_teacher_03",
    displayName: "محمد المحفظ",
    externalMeetingUrl: "https://meet.google.com/staging-teacher-03",
    gender: "male",
  },
  {
    id: "staging_teacher_04",
    displayName: "نور المحفظة",
    externalMeetingUrl: "https://meet.google.com/staging-teacher-04",
    gender: "female",
  },
  {
    id: "staging_teacher_05",
    displayName: "يوسف المحفظ",
    externalMeetingUrl: "https://meet.google.com/staging-teacher-05",
    gender: "male",
  },
];

function teacherDoc(seed: TeacherSeed): Record<string, unknown> {
  return {
    userId: seed.id,
    displayName: seed.displayName,
    verificationStatus: "verified",
    gender: seed.gender,
    allowedStudentGender: "both",
    canTeachChildren: true,
    requiresGuardianApprovalForChildren: false,
    isPubliclyVisible: true,
    isActive: true,
    externalMeetingUrl: seed.externalMeetingUrl,
    countryCode: "EG",
    cityId: "cairo",
    pricingType: "free",
    updatedAt: FieldValue.serverTimestamp(),
  };
}

async function main(): Promise<void> {
  initializeApp({ projectId: process.env.FIREBASE_PROJECT_ID ?? FIREBASE_PROJECT_ID });
  const db = getFirestore();

  console.log(
    APPLY
      ? `Applying ${TEACHERS.length} verified teachers to ${COLLECTION}…`
      : `Dry run — would seed ${TEACHERS.length} teachers (pass --apply to write)`,
  );

  for (const seed of TEACHERS) {
    const payload = teacherDoc(seed);
    console.log(`  ${seed.id}: ${seed.displayName} → ${seed.externalMeetingUrl}`);
    if (APPLY) {
      await db.collection(COLLECTION).doc(seed.id).set(payload, { merge: true });
    }
  }

  if (!APPLY) {
    console.log("\nNo writes performed. Re-run with --apply to seed staging.");
  } else {
    console.log(`\nSeeded ${TEACHERS.length} teachers.`);
  }
}

void main();

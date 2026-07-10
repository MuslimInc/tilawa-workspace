/**
 * Seed Maestro QA data for existing Google-auth staging accounts.
 *
 * Adds Email/Password to the same Auth uid (never creates new users), merges
 * Firestore profiles, platform config, teacher availability, and market
 * whitelist. Passwords come from env only and are never logged.
 *
 * Usage (from functions/):
 *   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
 *   export MAESTRO_QURAN_TEACHER_PASSWORD='***'
 *   export MAESTRO_QURAN_STUDENT_PASSWORD='***'
 *   npm run seed:quran-staging-existing-maestro-accounts          # dry run
 *   npm run seed:quran-staging-existing-maestro-accounts:apply    # write
 */
import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

import {
  assertMaestroStagingProject,
  buildLegacyAvailabilitySlotDoc,
  buildMaestroPlatformConfig,
  buildMaestroStudentQuranProfile,
  buildMaestroTeacherApplication,
  buildMaestroTeacherProfile,
  buildMaestroUserDoc,
  buildMaestroWeeklySchedule,
  generateMaestroAvailabilitySlots,
  MAESTRO_ACCOUNT_SPECS,
  MAESTRO_STUDENT_EMAIL,
  MAESTRO_STUDENT_PASSWORD_ENV,
  MAESTRO_TEACHER_EMAIL,
  MAESTRO_TEACHER_PASSWORD_ENV,
  mergeTeacherWhitelist,
  resolveMaestroProjectId,
  summarizeAuthUser,
} from "../src/quranSessions/maestroStagingAccounts";

const APPLY = process.argv.includes("--apply");

interface ResolvedTeacherContext {
  uid: string;
  email: string;
  displayName: string;
  applicationId: string;
  profileDocId: string;
}

async function resolveTeacherContext(
  uid: string,
  email: string,
  displayName: string,
): Promise<ResolvedTeacherContext> {
  const db = getFirestore();

  const applications = await db
    .collection("quran_teacher_applications")
    .where("userId", "==", uid)
    .limit(5)
    .get();

  if (!applications.empty) {
    const applicationId = applications.docs[0].id;
    const profileByApp = await db
      .collection("quran_teacher_profiles")
      .doc(applicationId)
      .get();
    const profileDocId = profileByApp.exists
      ? applicationId
      : applicationId;

    return { uid, email, displayName, applicationId, profileDocId };
  }

  const profiles = await db
    .collection("quran_teacher_profiles")
    .where("userId", "==", uid)
    .limit(1)
    .get();

  if (!profiles.empty) {
    const profileDocId = profiles.docs[0].id;
    return {
      uid,
      email,
      displayName,
      applicationId: profileDocId,
      profileDocId,
    };
  }

  const applicationId = `maestro_${uid}`;
  return {
    uid,
    email,
    displayName,
    applicationId,
    profileDocId: applicationId,
  };
}

async function linkPasswordIfConfigured(params: {
  uid: string;
  email: string;
  passwordEnvVar: string;
}): Promise<void> {
  const password = process.env[params.passwordEnvVar]?.trim();
  if (!password) {
    console.log(
      `  skip password update for ${params.email} — ${params.passwordEnvVar} not set`,
    );
    return;
  }

  if (!APPLY) {
    console.log(
      `  would update password for uid=${params.uid} via auth.updateUser({ password })`,
    );
    return;
  }

  const auth = getAuth();
  await auth.updateUser(params.uid, { password });
  console.log(`  linked Email/Password on uid=${params.uid} (password not logged)`);
}

async function seedTeacher(params: ResolvedTeacherContext): Promise<void> {
  const db = getFirestore();
  const now = FieldValue.serverTimestamp();
  const resolvedDisplayName =
    params.displayName.trim().length >= 3
      ? params.displayName.trim()
      : "محمد المحفظ";

  console.log(
    `Teacher ${params.email} uid=${params.uid} profile=${params.profileDocId}`,
  );

  const userDoc = buildMaestroUserDoc({
    uid: params.uid,
    email: params.email,
    displayName: resolvedDisplayName,
    authProvider: "google",
    profileCompleted: true,
  });

  const applicationDoc = buildMaestroTeacherApplication({
    userId: params.uid,
    displayName: resolvedDisplayName,
    now,
  });
  const profileDoc = buildMaestroTeacherProfile({
    userId: params.uid,
    displayName: resolvedDisplayName,
    now,
  });
  const scheduleDoc = buildMaestroWeeklySchedule(params.profileDocId);
  const slots = generateMaestroAvailabilitySlots({
    teacherId: params.profileDocId,
    now: new Date(),
  });

  if (!APPLY) {
    console.log(`  would merge users/${params.uid}`);
    console.log(
      `  would merge quran_teacher_applications/${params.applicationId}`,
    );
    console.log(
      `  would merge quran_teacher_profiles/${params.profileDocId} + availability_config/schedule`,
    );
    console.log(`  would merge ${slots.length} legacy availability slots`);
    return;
  }

  await db.collection("users").doc(params.uid).set(userDoc, { merge: true });
  await db
    .collection("quran_teacher_applications")
    .doc(params.applicationId)
    .set(applicationDoc, { merge: true });
  await db
    .collection("quran_teacher_profiles")
    .doc(params.profileDocId)
    .set(profileDoc, { merge: true });
  await db
    .collection("quran_teacher_profiles")
    .doc(params.profileDocId)
    .collection("availability_config")
    .doc("schedule")
    .set(scheduleDoc, { merge: true });

  const slotNow = new Date();
  for (const slot of slots) {
    await db
      .collection("quran_teacher_profiles")
      .doc(params.profileDocId)
      .collection("availability")
      .doc(slot.slotId)
      .set(
        buildLegacyAvailabilitySlotDoc({
          teacherId: params.profileDocId,
          slot,
          now: slotNow,
        }),
        { merge: true },
      );
  }

  console.log(`  merged teacher profile + schedule + ${slots.length} slots`);
}

async function backfillTeacherUserIdOnOpenBookings(params: {
  teacherProfileId: string;
  teacherAuthUid: string;
}): Promise<void> {
  const db = getFirestore();
  const collections = ["quran_bookings", "quran_sessions"] as const;

  for (const collection of collections) {
    const snap = await db
      .collection(collection)
      .where("teacherId", "==", params.teacherProfileId)
      .get();

    let updated = 0;
    for (const doc of snap.docs) {
      const data = doc.data();
      const denormalized = data.teacherUserId;
      if (
        typeof denormalized === "string" &&
        denormalized.trim().length > 0 &&
        denormalized !== params.teacherProfileId
      ) {
        continue;
      }

      if (!APPLY) {
        updated += 1;
        continue;
      }

      await doc.ref.set(
        { teacherUserId: params.teacherAuthUid },
        { merge: true },
      );
      updated += 1;
    }

    console.log(
      APPLY
        ? `  backfilled teacherUserId on ${updated} ${collection} docs`
        : `  would backfill teacherUserId on ${updated} ${collection} docs`,
    );
  }
}

async function seedStudent(params: {
  uid: string;
  email: string;
  displayName: string;
}): Promise<void> {
  const db = getFirestore();
  const nowIso = new Date().toISOString();

  console.log(`Student ${params.email} uid=${params.uid}`);

  const userDoc = {
    ...buildMaestroUserDoc({
      uid: params.uid,
      email: params.email,
      displayName: params.displayName,
      authProvider: "google",
      profileCompleted: true,
    }),
    quranSessionsProfile: buildMaestroStudentQuranProfile(nowIso),
  };

  if (!APPLY) {
    console.log(`  would merge users/${params.uid} with quranSessionsProfile`);
    return;
  }

  await db.collection("users").doc(params.uid).set(userDoc, { merge: true });
  console.log("  merged student users doc + quranSessionsProfile");
}

async function seedPlatformAndMarket(teacherProfileId: string): Promise<void> {
  const db = getFirestore();
  const platformDoc = buildMaestroPlatformConfig();

  const marketRef = db.collection("quran_session_market_configs").doc("EG");
  const marketSnap = await marketRef.get();
  const mergedWhitelist = mergeTeacherWhitelist(
    marketSnap.data()?.teacherWhitelist,
    teacherProfileId,
  );

  if (!APPLY) {
    console.log("Would merge quran_session_platform_config/global");
    console.log(
      `Would merge quran_session_market_configs/EG teacherWhitelist → [${mergedWhitelist.join(", ")}]`,
    );
    return;
  }

  await db
    .collection("quran_session_platform_config")
    .doc("global")
    .set(platformDoc, { merge: true });

  await marketRef.set(
    {
      teacherWhitelist: mergedWhitelist,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  console.log("Merged platform config + EG teacher whitelist");
}

async function main(): Promise<void> {
  const projectId = resolveMaestroProjectId();
  assertMaestroStagingProject(projectId);

  initializeApp({ projectId });
  const auth = getAuth();

  console.log(
    APPLY
      ? `Applying Maestro staging seed — project ${projectId}`
      : `Dry run — Maestro staging seed for project ${projectId} (pass --apply to write)`,
  );
  console.log("");

  const teacherUser = await auth.getUserByEmail(MAESTRO_TEACHER_EMAIL);
  const studentUser = await auth.getUserByEmail(MAESTRO_STUDENT_EMAIL);

  console.log("Resolved Auth users (existing uids only):");
  console.log(JSON.stringify(summarizeAuthUser(teacherUser), null, 2));
  console.log(JSON.stringify(summarizeAuthUser(studentUser), null, 2));
  console.log("");

  for (const spec of MAESTRO_ACCOUNT_SPECS) {
    const user = spec.role === "teacher" ? teacherUser : studentUser;
    await linkPasswordIfConfigured({
      uid: user.uid,
      email: spec.email,
      passwordEnvVar: spec.passwordEnvVar,
    });
  }
  console.log("");

  const teacherContext = await resolveTeacherContext(
    teacherUser.uid,
    teacherUser.email ?? MAESTRO_TEACHER_EMAIL,
    teacherUser.displayName ?? "محمد المحفظ",
  );

  await seedTeacher(teacherContext);
  await backfillTeacherUserIdOnOpenBookings({
    teacherProfileId: teacherContext.profileDocId,
    teacherAuthUid: teacherContext.uid,
  });
  await seedStudent({
    uid: studentUser.uid,
    email: studentUser.email ?? MAESTRO_STUDENT_EMAIL,
    displayName: studentUser.displayName ?? studentUser.email ?? "Student QA",
  });
  await seedPlatformAndMarket(teacherContext.profileDocId);

  if (!APPLY) {
    console.log("\nNo writes performed. Re-run with --apply to seed staging.");
    console.log(
      `Set ${MAESTRO_TEACHER_PASSWORD_ENV} and ${MAESTRO_STUDENT_PASSWORD_ENV} to link passwords.`,
    );
  } else {
    console.log("\nMaestro staging seed complete.");
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

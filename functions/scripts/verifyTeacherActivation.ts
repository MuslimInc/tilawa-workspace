/**
 * Phase A — verify approved teacher activation pipeline in Firestore.
 *
 * Reads application + profile docs and derives Flutter [TeacherCapabilityState].
 *
 * Usage:
 *   FIREBASE_PROJECT_ID=quran-playera-app npm run quran-sessions:verify-teacher-activation
 *   FIREBASE_PROJECT_ID=quran-playera-app npm run quran-sessions:verify-teacher-activation -- --userId=UID
 *   FIREBASE_PROJECT_ID=quran-playera-app npm run quran-sessions:verify-teacher-activation -- --applicationId=APP_ID
 *   FIREBASE_PROJECT_ID=quran-playera-app npm run quran-sessions:verify-teacher-activation -- --list-recent=10
 *
 * Exit 1 when approved application is missing profile or critical field mismatch.
 */
import { initializeApp } from "firebase-admin/app";
import { getFirestore, type DocumentSnapshot } from "firebase-admin/firestore";

import {
  computeIsPubliclyVisible,
  computeProfileCompleteness,
  TEACHER_DISPLAY_NAME_PLACEHOLDERS,
} from "../src/quranSessions/teacherProfileApproval";

const PROJECT_ID = process.env.FIREBASE_PROJECT_ID ?? "quran-playera-app";

type TeacherCapabilityState =
  | "none"
  | "draft"
  | "pending"
  | "rejected"
  | "approvedIncompleteProfile"
  | "approvedActive"
  | "approvedInactive"
  | "suspended"
  | "revoked";

interface CliArgs {
  userId?: string;
  applicationId?: string;
  listRecent: number;
}

interface CheckResult {
  id: string;
  pass: boolean;
  detail: string;
}

interface VerificationReport {
  applicationId: string;
  userId: string;
  application: Record<string, unknown> | null;
  profile: Record<string, unknown> | null;
  profileDocId: string | null;
  checks: CheckResult[];
  derived: {
    cfProfileCompleteness: "complete" | "incomplete" | null;
    dartProfileCompleteness: "complete" | "incomplete" | null;
    cfIsPubliclyVisible: boolean | null;
    dartIsPubliclyVisible: boolean | null;
    capabilityState: TeacherCapabilityState;
    settingsTitleAr: string;
    navTarget: string;
    staleCacheHypothesis: string;
  };
  pass: boolean;
}

function parseArgs(argv: string[]): CliArgs {
  let userId: string | undefined;
  let applicationId: string | undefined;
  let listRecent = 0;

  for (const arg of argv) {
    if (arg.startsWith("--userId=")) {
      userId = arg.slice("--userId=".length).trim() || undefined;
    } else if (arg.startsWith("--applicationId=")) {
      applicationId = arg.slice("--applicationId=".length).trim() || undefined;
    } else if (arg.startsWith("--list-recent=")) {
      listRecent = Number.parseInt(arg.slice("--list-recent=".length), 10) || 10;
    } else if (arg === "--help" || arg === "-h") {
      console.log(`verifyTeacherActivation — Phase A Firestore audit

Options:
  --userId=UID              Resolve application by userId
  --applicationId=ID        Read application + profile by doc id
  --list-recent=N           List N recent approved applications (default 10 when no ids)
`);
      process.exit(0);
    }
  }

  return { userId, applicationId, listRecent };
}

function trimString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

const DART_ENGLISH_PLACEHOLDERS = new Set([
  "quran teacher",
  "teacher",
  "test",
  "anonymous",
]);

const DART_ARABIC_PLACEHOLDERS = new Set(["محفظ قرآن"]);

function isDartValidDisplayName(raw: string): boolean {
  const trimmed = raw.trim();
  if (trimmed.length === 0) return false;
  const lower = trimmed.toLowerCase();
  if (DART_ENGLISH_PLACEHOLDERS.has(lower)) return false;
  if (DART_ARABIC_PLACEHOLDERS.has(trimmed)) return false;
  if (trimmed.length >= 3) return true;
  const words = trimmed.split(/\s+/).filter((w) => w.length > 0);
  return words.length >= 2;
}

function mapVerificationStatus(raw: unknown): string {
  if (typeof raw !== "string") return "pending";
  if (raw === "underReview") return "underReview";
  if (raw === "verified" || raw === "approved") return "verified";
  if (raw === "rejected") return "rejected";
  if (raw === "suspended") return "suspended";
  return "pending";
}

function dartEvaluateCompleteness(profile: {
  userId: string;
  displayName: string;
  publicBio: string | null;
  teachingLanguages: string[];
  specializations: string[];
  verificationStatus: string;
}): "complete" | "incomplete" {
  if (profile.userId.trim().length === 0) return "incomplete";
  if (!isDartValidDisplayName(profile.displayName)) return "incomplete";
  if (!profile.publicBio || profile.publicBio.trim().length === 0) {
    return "incomplete";
  }
  if (
    profile.teachingLanguages.length === 0
    || profile.specializations.length === 0
  ) {
    return "incomplete";
  }
  if (profile.verificationStatus !== "verified") return "incomplete";
  return "complete";
}

function dartIsPubliclyVisible(profile: {
  userId: string;
  displayName: string;
  publicBio: string | null;
  teachingLanguages: string[];
  specializations: string[];
  verificationStatus: string;
  isActive: boolean;
}): boolean {
  return (
    profile.isActive
    && dartEvaluateCompleteness(profile) === "complete"
  );
}

function resolveCapabilityState(params: {
  applicationStatus: string | null;
  profile: {
    userId: string;
    displayName: string;
    publicBio: string | null;
    teachingLanguages: string[];
    specializations: string[];
    verificationStatus: string;
    isActive: boolean;
  } | null;
}): TeacherCapabilityState {
  const status = params.applicationStatus;
  if (!status) return "none";

  switch (status) {
    case "draft":
      return "draft";
    case "pending":
      return "pending";
    case "rejected":
      return "rejected";
    case "suspended":
      return "suspended";
    case "revoked":
      return "revoked";
    case "approved": {
      const profile = params.profile;
      if (!profile) return "approvedIncompleteProfile";

      const completeness = dartEvaluateCompleteness(profile);
      if (completeness !== "complete") return "approvedIncompleteProfile";

      const visible = dartIsPubliclyVisible(profile);
      return visible ? "approvedActive" : "approvedInactive";
    }
    default:
      return "none";
  }
}

function settingsTitleAr(state: TeacherCapabilityState): string {
  switch (state) {
    case "approvedIncompleteProfile":
      return "أكمل ملف المعلم";
    case "approvedActive":
      return "لوحة تحكم المحفظ";
    case "pending":
    case "rejected":
    case "approvedInactive":
    case "suspended":
    case "revoked":
      return "عرض حالة الطلب";
    default:
      return "(no teaching row / apply entry)";
  }
}

function navTarget(state: TeacherCapabilityState): string {
  switch (state) {
    case "approvedIncompleteProfile":
      return "/sessions/teacher/profile/complete";
    case "approvedActive":
      return "/sessions/dashboard";
    case "pending":
    case "rejected":
    case "approvedInactive":
    case "suspended":
    case "revoked":
      return "/sessions/teacher/status";
    default:
      return "(n/a)";
  }
}

function staleCacheHypothesis(
  state: TeacherCapabilityState,
  applicationStatus: string | null,
): string {
  if (applicationStatus === "approved" && state === "pending") {
    return "Settings likely stale (cached pending while application approved)";
  }
  if (applicationStatus === "approved" && state === "approvedActive") {
    return "Fresh load should show dashboard CTA; stale pending cache would show view-status";
  }
  if (applicationStatus === "approved" && state === "approvedInactive") {
    return "Backend/profile issue (isActive false or visibility) — not stale-cache alone";
  }
  if (applicationStatus === "approved" && state === "approvedIncompleteProfile") {
    return "Incomplete profile fields — complete-profile CTA expected";
  }
  return "n/a";
}

function docData(doc: DocumentSnapshot | null): Record<string, unknown> | null {
  if (!doc?.exists) return null;
  return doc.data() as Record<string, unknown>;
}

function asStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.filter((item): item is string => typeof item === "string");
}

async function resolveApplicationId(
  db: FirebaseFirestore.Firestore,
  args: CliArgs,
): Promise<string | null> {
  if (args.applicationId) return args.applicationId;

  if (args.userId) {
    const byUser = await db
      .collection("quran_teacher_applications")
      .where("userId", "==", args.userId)
      .limit(5)
      .get();
    if (byUser.empty) return null;
    if (byUser.size > 1) {
      console.warn(
        `WARN: multiple applications for userId=${args.userId}; using ${byUser.docs[0].id}`,
      );
    }
    return byUser.docs[0].id;
  }

  return null;
}

async function listRecentApproved(
  db: FirebaseFirestore.Firestore,
  limit: number,
): Promise<void> {
  const snapshot = await db
    .collection("quran_teacher_applications")
    .where("status", "==", "approved")
    .limit(limit)
    .get();

  if (snapshot.empty) {
    console.log("No approved teacher applications found.");
    return;
  }

  console.log(`Recent approved applications (up to ${limit}):\n`);
  for (const doc of snapshot.docs) {
    const data = doc.data();
    const profileSnap = await db
      .collection("quran_teacher_profiles")
      .doc(doc.id)
      .get();
    const profileExists = profileSnap.exists;
    const isActive = profileSnap.get("isActive");
    console.log(
      JSON.stringify({
        applicationId: doc.id,
        userId: data.userId,
        reviewedAt: data.reviewedAt?.toDate?.()?.toISOString?.() ?? null,
        profileExists,
        profileIsActive: isActive ?? null,
        profileCompleteness: profileSnap.get("profileCompleteness") ?? null,
      }),
    );
  }
}

function buildReport(params: {
  applicationId: string;
  userId: string;
  application: Record<string, unknown> | null;
  profile: Record<string, unknown> | null;
  profileDocId: string | null;
}): VerificationReport {
  const { applicationId, userId, application, profile, profileDocId } = params;
  const checks: CheckResult[] = [];

  const appStatus = application ? trimString(application.status) : null;

  if (!application) {
    checks.push({
      id: "application.exists",
      pass: false,
      detail: "Application document missing",
    });
  } else {
    checks.push({
      id: "application.exists",
      pass: true,
      detail: `status=${appStatus}`,
    });
    checks.push({
      id: "application.status",
      pass: appStatus === "approved",
      detail: `expected approved, got ${appStatus ?? "(missing)"}`,
    });
    checks.push({
      id: "application.userId",
      pass: trimString(application.userId) === userId,
      detail: `application.userId=${trimString(application.userId)} auth=${userId}`,
    });
  }

  if (!profile) {
    checks.push({
      id: "profile.exists",
      pass: appStatus !== "approved",
      detail:
        appStatus === "approved"
          ? "Approved application missing quran_teacher_profiles doc"
          : "No profile (ok when not approved)",
    });
  } else {
    const profileUserId = trimString(profile.userId);
    const isActive = profile.isActive === true;
    const isActiveMissing = profile.isActive === undefined;
    const verificationStatus = mapVerificationStatus(profile.verificationStatus);
    const displayName = trimString(profile.displayName);
    const publicBio = trimString(profile.publicBio);
    const teachingLanguages = asStringArray(profile.teachingLanguages);
    const specializations = asStringArray(profile.specializations);
    const storedCompleteness = trimString(profile.profileCompleteness);

    checks.push({
      id: "profile.exists",
      pass: true,
      detail: `docId=${profileDocId}`,
    });
    checks.push({
      id: "profile.userId",
      pass: profileUserId === userId,
      detail: `profile.userId=${profileUserId} expected=${userId}`,
    });
    checks.push({
      id: "profile.isActive",
      pass: isActive,
      detail: isActiveMissing
        ? "isActive missing (Flutter defaults to false)"
        : `isActive=${String(profile.isActive)}`,
    });
    checks.push({
      id: "profile.verificationStatus",
      pass: verificationStatus === "verified",
      detail: `verificationStatus=${verificationStatus}`,
    });
    checks.push({
      id: "profile.displayName",
      pass: isDartValidDisplayName(displayName),
      detail: displayName.length === 0 ? "empty" : `"${displayName}"`,
    });
    checks.push({
      id: "profile.publicBio",
      pass: publicBio.length > 0,
      detail: publicBio.length === 0 ? "empty" : `length=${publicBio.length}`,
    });
    checks.push({
      id: "profile.teachingLanguages",
      pass: teachingLanguages.length > 0,
      detail: `count=${teachingLanguages.length}`,
    });
    checks.push({
      id: "profile.specializations",
      pass: specializations.length > 0,
      detail: `count=${specializations.length}`,
    });

    const cfCompleteness = computeProfileCompleteness({
      displayName,
      publicBio,
      teachingLanguages,
      specializations,
    });
    const dartCompleteness = dartEvaluateCompleteness({
      userId: profileUserId,
      displayName,
      publicBio: publicBio || null,
      teachingLanguages,
      specializations,
      verificationStatus,
    });

    checks.push({
      id: "profile.profileCompleteness.stored",
      pass: storedCompleteness === "complete" || storedCompleteness === "incomplete",
      detail: `stored=${storedCompleteness || "(missing)"}`,
    });
    checks.push({
      id: "profile.profileCompleteness.cf_vs_dart",
      pass: cfCompleteness === dartCompleteness,
      detail: `cf=${cfCompleteness} dart=${dartCompleteness}`,
    });

    const cfVisible = computeIsPubliclyVisible({
      profileCompleteness: cfCompleteness,
      verificationStatus,
      isActive,
    });
    const dartVisible = dartIsPubliclyVisible({
      userId: profileUserId,
      displayName,
      publicBio: publicBio || null,
      teachingLanguages,
      specializations,
      verificationStatus,
      isActive,
    });
    const storedVisible = profile.isPubliclyVisible === true;

    checks.push({
      id: "profile.isPubliclyVisible",
      pass: storedVisible === cfVisible,
      detail: `stored=${String(profile.isPubliclyVisible)} cf=${cfVisible}`,
    });
    checks.push({
      id: "profile.isPubliclyVisible.dart",
      pass: dartVisible === cfVisible || dartCompleteness !== cfCompleteness,
      detail: `dart=${dartVisible} (parity gap ok when name rules differ)`,
    });

    if (
      TEACHER_DISPLAY_NAME_PLACEHOLDERS.includes(
        displayName as (typeof TEACHER_DISPLAY_NAME_PLACEHOLDERS)[number],
      )
    ) {
      checks.push({
        id: "profile.displayName.placeholder",
        pass: false,
        detail: "CF placeholder name detected",
      });
    }
  }

  const mappedProfile = profile
    ? {
        userId: trimString(profile.userId),
        displayName: trimString(profile.displayName),
        publicBio: trimString(profile.publicBio) || null,
        teachingLanguages: asStringArray(profile.teachingLanguages),
        specializations: asStringArray(profile.specializations),
        verificationStatus: mapVerificationStatus(profile.verificationStatus),
        isActive: profile.isActive === true,
      }
    : null;

  const capabilityState = resolveCapabilityState({
    applicationStatus: appStatus,
    profile: mappedProfile,
  });

  const cfCompleteness = mappedProfile
    ? computeProfileCompleteness({
        displayName: mappedProfile.displayName,
        publicBio: mappedProfile.publicBio ?? "",
        teachingLanguages: mappedProfile.teachingLanguages,
        specializations: mappedProfile.specializations,
      })
    : null;
  const dartCompleteness = mappedProfile
    ? dartEvaluateCompleteness(mappedProfile)
    : null;

  const criticalFail = checks.some(
    (c) =>
      !c.pass
      && [
        "application.exists",
        "profile.exists",
        "application.status",
        "profile.userId",
        "profile.isActive",
        "profile.verificationStatus",
      ].includes(c.id),
  );

  return {
    applicationId,
    userId,
    application,
    profile,
    profileDocId,
    checks,
    derived: {
      cfProfileCompleteness: cfCompleteness,
      dartProfileCompleteness: dartCompleteness,
      cfIsPubliclyVisible: mappedProfile
        ? computeIsPubliclyVisible({
            profileCompleteness: cfCompleteness ?? "incomplete",
            verificationStatus: mappedProfile.verificationStatus,
            isActive: mappedProfile.isActive,
          })
        : null,
      dartIsPubliclyVisible: mappedProfile
        ? dartIsPubliclyVisible(mappedProfile)
        : null,
      capabilityState,
      settingsTitleAr: settingsTitleAr(capabilityState),
      navTarget: navTarget(capabilityState),
      staleCacheHypothesis: staleCacheHypothesis(capabilityState, appStatus),
    },
    pass: !criticalFail,
  };
}

function printReport(report: VerificationReport): void {
  console.log("\n=== Teacher activation verification ===");
  console.log(`applicationId: ${report.applicationId}`);
  console.log(`userId: ${report.userId}`);
  console.log(`verdict: ${report.pass ? "PASS (data)" : "FAIL (data)"}`);
  console.log("\n--- Checks ---");
  for (const check of report.checks) {
    console.log(`[${check.pass ? "OK" : "FAIL"}] ${check.id}: ${check.detail}`);
  }
  console.log("\n--- Derived Flutter capability ---");
  console.log(JSON.stringify(report.derived, null, 2));
  console.log("\n--- Raw application (subset) ---");
  if (report.application) {
    console.log(
      JSON.stringify(
        {
          status: report.application.status,
          userId: report.application.userId,
          publicDisplayName: report.application.publicDisplayName,
          bio: typeof report.application.bio === "string"
            ? `(len ${(report.application.bio as string).length})`
            : report.application.bio,
          teachingLanguages: report.application.teachingLanguages,
          specializations: report.application.specializations,
          reviewedAt: report.application.reviewedAt,
        },
        null,
        2,
      ),
    );
  } else {
    console.log("(missing)");
  }
  console.log("\n--- Raw profile (subset) ---");
  if (report.profile) {
    console.log(
      JSON.stringify(
        {
          userId: report.profile.userId,
          displayName: report.profile.displayName,
          publicBio: typeof report.profile.publicBio === "string"
            ? `(len ${(report.profile.publicBio as string).length})`
            : report.profile.publicBio,
          verificationStatus: report.profile.verificationStatus,
          isActive: report.profile.isActive,
          profileCompleteness: report.profile.profileCompleteness,
          isPubliclyVisible: report.profile.isPubliclyVisible,
          teachingLanguages: report.profile.teachingLanguages,
          specializations: report.profile.specializations,
        },
        null,
        2,
      ),
    );
  } else {
    console.log("(missing)");
  }
}

async function verifyOne(
  db: FirebaseFirestore.Firestore,
  applicationId: string,
): Promise<VerificationReport> {
  const appSnap = await db
    .collection("quran_teacher_applications")
    .doc(applicationId)
    .get();
  const application = docData(appSnap);
  const userId = application ? trimString(application.userId) : "";

  const profileByAppId = await db
    .collection("quran_teacher_profiles")
    .doc(applicationId)
    .get();
  let profileSnap = profileByAppId;
  let profileDocId = profileByAppId.exists ? applicationId : null;

  if (!profileByAppId.exists && userId) {
    const byUser = await db
      .collection("quran_teacher_profiles")
      .where("userId", "==", userId)
      .limit(1)
      .get();
    if (!byUser.empty) {
      profileSnap = byUser.docs[0];
      profileDocId = byUser.docs[0].id;
    }
  }

  return buildReport({
    applicationId,
    userId,
    application,
    profile: docData(profileSnap),
    profileDocId,
  });
}

async function main(): Promise<void> {
  const args = parseArgs(process.argv.slice(2));
  initializeApp({ projectId: PROJECT_ID });
  const db = getFirestore();

  console.log(`verifyTeacherActivation — project ${PROJECT_ID}`);

  if (!args.userId && !args.applicationId) {
    const limit = args.listRecent > 0 ? args.listRecent : 10;
    await listRecentApproved(db, limit);

    const recent = await db
      .collection("quran_teacher_applications")
      .where("status", "==", "approved")
      .limit(limit)
      .get();

    if (recent.empty) {
      console.log(
        "\nNo approved applications to verify. Re-run with --userId or --applicationId.",
      );
      process.exit(2);
    }

    const reports: VerificationReport[] = [];
    for (const doc of recent.docs) {
      reports.push(await verifyOne(db, doc.id));
    }

    let anyFail = false;
    for (const report of reports) {
      printReport(report);
      if (!report.pass) anyFail = true;
    }

    console.log("\n=== Summary ===");
    const passCount = reports.filter((r) => r.pass).length;
    console.log(`${passCount}/${reports.length} approved applications pass data checks`);
    console.log(
      "Stale-cache manual test: open Settings while pending → admin approve → reopen status (fresh) vs Settings (stale until app restart).",
    );
    console.log(
      "Code: SettingsTeacherCapabilityScope loads once in initState (no resume refresh).",
    );

    process.exit(anyFail ? 1 : 0);
  }

  const applicationId = await resolveApplicationId(db, args);
  if (!applicationId) {
    console.error(
      "Could not resolve application. Provide --applicationId or --userId with an existing application.",
    );
    process.exit(2);
  }

  const report = await verifyOne(db, applicationId);
  printReport(report);
  process.exit(report.pass ? 0 : 1);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

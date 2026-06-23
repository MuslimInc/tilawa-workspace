/**
 * Backfill legacy `quran_teacher_profiles` display names and visibility fields.
 *
 * Finds profiles with placeholder/empty displayName, missing userId, or missing
 * publicBio. Resolves displayName from application.publicDisplayName, then
 * users/{userId}.displayName. Never derives displayName from bio.
 *
 * Usage (from functions/):
 *   GOOGLE_APPLICATION_CREDENTIALS=... npm run admin:backfill-teacher-profiles
 *   GOOGLE_APPLICATION_CREDENTIALS=... npm run admin:backfill-teacher-profiles -- --apply
 */
import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import {
  COLLECTIONS,
  computeIsPubliclyVisible,
  computeProfileCompleteness,
  profileNeedsAttention,
  resolveMigrationDisplayName,
  trimString,
} from "./lib/quran-sessions-schema";

const APPLY = process.argv.includes("--apply");

interface ProfileReportRow {
  profileId: string;
  userId: string;
  action: "fixed" | "incomplete" | "manual_review" | "skipped";
  reason: string;
  displayName?: string;
}

async function main(): Promise<void> {
  initializeApp({
    projectId: process.env.FIREBASE_PROJECT_ID ?? "quran-playera-app",
  });
  const db = getFirestore();

  const snapshot = await db.collection(COLLECTIONS.teacherProfiles).get();
  const report: ProfileReportRow[] = [];
  let writeCount = 0;

  for (const doc of snapshot.docs) {
    const profile = doc.data();
    const profileId = doc.id;

    if (!profileNeedsAttention(profile)) {
      report.push({
        profileId,
        userId: trimString(profile.userId),
        action: "skipped",
        reason: "already_complete",
      });
      continue;
    }

    const userId = trimString(profile.userId);
    const applicationSnap = await db
      .collection(COLLECTIONS.teacherApplications)
      .doc(profileId)
      .get();
    const application = applicationSnap.exists
      ? (applicationSnap.data() as Record<string, unknown>)
      : undefined;

    let user: Record<string, unknown> | undefined;
    if (userId.length > 0) {
      const userSnap = await db.collection(COLLECTIONS.users).doc(userId).get();
      user = userSnap.exists
        ? (userSnap.data() as Record<string, unknown>)
        : undefined;
    }

    if (!userId.length && !application) {
      report.push({
        profileId,
        userId: "",
        action: "manual_review",
        reason: "missing_userId_and_application",
      });
      continue;
    }

    const resolvedDisplayName = resolveMigrationDisplayName(application, user);
    const nextDisplayName =
      resolvedDisplayName ?? trimString(profile.displayName);
    const nextUserId =
      userId.length > 0 ? userId : trimString(application?.userId);
    const nextPublicBio = trimString(profile.publicBio);

    const completeness = computeProfileCompleteness(
      resolvedDisplayName ?? nextDisplayName,
      nextUserId,
      nextPublicBio,
    );
    const isPubliclyVisible = computeIsPubliclyVisible(profile, completeness);

    if (completeness === "incomplete" && resolvedDisplayName == null) {
      report.push({
        profileId,
        userId: nextUserId,
        action: "incomplete",
        reason: "no_display_name_source",
      });
    } else if (resolvedDisplayName != null) {
      report.push({
        profileId,
        userId: nextUserId,
        action: "fixed",
        reason: "display_name_migrated",
        displayName: resolvedDisplayName,
      });
    } else {
      report.push({
        profileId,
        userId: nextUserId,
        action: "fixed",
        reason: "visibility_fields_only",
      });
    }

    const patch: Record<string, unknown> = {
      profileCompleteness: completeness,
      isPubliclyVisible,
      updatedAt: FieldValue.serverTimestamp(),
    };

    if (resolvedDisplayName != null) {
      patch.displayName = resolvedDisplayName;
    }
    if (!userId.length && nextUserId.length > 0) {
      patch.userId = nextUserId;
    }

    if (APPLY) {
      await doc.ref.set(patch, { merge: true });
      writeCount++;
    }
  }

  const scanned = snapshot.size;
  const fixed = report.filter((row) => row.action === "fixed").length;
  const incomplete = report.filter((row) => row.action === "incomplete").length;
  const manualReview = report.filter(
    (row) => row.action === "manual_review",
  ).length;
  const skipped = report.filter((row) => row.action === "skipped").length;

  console.log(
    JSON.stringify(
      {
        mode: APPLY ? "apply" : "dry_run",
        scanned,
        fixed,
        incomplete,
        manualReview,
        skipped,
        writes: APPLY ? writeCount : 0,
      },
      null,
      2,
    ),
  );

  if (!APPLY) {
    console.log("\nSample rows (first 20 needing attention):");
    for (const row of report.filter((r) => r.action !== "skipped").slice(0, 20)) {
      console.log(JSON.stringify(row));
    }
    console.log("\nRe-run with --apply to write changes.");
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

/**
 * Backfill approved teacher profiles where `isActive` is false/missing.
 *
 * Approved applications should have an active profile unless the application
 * itself is suspended/revoked. Fixes `approvedInactive` → `approvedActive`
 * when profile fields are otherwise complete.
 *
 * Usage:
 *   FIREBASE_PROJECT_ID=quran-playera-app npm run quran-sessions:backfill-approved-activation
 *   FIREBASE_PROJECT_ID=quran-playera-app npm run quran-sessions:backfill-approved-activation -- --apply
 *   FIREBASE_PROJECT_ID=quran-playera-app npm run quran-sessions:backfill-approved-activation -- --applicationId=ID --apply
 */
import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

import { recomputeVisibilityFields } from "../src/quranSessions/teacherProfileApproval";

const APPLY = process.argv.includes("--apply");

function parseApplicationId(): string | undefined {
  for (const arg of process.argv.slice(2)) {
    if (arg.startsWith("--applicationId=")) {
      return arg.slice("--applicationId=".length).trim() || undefined;
    }
  }
  return undefined;
}

interface Row {
  applicationId: string;
  userId: string;
  applicationStatus: string;
  wasActive: boolean | undefined;
  willActivate: boolean;
  reason: string;
}

async function main(): Promise<void> {
  const projectId = process.env.FIREBASE_PROJECT_ID ?? "quran-playera-app";
  initializeApp({ projectId });
  const db = getFirestore();

  const singleId = parseApplicationId();
  const appSnap = singleId
    ? await db
        .collection("quran_teacher_applications")
        .doc(singleId)
        .get()
        .then((doc) => (doc.exists ? [doc] : []))
    : (
        await db
          .collection("quran_teacher_applications")
          .where("status", "==", "approved")
          .get()
      ).docs;

  const rows: Row[] = [];
  let writes = 0;

  for (const appDoc of appSnap) {
    const applicationId = appDoc.id;
    const app = appDoc.data();
    if (!app) {
      rows.push({
        applicationId,
        userId: "",
        applicationStatus: "",
        wasActive: undefined,
        willActivate: false,
        reason: "empty_application_doc",
      });
      continue;
    }
    const status = String(app.status ?? "");
    const userId = String(app.userId ?? "");

    if (status !== "approved") {
      rows.push({
        applicationId,
        userId,
        applicationStatus: status,
        wasActive: undefined,
        willActivate: false,
        reason: "application_not_approved",
      });
      continue;
    }

    const profileRef = db.collection("quran_teacher_profiles").doc(applicationId);
    const profileSnap = await profileRef.get();

    if (!profileSnap.exists) {
      rows.push({
        applicationId,
        userId,
        applicationStatus: status,
        wasActive: undefined,
        willActivate: false,
        reason: "missing_profile",
      });
      continue;
    }

    const profile = profileSnap.data() ?? {};
    const wasActive = profile.isActive as boolean | undefined;

    if (wasActive === true) {
      rows.push({
        applicationId,
        userId,
        applicationStatus: status,
        wasActive: true,
        willActivate: false,
        reason: "already_active",
      });
      continue;
    }

    const visibility = recomputeVisibilityFields({
      ...profile,
      isActive: true,
    });

    rows.push({
      applicationId,
      userId,
      applicationStatus: status,
      wasActive,
      willActivate: true,
      reason: wasActive === undefined ? "isActive_missing" : "isActive_false",
    });

    if (APPLY) {
      await profileRef.set(
        {
          isActive: true,
          isPubliclyVisible: visibility.isPubliclyVisible,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      writes++;
    }
  }

  const toActivate = rows.filter((r) => r.willActivate);

  console.log(
    JSON.stringify(
      {
        mode: APPLY ? "apply" : "dry_run",
        projectId,
        scanned: rows.length,
        toActivate: toActivate.length,
        writes: APPLY ? writes : 0,
        rows: toActivate,
      },
      null,
      2,
    ),
  );

  if (!APPLY && toActivate.length > 0) {
    console.log("\nRe-run with --apply to activate profiles.");
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

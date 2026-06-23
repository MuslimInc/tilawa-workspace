/**
 * Audit `users` collection for duplicate emails and doc.id != stored uid mismatches.
 *
 * Read-only — never merges or deletes documents.
 *
 * Usage (from functions/):
 *   GOOGLE_APPLICATION_CREDENTIALS=... npm run admin:audit-duplicate-users
 */
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { COLLECTIONS, trimString } from "./lib/quran-sessions-schema";

interface UserRow {
  docId: string;
  storedUid: string | null;
  email: string;
  displayName: string;
  hasQuranSessionsProfile: boolean;
  docIdMatchesStoredUid: boolean;
}

function normalizeEmail(value: unknown): string | null {
  const email = trimString(value).toLowerCase();
  return email.length > 0 ? email : null;
}

async function main(): Promise<void> {
  initializeApp({
    projectId: process.env.FIREBASE_PROJECT_ID ?? "quran-playera-app",
  });
  const db = getFirestore();

  const snapshot = await db.collection(COLLECTIONS.users).get();
  const rows: UserRow[] = [];

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const email = normalizeEmail(data.email);
    if (email == null) {
      continue;
    }

    const storedUidRaw = data.uid ?? data.userId;
    const storedUid =
      typeof storedUidRaw === "string" && storedUidRaw.trim().length > 0
        ? storedUidRaw.trim()
        : null;

    rows.push({
      docId: doc.id,
      storedUid,
      email,
      displayName: trimString(data.displayName),
      hasQuranSessionsProfile: data.quranSessionsProfile != null,
      docIdMatchesStoredUid: storedUid == null || storedUid === doc.id,
    });
  }

  const byEmail = new Map<string, UserRow[]>();
  for (const row of rows) {
    const group = byEmail.get(row.email) ?? [];
    group.push(row);
    byEmail.set(row.email, group);
  }

  const duplicateEmails = [...byEmail.entries()]
    .filter(([, group]) => group.length > 1)
    .sort((a, b) => b[1].length - a[1].length);

  const uidMismatches = rows.filter((row) => !row.docIdMatchesStoredUid);

  console.log(
    JSON.stringify(
      {
        scanned: snapshot.size,
        withEmail: rows.length,
        duplicateEmailGroups: duplicateEmails.length,
        uidFieldMismatches: uidMismatches.length,
      },
      null,
      2,
    ),
  );

  if (duplicateEmails.length > 0) {
    console.log("\nDuplicate emails:");
    for (const [email, group] of duplicateEmails) {
      console.log(
        JSON.stringify({
          email,
          count: group.length,
          users: group.map((row) => ({
            docId: row.docId,
            storedUid: row.storedUid,
            displayName: row.displayName,
            hasQuranSessionsProfile: row.hasQuranSessionsProfile,
          })),
        }),
      );
    }
  } else {
    console.log("\nNo duplicate emails found.");
  }

  if (uidMismatches.length > 0) {
    console.log("\nDoc id != stored uid field:");
    for (const row of uidMismatches) {
      console.log(
        JSON.stringify({
          docId: row.docId,
          storedUid: row.storedUid,
          email: row.email,
        }),
      );
    }
  } else {
    console.log("\nNo doc.id vs stored uid mismatches found.");
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

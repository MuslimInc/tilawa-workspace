#!/usr/bin/env ts-node
/**
 * Audit duplicate emails in `users` collection.
 *
 * Default is dry-run: reports duplicates only, never deletes documents.
 */
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

import {
  findDuplicateEmailGroups,
  formatDuplicateEmailAuditReport,
  type UserEmailRecord,
} from "../src/auditDuplicateUserEmails";

async function main() {
  const apply = process.argv.includes("--apply");
  if (apply) {
    console.error("This audit script never deletes user documents.");
  }

  initializeApp();
  const db = getFirestore();
  const snapshot = await db.collection("users").get();
  const users: UserEmailRecord[] = snapshot.docs.map((doc) => ({
    id: doc.id,
    email: doc.data().email as string | undefined,
  }));

  const result = findDuplicateEmailGroups(users);
  console.log(formatDuplicateEmailAuditReport(result, !apply));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

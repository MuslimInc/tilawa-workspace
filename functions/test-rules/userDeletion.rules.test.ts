import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import test from "node:test";
import assert from "node:assert/strict";
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
  type RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  collection,
  deleteField,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
} from "firebase/firestore";

const PROJECT_ID = "demo-tilawa-rules";
let testEnv: RulesTestEnvironment;

test.before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(
        resolve(__dirname, "../../firestore.rules"),
        "utf8",
      ),
    },
  });
});

test.after(async () => {
  await testEnv.cleanup();
});

async function seedPendingDeletionUser(): Promise<void> {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await setDoc(doc(adminDb, "users/student1"), {
      displayName: "Student",
      accountStatus: "pending_deletion",
      deletion: {
        requestedBy: "admin1",
        reason: "GDPR erasure request",
      },
    });
    await setDoc(doc(adminDb, "user_deletion_state/student1"), {
      userId: "student1",
      status: "pending_deletion",
    });
    await setDoc(doc(adminDb, "user_deletion_audit/audit1"), {
      targetUserId: "student1",
      action: "requested",
      actorUid: "admin1",
    });
  });
}

test("rules: admin can read deletion state and audit log", async () => {
  await testEnv.clearFirestore();
  await seedPendingDeletionUser();

  const adminDb = testEnv
    .authenticatedContext("admin1", { admin: true })
    .firestore();
  await assertSucceeds(getDoc(doc(adminDb, "user_deletion_state/student1")));
  const audit = await assertSucceeds(
    getDocs(collection(adminDb, "user_deletion_audit")),
  );
  assert.equal(audit.size, 1);
});

test("rules: non-admin cannot read deletion state or audit log", async () => {
  await testEnv.clearFirestore();
  await seedPendingDeletionUser();

  const ownerDb = testEnv.authenticatedContext("student1").firestore();
  await assertFails(getDoc(doc(ownerDb, "user_deletion_state/student1")));
  await assertFails(getDocs(collection(ownerDb, "user_deletion_audit")));
});

test("rules: nobody can write deletion state or audit log (admin included)", async () => {
  await testEnv.clearFirestore();
  await seedPendingDeletionUser();

  const adminDb = testEnv
    .authenticatedContext("admin1", { admin: true })
    .firestore();
  await assertFails(
    setDoc(doc(adminDb, "user_deletion_state/other"), { status: "purged" }),
  );
  await assertFails(
    updateDoc(doc(adminDb, "user_deletion_state/student1"), {
      status: "cancelled",
    }),
  );
  await assertFails(
    setDoc(doc(adminDb, "user_deletion_audit/audit2"), { action: "forged" }),
  );
});

test("rules: admin client cannot set or clear the deletion envelope on users", async () => {
  await testEnv.clearFirestore();
  await seedPendingDeletionUser();

  const adminDb = testEnv
    .authenticatedContext("admin1", { admin: true })
    .firestore();
  // Cannot remove the envelope written by the CF.
  await assertFails(
    updateDoc(doc(adminDb, "users/student1"), {
      accountStatus: deleteField(),
      deletion: deleteField(),
    }),
  );
  // Cannot flag a different user directly from a client.
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "users/student2"), {
      displayName: "Other",
    });
  });
  await assertFails(
    updateDoc(doc(adminDb, "users/student2"), {
      accountStatus: "pending_deletion",
    }),
  );
  // Unrelated admin edits still work.
  await assertSucceeds(
    updateDoc(doc(adminDb, "users/student2"), { displayName: "Renamed" }),
  );
});

test("rules: owner cannot touch the deletion envelope", async () => {
  await testEnv.clearFirestore();
  await seedPendingDeletionUser();

  const ownerDb = testEnv.authenticatedContext("student1").firestore();
  await assertFails(
    updateDoc(doc(ownerDb, "users/student1"), {
      accountStatus: deleteField(),
      deletion: deleteField(),
    }),
  );
  await assertFails(
    updateDoc(doc(ownerDb, "users/student1"), { accountStatus: "active" }),
  );
});

test("rules: owner cannot create their doc pre-flagged for deletion", async () => {
  await testEnv.clearFirestore();

  const ownerDb = testEnv.authenticatedContext("student3").firestore();
  await assertFails(
    setDoc(doc(ownerDb, "users/student3"), {
      displayName: "Sneaky",
      accountStatus: "pending_deletion",
    }),
  );
  await assertSucceeds(
    setDoc(doc(ownerDb, "users/student3"), { displayName: "Normal" }),
  );
});

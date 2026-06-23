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
import { doc, getDoc, setDoc, updateDoc } from "firebase/firestore";

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

async function seedBlockedUser(): Promise<void> {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await setDoc(doc(adminDb, "users/student1"), {
      quranSessionsProfile: {
        accountStatus: "blocked",
        restrictionReason: "policy_violation",
        gender: "male",
        countryCode: "EG",
        cityId: "cairo",
      },
    });
  });
}

test("rules: owner cannot self-unblock accountStatus", async () => {
  await testEnv.clearFirestore();
  await seedBlockedUser();

  const ownerDb = testEnv.authenticatedContext("student1").firestore();
  await assertFails(
    updateDoc(doc(ownerDb, "users/student1"), {
      quranSessionsProfile: {
        accountStatus: "active",
        restrictionReason: "policy_violation",
        gender: "male",
        countryCode: "EG",
        cityId: "cairo",
      },
    }),
  );
});

test("rules: owner cannot edit restrictionReason", async () => {
  await testEnv.clearFirestore();
  await seedBlockedUser();

  const ownerDb = testEnv.authenticatedContext("student1").firestore();
  await assertFails(
    updateDoc(doc(ownerDb, "users/student1"), {
      quranSessionsProfile: {
        accountStatus: "blocked",
        restrictionReason: "cleared",
        gender: "male",
        countryCode: "EG",
        cityId: "cairo",
      },
    }),
  );
});

test("rules: admin can update moderation fields", async () => {
  await testEnv.clearFirestore();
  await seedBlockedUser();

  const adminDb = testEnv
    .authenticatedContext("admin1", { admin: true })
    .firestore();
  await assertSucceeds(
    updateDoc(doc(adminDb, "users/student1"), {
      quranSessionsProfile: {
        accountStatus: "active",
        restrictionReason: null,
        gender: "male",
        countryCode: "EG",
        cityId: "cairo",
      },
    }),
  );
});

test("rules: owner cannot change eligibility fields after set", async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await setDoc(doc(adminDb, "users/student1"), {
      quranSessionsProfile: {
        accountStatus: "active",
        gender: "male",
        countryCode: "EG",
        cityId: "cairo",
      },
    });
  });

  const ownerDb = testEnv.authenticatedContext("student1").firestore();
  await assertFails(
    updateDoc(doc(ownerDb, "users/student1"), {
      quranSessionsProfile: {
        accountStatus: "active",
        gender: "male",
        countryCode: "EG",
        cityId: "alexandria",
      },
    }),
  );
});

test("rules: owner can set eligibility fields on first profile write", async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await setDoc(doc(adminDb, "users/student1"), {
      displayName: "Student",
    });
  });

  const ownerDb = testEnv.authenticatedContext("student1").firestore();
  await assertSucceeds(
    updateDoc(doc(ownerDb, "users/student1"), {
      quranSessionsProfile: {
        accountStatus: "active",
        gender: "male",
        countryCode: "EG",
        cityId: "cairo",
      },
    }),
  );
});

test("rules: owner cannot spoof gender after initial set", async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await setDoc(doc(adminDb, "users/student1"), {
      quranSessionsProfile: {
        accountStatus: "active",
        gender: "male",
        countryCode: "EG",
        cityId: "cairo",
      },
    });
  });

  const ownerDb = testEnv.authenticatedContext("student1").firestore();
  await assertFails(
    updateDoc(doc(ownerDb, "users/student1"), {
      quranSessionsProfile: {
        accountStatus: "active",
        gender: "female",
        countryCode: "EG",
        cityId: "cairo",
      },
    }),
  );
});

test("rules: unauthenticated user denied user doc write", async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "users/student1"), {
      displayName: "Student",
    });
  });

  const anonDb = testEnv.unauthenticatedContext().firestore();
  await assertFails(
    updateDoc(doc(anonDb, "users/student1"), { displayName: "Hacked" }),
  );
});

test("rules: owner can read own user doc", async () => {
  await testEnv.clearFirestore();
  await seedBlockedUser();

  const ownerDb = testEnv.authenticatedContext("student1").firestore();
  const snap = await assertSucceeds(getDoc(doc(ownerDb, "users/student1")));
  assert.equal(snap.get("quranSessionsProfile.accountStatus"), "blocked");
});

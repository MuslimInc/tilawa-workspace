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

async function seedUser(): Promise<void> {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await setDoc(doc(adminDb, "users/student1"), {
      displayName: "Student",
      session: {
        epoch: 1,
        activeDeviceId: "device-a",
      },
      notifications: {
        activeFcmToken: "token-a",
        platform: "android",
      },
    });
  });
}

test("rules: owner cannot bump session.epoch", async () => {
  await testEnv.clearFirestore();
  await seedUser();

  const ownerDb = testEnv.authenticatedContext("student1").firestore();
  await assertFails(
    updateDoc(doc(ownerDb, "users/student1"), {
      session: {
        epoch: 99,
        activeDeviceId: "device-a",
      },
    }),
  );
});

test("rules: owner cannot write notifications.activeFcmToken", async () => {
  await testEnv.clearFirestore();
  await seedUser();

  const ownerDb = testEnv.authenticatedContext("student1").firestore();
  await assertFails(
    updateDoc(doc(ownerDb, "users/student1"), {
      notifications: {
        activeFcmToken: "spoofed-token",
        platform: "android",
      },
    }),
  );
});

test("rules: owner cannot write fcm_tokens subcollection", async () => {
  await testEnv.clearFirestore();
  await seedUser();

  const ownerDb = testEnv.authenticatedContext("student1").firestore();
  await assertFails(
    setDoc(doc(ownerDb, "users/student1/fcm_tokens/spoofed"), {
      token: "spoofed-token",
      platform: "android",
    }),
  );
});

test("rules: owner cannot change session.activeDeviceId", async () => {
  await testEnv.clearFirestore();
  await seedUser();

  const ownerDb = testEnv.authenticatedContext("student1").firestore();
  await assertFails(
    updateDoc(doc(ownerDb, "users/student1"), {
      session: {
        epoch: 1,
        activeDeviceId: "device-spoofed",
      },
    }),
  );
});

test("rules: owner cannot change session.registeredAt", async () => {
  await testEnv.clearFirestore();
  await seedUser();

  const ownerDb = testEnv.authenticatedContext("student1").firestore();
  await assertFails(
    updateDoc(doc(ownerDb, "users/student1"), {
      session: {
        epoch: 1,
        activeDeviceId: "device-a",
        registeredAt: new Date(),
      },
    }),
  );
});

test("rules: owner can read own session epoch", async () => {
  await testEnv.clearFirestore();
  await seedUser();

  const ownerDb = testEnv.authenticatedContext("student1").firestore();
  const snap = await assertSucceeds(getDoc(doc(ownerDb, "users/student1")));
  assert.equal(snap.get("session.epoch"), 1);
});

test("rules: owner can update allowed profile fields", async () => {
  await testEnv.clearFirestore();
  await seedUser();

  const ownerDb = testEnv.authenticatedContext("student1").firestore();
  await assertSucceeds(
    updateDoc(doc(ownerDb, "users/student1"), {
      displayName: "Updated",
    }),
  );
});

test("rules: owner can set languageCode", async () => {
  await testEnv.clearFirestore();
  await seedUser();

  const ownerDb = testEnv.authenticatedContext("student1").firestore();
  await assertSucceeds(
    updateDoc(doc(ownerDb, "users/student1"), {
      languageCode: "ar",
    }),
  );

  const snap = await assertSucceeds(getDoc(doc(ownerDb, "users/student1")));
  assert.equal(snap.get("languageCode"), "ar");
});

import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import test from "node:test";
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
  type RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDoc,
  setDoc,
  updateDoc,
} from "firebase/firestore";

const PROJECT_ID = "demo-tilawa-rules";
let testEnv: RulesTestEnvironment;

const pendingNotification = {
  title: "Share MeMuslim",
  body: "Share with friends",
  targetType: "all",
  targetUserIds: [] as string[],
  createdAt: Date.now(),
  status: "pending",
  actionType: "home",
};

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

test("rules: non-admin cannot create notifications", async () => {
  await testEnv.clearFirestore();

  const userDb = testEnv.authenticatedContext("user1").firestore();
  await assertFails(addDoc(collection(userDb, "notifications"), pendingNotification));
});

test("rules: admin can create pending notifications", async () => {
  await testEnv.clearFirestore();

  const adminDb = testEnv
    .authenticatedContext("admin1", { admin: true })
    .firestore();
  await assertSucceeds(
    addDoc(collection(adminDb, "notifications"), pendingNotification),
  );
});

test("rules: admin cannot create notification with non-pending status", async () => {
  await testEnv.clearFirestore();

  const adminDb = testEnv
    .authenticatedContext("admin1", { admin: true })
    .firestore();
  await assertFails(
    addDoc(collection(adminDb, "notifications"), {
      ...pendingNotification,
      status: "sent",
    }),
  );
});

test("rules: admin can read notifications; clients cannot", async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "notifications/n1"), pendingNotification);
  });

  const adminDb = testEnv
    .authenticatedContext("admin1", { admin: true })
    .firestore();
  await assertSucceeds(getDoc(doc(adminDb, "notifications/n1")));

  const userDb = testEnv.authenticatedContext("user1").firestore();
  await assertFails(getDoc(doc(userDb, "notifications/n1")));
});

test("rules: admin cannot update or delete notifications", async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "notifications/n1"), pendingNotification);
  });

  const adminDb = testEnv
    .authenticatedContext("admin1", { admin: true })
    .firestore();
  await assertFails(
    updateDoc(doc(adminDb, "notifications/n1"), { status: "sent" }),
  );
  await assertFails(deleteDoc(doc(adminDb, "notifications/n1")));
});

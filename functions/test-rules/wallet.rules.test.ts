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
import { doc, getDoc, setDoc } from "firebase/firestore";

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

async function seedWalletData(): Promise<void> {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await setDoc(doc(adminDb, "user_wallets/wallet_student1"), {
      walletId: "wallet_student1",
      userId: "student1",
      currency: "EGP",
      status: "active",
      availableBalance: 100,
      heldBalance: 0,
      version: 1,
    });
    await setDoc(doc(adminDb, "wallet_transactions/txn_1"), {
      transactionId: "txn_1",
      walletId: "wallet_student1",
      userId: "student1",
      amount: 100,
      currency: "EGP",
      direction: "credit",
      status: "posted",
    });
  });
}

test("rules: owner can read own wallet", async () => {
  await testEnv.clearFirestore();
  await seedWalletData();

  const ownerDb = testEnv.authenticatedContext("student1").firestore();
  const snap = await assertSucceeds(
    getDoc(doc(ownerDb, "user_wallets/wallet_student1")),
  );
  assert.equal(snap.get("availableBalance"), 100);
});

test("rules: owner can read own wallet transactions", async () => {
  await testEnv.clearFirestore();
  await seedWalletData();

  const ownerDb = testEnv.authenticatedContext("student1").firestore();
  const snap = await assertSucceeds(
    getDoc(doc(ownerDb, "wallet_transactions/txn_1")),
  );
  assert.equal(snap.get("amount"), 100);
});

test("rules: other user cannot read wallet", async () => {
  await testEnv.clearFirestore();
  await seedWalletData();

  const otherDb = testEnv.authenticatedContext("student2").firestore();
  await assertFails(getDoc(doc(otherDb, "user_wallets/wallet_student1")));
});

test("rules: client cannot write wallet", async () => {
  await testEnv.clearFirestore();
  await seedWalletData();

  const ownerDb = testEnv.authenticatedContext("student1").firestore();
  await assertFails(
    setDoc(doc(ownerDb, "user_wallets/wallet_student1"), {
      availableBalance: 999,
    }),
  );
});

test("rules: admin can read any wallet", async () => {
  await testEnv.clearFirestore();
  await seedWalletData();

  const adminDb = testEnv
    .authenticatedContext("admin1", { admin: true })
    .firestore();
  const snap = await assertSucceeds(
    getDoc(doc(adminDb, "user_wallets/wallet_student1")),
  );
  assert.equal(snap.get("userId"), "student1");
});

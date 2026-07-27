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
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  where,
} from "firebase/firestore";

const PROJECT_ID = "demo-tilawa-rules";
let testEnv: RulesTestEnvironment;

const publishedDedication = {
  displayName: "Published Person",
  photoStoragePath: null,
  status: "published",
  isFounding: false,
  isFeatured: false,
  sortOrder: 1,
  publishedAt: new Date(),
  updatedAt: new Date(),
};

const draftDedication = {
  displayName: "Draft Person",
  slug: "draft-person",
  status: "draft",
  isFounding: false,
  isFeatured: false,
  sortOrder: 2,
};

test.before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(resolve(__dirname, "../../firestore.rules"), "utf8"),
    },
  });
});

test.after(async () => {
  await testEnv.cleanup();
});

test("rules: client reads safe projection; source records remain private", async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, "dedications/pub1"), publishedDedication);
    await setDoc(doc(db, "dedications/draft1"), draftDedication);
    await setDoc(
      doc(db, "published_dedications/pub1"),
      publishedDedication,
    );
  });

  const clientDb = testEnv.unauthenticatedContext().firestore();
  await assertSucceeds(
    getDoc(doc(clientDb, "published_dedications/pub1")),
  );
  await assertFails(getDoc(doc(clientDb, "dedications/pub1")));
  await assertFails(getDoc(doc(clientDb, "dedications/draft1")));
});

test("rules: client projection query succeeds; private ops denied", async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(
      doc(db, "published_dedications/pub1"),
      publishedDedication,
    );
    await setDoc(doc(db, "dedications/pub1/private/ops"), {
      internalOpsNote: "secret",
      channelRef: "wa-1",
    });
  });

  const clientDb = testEnv.unauthenticatedContext().firestore();
  await assertSucceeds(
    getDocs(
      query(
        collection(clientDb, "published_dedications"),
        where("status", "==", "published"),
      ),
    ),
  );
  await assertFails(getDoc(doc(clientDb, "dedications/pub1/private/ops")));
});

test("rules: config public read; client cannot write dedications", async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "app_config/sadaqah_jariyah"), {
      featureTitleEn: "Sadaqah Jariyah",
      featureEnabled: true,
    });
  });

  const clientDb = testEnv.unauthenticatedContext().firestore();
  await assertSucceeds(getDoc(doc(clientDb, "app_config/sadaqah_jariyah")));
  await assertFails(
    setDoc(doc(clientDb, "dedications/hack"), publishedDedication),
  );
  await assertFails(
    setDoc(
      doc(clientDb, "published_dedications/hack"),
      publishedDedication,
    ),
  );
});

test("rules: admin can read draft and private ops", async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, "dedications/draft1"), draftDedication);
    await setDoc(doc(db, "dedications/draft1/private/ops"), {
      internalOpsNote: "ops",
    });
  });

  const adminDb = testEnv
    .authenticatedContext("admin1", { admin: true })
    .firestore();
  await assertSucceeds(getDoc(doc(adminDb, "dedications/draft1")));
  await assertSucceeds(getDoc(doc(adminDb, "dedications/draft1/private/ops")));
});

test("rules: admin projection rejects private fields", async () => {
  await testEnv.clearFirestore();
  const adminDb = testEnv
    .authenticatedContext("admin1", { admin: true })
    .firestore();

  await assertSucceeds(
    setDoc(
      doc(adminDb, "published_dedications/safe"),
      publishedDedication,
    ),
  );
  await assertFails(
    setDoc(doc(adminDb, "published_dedications/unsafe"), {
      ...publishedDedication,
      note: "private note",
      updatedByAdminId: "admin1",
    }),
  );
});

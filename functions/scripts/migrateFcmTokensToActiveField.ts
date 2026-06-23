/**
 * Migrates legacy `users/{uid}/fcm_tokens/*` to embedded `notifications.activeFcmToken`.
 *
 * Usage:
 *   FIREBASE_PROJECT_ID=quran-playera-app npm run migrate:fcm-tokens
 *   FIREBASE_PROJECT_ID=quran-playera-app npm run migrate:fcm-tokens -- --apply
 *   FIREBASE_PROJECT_ID=quran-playera-app npm run migrate:fcm-tokens -- --userId=UID --apply
 */
import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";

const APPLY = process.argv.includes("--apply");

function parseUserId(): string | undefined {
  for (const arg of process.argv.slice(2)) {
    if (arg.startsWith("--userId=")) {
      return arg.slice("--userId=".length).trim() || undefined;
    }
  }
  return undefined;
}

interface MigrationRow {
  userId: string;
  selectedToken: string | null;
  platform: string | null;
  legacyDocCount: number;
  action: "skip" | "set" | "clear";
  reason: string;
}

function tokenCreatedAtMillis(data: FirebaseFirestore.DocumentData): number {
  const createdAt = data.createdAt;
  if (createdAt instanceof Timestamp) {
    return createdAt.toMillis();
  }
  if (
    createdAt != null &&
    typeof createdAt === "object" &&
    "toDate" in createdAt &&
    typeof (createdAt as { toDate: () => Date }).toDate === "function"
  ) {
    return (createdAt as { toDate: () => Date }).toDate().getTime();
  }
  return 0;
}

async function main(): Promise<void> {
  const projectId = process.env.FIREBASE_PROJECT_ID ?? "quran-playera-app";
  initializeApp({ projectId });
  const db = getFirestore();

  const singleUserId = parseUserId();
  const userDocs = singleUserId
    ? await db
        .collection("users")
        .doc(singleUserId)
        .get()
        .then((doc) => (doc.exists ? [doc] : []))
    : (await db.collection("users").get()).docs;

  const rows: MigrationRow[] = [];
  let writes = 0;

  for (const userDoc of userDocs) {
    const userId = userDoc.id;
    const userData = userDoc.data() ?? {};
    const existingToken = userData.notifications?.activeFcmToken;
    if (typeof existingToken === "string" && existingToken.length > 0) {
      rows.push({
        userId,
        selectedToken: existingToken,
        platform: userData.notifications?.platform ?? null,
        legacyDocCount: 0,
        action: "skip",
        reason: "embedded_token_already_set",
      });
      continue;
    }

    const tokensSnap = await userDoc.ref.collection("fcm_tokens").get();
    if (tokensSnap.empty) {
      rows.push({
        userId,
        selectedToken: null,
        platform: null,
        legacyDocCount: 0,
        action: "skip",
        reason: "no_legacy_tokens",
      });
      continue;
    }

    const newest = [...tokensSnap.docs].sort(
      (a, b) => tokenCreatedAtMillis(b.data()) - tokenCreatedAtMillis(a.data()),
    )[0];
    const token = String(newest.data().token ?? newest.id);
    const platform = String(newest.data().platform ?? "android");

    rows.push({
      userId,
      selectedToken: token,
      platform,
      legacyDocCount: tokensSnap.size,
      action: "set",
      reason: "newest_legacy_token",
    });

    if (APPLY) {
      const batch = db.batch();
      batch.set(
        userDoc.ref,
        {
          notifications: {
            activeFcmToken: token,
            tokenUpdatedAt: FieldValue.serverTimestamp(),
            platform,
          },
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      for (const legacyDoc of tokensSnap.docs) {
        batch.delete(legacyDoc.ref);
      }
      await batch.commit();
      writes += 1;
    }
  }

  console.log(
    JSON.stringify(
      {
        projectId,
        apply: APPLY,
        usersScanned: userDocs.length,
        writes,
        rows,
      },
      null,
      2,
    ),
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

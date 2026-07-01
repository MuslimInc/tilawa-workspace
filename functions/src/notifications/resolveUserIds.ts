import { FieldPath } from "firebase-admin/firestore";

const USER_ID_PAGE_SIZE = 500;

export interface NotificationTarget {
  targetType: "all" | "single" | "selected";
  targetUserIds: string[];
}

export class BroadcastAllUsersDisabledError extends Error {
  constructor() {
    super(
      "Broadcast to all users is disabled in production. " +
        "Use targetType 'selected' with explicit user IDs."
    );
    this.name = "BroadcastAllUsersDisabledError";
  }
}

/** Full collection scans are allowed only in the Functions emulator. */
export function isFullUserCollectionScanAllowed(): boolean {
  return process.env.FUNCTIONS_EMULATOR === "true";
}

/**
 * Resolve target user IDs based on targetType.
 * Production blocks unbounded "all" scans; emulator uses paginated reads.
 */
export async function resolveUserIds(
  db: FirebaseFirestore.Firestore,
  notification: NotificationTarget
): Promise<string[]> {
  if (notification.targetType === "all") {
    if (!isFullUserCollectionScanAllowed()) {
      throw new BroadcastAllUsersDisabledError();
    }
    return collectAllUserIdsPaginated(db);
  }
  return notification.targetUserIds;
}

async function collectAllUserIdsPaginated(
  db: FirebaseFirestore.Firestore
): Promise<string[]> {
  const userIds: string[] = [];
  let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | undefined;

  while (true) {
    let query = db
      .collection("users")
      .orderBy(FieldPath.documentId())
      .limit(USER_ID_PAGE_SIZE);

    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const snapshot = await query.get();
    if (snapshot.empty) {
      break;
    }

    userIds.push(...snapshot.docs.map((doc) => doc.id));
    lastDoc = snapshot.docs[snapshot.docs.length - 1];

    if (snapshot.docs.length < USER_ID_PAGE_SIZE) {
      break;
    }
  }

  return userIds;
}

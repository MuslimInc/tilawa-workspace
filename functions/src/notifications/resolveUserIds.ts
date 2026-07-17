import { FieldPath } from "firebase-admin/firestore";

const USER_ID_PAGE_SIZE = 500;

export interface NotificationTarget {
  targetType: "all" | "single" | "selected";
  targetUserIds: string[];
}

/**
 * Resolve target user IDs based on targetType.
 * `all` uses paginated reads over the users collection.
 */
export async function resolveUserIds(
  db: FirebaseFirestore.Firestore,
  notification: NotificationTarget
): Promise<string[]> {
  if (notification.targetType === "all") {
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

import { HttpsError, CallableRequest } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import { lifecycleError } from "./lifecycleErrors";
import {
  assertClientSessionEpoch,
  readServerSessionEpoch,
} from "./sessionRegistration";
import type { ActorRole } from "./sessionLifecycleGuard";

export interface BookingParticipants {
  studentId: string;
  teacherId: string;
}

export function requireAuthenticatedUid(
  request: CallableRequest<unknown>,
): string {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  return uid;
}

export async function requireValidSessionEpoch(
  request: CallableRequest<unknown>,
  uid: string,
  db: FirebaseFirestore.Firestore = getFirestore(),
): Promise<void> {
  const data = request.data as Record<string, unknown> | undefined;
  const userSnap = await db.collection("users").doc(uid).get();
  const serverEpoch = readServerSessionEpoch(userSnap.data());

  try {
    assertClientSessionEpoch(data?.sessionEpoch, serverEpoch);
  } catch (error) {
    const code =
      error instanceof Error && error.message === "session_epoch_required"
        ? "Session epoch required."
        : "Session revoked on another device.";
    throw new HttpsError("failed-precondition", code);
  }
}

export function requireAdmin(request: CallableRequest<unknown>): string {
  const uid = requireAuthenticatedUid(request);
  if (!request.auth?.token?.admin) {
    throw lifecycleError("unauthorized_actor", "Admin access required.", {
      actorRole: "admin",
    });
  }
  return uid;
}

export function isAdmin(request: CallableRequest<unknown>): boolean {
  return request.auth?.token?.admin === true;
}

export async function requireValidSessionEpochUnlessAdmin(
  request: CallableRequest<unknown>,
  uid: string,
): Promise<void> {
  if (isAdmin(request)) {
    return;
  }
  await requireValidSessionEpoch(request, uid);
}

export function resolveActorRole(
  request: CallableRequest<unknown>,
  claimedRole: ActorRole | undefined,
  participants: BookingParticipants,
): ActorRole {
  const uid = requireAuthenticatedUid(request);

  if (isAdmin(request)) {
    return claimedRole === "system" ? "system" : "admin";
  }

  if (uid === participants.studentId) {
    if (claimedRole != null && claimedRole !== "student") {
      throw lifecycleError("unauthorized_actor", "Student cannot act as another role.", {
        actorRole: claimedRole,
      });
    }
    return "student";
  }

  if (uid === participants.teacherId) {
    if (claimedRole != null && claimedRole !== "teacher") {
      throw lifecycleError("unauthorized_actor", "Teacher cannot act as another role.", {
        actorRole: claimedRole,
      });
    }
    return "teacher";
  }

  throw lifecycleError("not_participant", "Caller is not a session participant.", {
    actorId: uid,
  });
}

export function requireParticipantOrAdmin(
  request: CallableRequest<unknown>,
  participants: BookingParticipants,
): { uid: string; actor: ActorRole } {
  const uid = requireAuthenticatedUid(request);
  if (isAdmin(request)) {
    return { uid, actor: "admin" };
  }
  if (uid === participants.studentId) {
    return { uid, actor: "student" };
  }
  if (uid === participants.teacherId) {
    return { uid, actor: "teacher" };
  }
  throw lifecycleError("not_participant", "Caller is not a session participant.", {
    actorId: uid,
  });
}

export function requireAdminOrSystemActor(
  request: CallableRequest<unknown>,
  claimedRole: ActorRole | undefined,
): { uid: string; actor: ActorRole } {
  if (claimedRole === "system") {
    throw lifecycleError("unauthorized_actor", "System actor must use backend jobs.", {
      actorRole: "system",
    });
  }
  return { uid: requireAdmin(request), actor: "admin" };
}

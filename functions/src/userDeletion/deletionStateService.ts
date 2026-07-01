import { createHash } from "node:crypto";

import {
  DocumentReference,
  FieldValue,
  Firestore,
  Timestamp,
} from "firebase-admin/firestore";

import {
  USER_DELETION_AUDIT_COLLECTION,
  USER_DELETION_STATE_COLLECTION,
} from "./deletionManifest";

export type DeletionStatus =
  | "pending_deletion"
  | "purging"
  | "purged"
  | "cancelled";

export type DeletionAuditAction =
  | "requested"
  | "cancelled"
  | "purge_started"
  | "purged"
  | "purge_failed";

export interface TeacherVisibilitySnapshot {
  isActive: boolean;
  isPubliclyVisible: boolean;
}

/**
 * user_deletion_state/{uid} — the purge state machine. Lives OUTSIDE the
 * users/{uid} tree so progress tracking survives the owned-tree delete: a
 * crash between deleting users/{uid} and deleting the Auth user must still
 * leave a queryable record for the next scheduler run to finish from.
 */
export interface DeletionStateDoc {
  userId: string;
  status: DeletionStatus;
  reason: string;
  requestedBy: string;
  requestedAt: Timestamp;
  purgeAfter: Timestamp;
  /** sha256 of the Auth email — audit stays useful after PII is purged. */
  targetEmailHash: string | null;
  priorAccountStatus: string | null;
  priorProfileAccountStatus: string | null;
  priorTeacherVisibility: TeacherVisibilitySnapshot | null;
  teacherProfileId: string | null;
  completedSteps: string[];
  financialSummary: Record<string, unknown> | null;
  purgedAt: Timestamp | null;
  cancelledAt: Timestamp | null;
  cancelledBy: string | null;
  cancelReason: string | null;
  /** True when the target has a Firestore profile but no Firebase Auth user. */
  firestoreOnly?: boolean;
}

export function hashEmail(email: string): string {
  return createHash("sha256")
    .update(email.trim().toLowerCase())
    .digest("hex");
}

export function deletionStateRef(
  db: Firestore,
  uid: string,
): DocumentReference {
  return db.collection(USER_DELETION_STATE_COLLECTION).doc(uid);
}

export async function appendDeletionAuditEvent(
  db: Firestore,
  event: {
    targetUserId: string;
    action: DeletionAuditAction;
    actorUid: string;
    reason?: string | null;
    targetEmailHash?: string | null;
    details?: Record<string, unknown>;
  },
): Promise<string> {
  const ref = db.collection(USER_DELETION_AUDIT_COLLECTION).doc();
  await ref.set({
    targetUserId: event.targetUserId,
    action: event.action,
    actorUid: event.actorUid,
    reason: event.reason ?? null,
    targetEmailHash: event.targetEmailHash ?? null,
    details: event.details ?? {},
    createdAt: FieldValue.serverTimestamp(),
  });
  return ref.id;
}


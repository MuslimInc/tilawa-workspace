/** Append-only audit row from user_deletion_audit. */
export interface UserDeletionAuditEvent {
  readonly id: string;
  readonly targetUserId: string;
  readonly action: string;
  readonly actorUid: string;
  readonly reason: string | null;
  readonly createdAt: Date | null;
}

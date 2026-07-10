/**
 * Explicit deletion manifest for admin-initiated user deletion.
 *
 * Every top-level Firestore collection MUST be classified here. The unit test
 * in test/userDeletionManifest.test.ts parses firestore.rules and fails if a
 * collection exists without a classification — new user-linked collections
 * cannot silently escape the deletion flow.
 *
 * There is intentionally NO discovery-based deletion (no "scan for fields
 * matching the uid"). The purge pipeline only touches collections listed with
 * `delete` or `anonymize`, each with an explicit handler.
 *
 * Design doc: docs/plans/admin_user_deletion_plan.md
 */

/** Days between requestUserDeletion and the hard purge. */
export const PURGE_GRACE_DAYS = 30;

/** Purge state machine + envelope, keyed by target uid. CF-only. */
export const USER_DELETION_STATE_COLLECTION = "user_deletion_state";

/** Append-only audit event log. Admin read, CF write. */
export const USER_DELETION_AUDIT_COLLECTION = "user_deletion_audit";

/**
 * Booking lifecycle statuses that block a deletion request: the admin must
 * cancel or complete the user's open bookings first, so the counterparty is
 * never left with a live booking against a vanishing account.
 */
export const ACTIVE_BOOKING_STATUSES = [
  "draft",
  "pending_payment",
  "pending_tutor_approval",
  "scheduled",
  "confirmed",
  "in_progress",
  "rescheduled",
  "disputed",
] as const;

/**
 * PII fields blanked on quran_teacher_profiles at purge. The doc itself is
 * retained (anonymized) because other users' bookings/sessions reference the
 * profile doc id. Field list mirrors TeacherProfileDto in
 * packages/quran_sessions/lib/src/data/dtos/teacher_profile_dto.dart.
 */
export const TEACHER_PROFILE_PII_FIELDS = [
  "displayName",
  "avatarUrl",
  "publicBio",
  "externalMeetingUrl",
] as const;

/** Subcollections of quran_teacher_profiles/{id} hard-deleted at purge. */
export const TEACHER_PROFILE_SUBCOLLECTIONS = [
  "pricing",
  "availability_config",
  "availability_overrides",
  "availability",
] as const;

/** Placeholder shown wherever an anonymized display field is read. */
export const ANONYMIZED_PLACEHOLDER = "deleted_account";

export type CollectionClassification =
  /** Hard-deleted during purge by an explicit handler. */
  | "delete"
  /** PII stripped in place; ids/amounts/timestamps kept. */
  | "anonymize"
  /** Kept untouched (financial ledger, safety evidence, idempotency). */
  | "retain"
  /** No user linkage; the purge never enumerates it. */
  | "unrelated";

/**
 * Classification of every top-level collection in firestore.rules.
 * Keys must match the collection names in the rules file exactly.
 */
export const COLLECTION_CLASSIFICATIONS: Record<
  string,
  CollectionClassification
> = {
  // ── delete ────────────────────────────────────────────────────────────
  // users/{uid} + all subcollections via recursiveDelete; a financial
  // summary of purchases/cancellations is exported to the deletion state
  // doc first.
  users: "delete",
  // Contains identity PII; no shared linkage.
  quran_teacher_applications: "delete",
  // Balance verified zero at request time and re-verified at purge.
  user_wallets: "delete",
  // Purely denormalized, rebuildable.
  quran_teacher_metrics: "delete",
  quran_student_metrics: "delete",

  // ── anonymize ─────────────────────────────────────────────────────────
  // Doc retained (referenced by other users' bookings); PII blanked,
  // unpublished, subcollections deleted.
  quran_teacher_profiles: "anonymize",
  // Free-text `reason` blanked for requests authored by the user.
  quran_reschedule_requests: "anonymize",
  // Transient outbox: uid removed from recipientUserIds; doc deleted when
  // the user was the sole recipient.
  quran_session_notifications: "anonymize",
  // Campaign docs target many users: uid removed from targetUserIds only.
  notifications: "anonymize",

  // ── retain ────────────────────────────────────────────────────────────
  // Shared two-party records referencing users by id only (verified: no
  // denormalized name/email fields) — retained so the counterparty's
  // history stays intact. The uid becomes a tombstone after purge.
  quran_bookings: "retain",
  quran_sessions: "retain",
  quran_session_events: "retain",
  // Financial ledgers — legal retention.
  wallet_transactions: "retain",
  quran_payment_intents: "retain",
  quran_payment_transactions: "retain",
  quran_session_refunds: "retain",
  quran_session_compensations: "retain",
  support_purchases: "retain",
  // Safety evidence — deletion must never destroy reports/disputes about
  // the deleted user.
  quran_session_reports: "retain",
  quran_session_disputes: "retain",
  // Backend idempotency ledger.
  quran_session_operations: "retain",
  // Deletion flow's own collections.
  user_deletion_state: "retain",
  user_deletion_audit: "retain",

  // ── unrelated ─────────────────────────────────────────────────────────
  // NOTE: app_config is intentionally NOT listed. firestore.rules exposes it
  // only as a single fixed public document (match /app_config/in_app_update),
  // not as a /app_config/{docId} collection, so it holds no per-user data and
  // the rules parser never surfaces it as a top-level collection. Adding it
  // here would drift from the parser and fail the manifest guard test. If a
  // per-user /app_config/{...} collection is ever introduced, the guard will
  // force a classification then.
  subscription_plans: "unrelated",
  quran_session_market_configs: "unrelated",
  quran_session_platform_config: "unrelated",
  // Occupancy markers guarding OTHER users' booked slots; deleting them
  // would allow double-booking. They are released by the booking lifecycle
  // (see expirePendingReservations), and the active-bookings guard blocks
  // deletion while any exist for this user.
  quran_slot_locks: "unrelated",
};

/** Ordered, idempotent purge steps. Auth deletion is strictly last. */
export const PURGE_STEPS = [
  "financial_summary",
  "fcm_tokens",
  "teacher_application",
  "teacher_profile",
  "reschedule_requests",
  "notification_outbox",
  "campaign_targets",
  "metrics",
  "wallet",
  "owned_tree",
  "auth_user",
] as const;

export type PurgeStep = (typeof PURGE_STEPS)[number];


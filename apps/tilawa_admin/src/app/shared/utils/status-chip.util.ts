/** Visual variant for admin status chips — maps domain status strings. */
export type StatusChipVariant =
  | 'success'
  | 'warning'
  | 'danger'
  | 'neutral'
  | 'scholar'
  | 'info';

const SUCCESS = new Set([
  'approved',
  'active',
  'verified',
  'completed',
  'confirmed',
  'resolved',
  'resolved_favor_student',
  'resolved_favor_teacher',
  'resolved_with_compensation',
  'compensated',
  'refunded',
  'closed',
  'complete',
]);

const WARNING = new Set([
  'pending',
  'pending_payment',
  'under_review',
  'underReview',
  'disputed',
  'in_progress',
  'scheduled',
  'rescheduled',
  'opened',
  'open',
  'incomplete',
  'suspended',
]);

const DANGER = new Set([
  'rejected',
  'blocked',
  'revoked',
  'cancelled_by_student',
  'cancelled_by_teacher',
  'cancelled_by_admin',
  'teacher_no_show',
  'student_no_show',
  'both_no_show',
  'dismissed',
  'expired',
  'inactive',
]);

const NEUTRAL = new Set(['draft', 'none', 'unknown']);

function normalizeStatus(status: string): string {
  return status
    .replace(/([a-z])([A-Z])/g, '$1_$2')
    .trim()
    .toLowerCase();
}

/**
 * Resolves a domain status string to a chip color variant.
 * Scholar (secondary green) is reserved for metadata-style labels.
 */
export function resolveStatusVariant(
  status: string,
  options?: { scholar?: boolean },
): StatusChipVariant {
  if (options?.scholar) {
    return 'scholar';
  }

  const key = normalizeStatus(status);

  if (SUCCESS.has(key)) {
    return 'success';
  }
  if (WARNING.has(key)) {
    return 'warning';
  }
  if (DANGER.has(key)) {
    return 'danger';
  }
  if (NEUTRAL.has(key)) {
    return 'neutral';
  }

  return 'info';
}

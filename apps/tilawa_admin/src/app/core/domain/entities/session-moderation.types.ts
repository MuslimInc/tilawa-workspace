export type NoShowClassification =
  | 'teacher_no_show'
  | 'student_no_show'
  | 'both_no_show';

export type SessionCompensationType =
  | 'restore_credit'
  | 'wallet_credit'
  | 'replacement_session'
  | 'extend_subscription'
  | 'manual_review';

export type DisputeResolution =
  | 'favor_student'
  | 'favor_teacher'
  | 'with_compensation'
  | 'rejected'
  | 'closed';

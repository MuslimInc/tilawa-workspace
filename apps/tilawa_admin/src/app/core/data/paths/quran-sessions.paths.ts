/** Firestore collection paths — infrastructure only; never import from components. */
export abstract class QuranSessionsPaths {
  static readonly users = 'users';
  static readonly teacherApplications = 'quran_teacher_applications';
  static readonly teacherProfiles = 'quran_teacher_profiles';
  static readonly bookings = 'quran_bookings';
  static readonly sessions = 'quran_sessions';
  static readonly sessionEvents = 'quran_session_events';
  static readonly sessionCompensations = 'quran_session_compensations';
  static readonly rescheduleRequests = 'quran_reschedule_requests';
  static readonly sessionReports = 'quran_session_reports';
  static readonly sessionDisputes = 'quran_session_disputes';
  static readonly userWallets = 'user_wallets';
  static readonly walletTransactions = 'wallet_transactions';
  static readonly quranSessionsProfileField = 'quranSessionsProfile';
}

export abstract class TilawaPaths {
  static readonly notifications = 'notifications';
}

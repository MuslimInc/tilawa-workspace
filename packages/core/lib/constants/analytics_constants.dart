/// Analytics event names and parameter keys
class AnalyticsEvents {
  // Authentication
  static const String login = 'login';
  static const String signUp = 'sign_up';
  static const String userSignOut = 'user_sign_out';

  // Navigation
  static const String screenView = 'screen_view';

  // App Lifecycle
  static const String appStart = 'app_start';
  static const String startupPhase = 'startup_phase';
  static const String startupFailed = 'startup_failed';
  static const String startupCompleted = 'startup_completed';

  // Audio Player
  static const String audioPlay = 'audio_play';
  static const String audioPause = 'audio_pause';
  static const String audioStop = 'audio_stop';
  static const String audioSeek = 'audio_seek';

  // Athkar
  static const String athkarCategoriesLoaded = 'athkar_categories_loaded';
  static const String athkarItemsLoaded = 'athkar_items_loaded';
  static const String athkarItemDecrement = 'athkar_item_decrement';
  static const String athkarItemCompleted = 'athkar_item_completed';
  static const String athkarItemReset = 'athkar_item_reset';
  static const String athkarNotificationOpen = 'athkar_notification_open';
  static const String athkarReadStart = 'athkar_read_start';

  // Commerce/Premium
  static const String purchase = 'purchase';
  static const String subscriptionStart = 'subscription_start';
  static const String subscriptionCancel = 'subscription_cancel';

  // Support Tilawa (voluntary one-time)
  static const String supportScreenViewed = 'support_screen_viewed';
  static const String supportTierSelected = 'support_tier_selected';
  static const String supportPurchaseStarted = 'support_purchase_started';
  static const String supportPurchaseVerified = 'support_purchase_verified';
  static const String supportPurchaseFailed = 'support_purchase_failed';
  static const String supportRestoreTapped = 'support_restore_tapped';

  // Engagement
  static const String search = 'search';
  static const String share = 'share';
  static const String favorite = 'favorite';
  static const String rating = 'rating';

  // What's new
  static const String whatsNewShown = 'whats_new_shown';
  static const String whatsNewDismissed = 'whats_new_dismissed';
  static const String whatsNewSkipped = 'whats_new_skipped';
  static const String whatsNewOpenSettings = 'whats_new_open_settings';
  static const String whatsNewLoadFailed = 'whats_new_load_failed';

  // Today Plan
  static const String todayPlanViewed = 'today_plan_viewed';
  static const String todayPlanStarted = 'today_plan_started';
  static const String todayPlanCompleted = 'today_plan_completed';
  static const String todayPlanTaskCompleted = 'today_plan_task_completed';
  static const String todayPlanContinueReading = 'today_plan_continue_reading';
  static const String todayPlanContinueListening =
      'today_plan_continue_listening';
  static const String todayPlanPremiumClicked = 'today_plan_premium_clicked';
  static const String todayPlanPremiumConverted =
      'today_plan_premium_converted';
  static const String khatmaCreated = 'khatma_created';
  static const String khatmaStarted = 'khatma_started';
  static const String khatmaProgressUpdated = 'khatma_progress_updated';
  static const String khatmaGoalCompleted = 'khatma_goal_completed';
  static const String khatmaPlanAdjusted = 'khatma_plan_adjusted';
  static const String khatmaCatchupSelected = 'khatma_catchup_selected';
  static const String khatmaExtendSelected = 'khatma_extend_selected';
  static const String khatmaCompleted = 'khatma_completed';
  static const String khatmaDashboardViewed = 'khatma_dashboard_viewed';
  static const String khatmaContinueReading = 'khatma_continue_reading';
  static const String khatmaReset = 'khatma_reset';

  // Quran Sessions
  static const String teacherApplyEntrySeen = 'teacher_apply_entry_seen';
  static const String teacherApplyStarted = 'teacher_apply_started';
  static const String teacherApplicationSubmitted =
      'teacher_application_submitted';
  static const String teacherApplicationStatusViewed =
      'teacher_application_status_viewed';
  static const String teacherApplicationApproved =
      'teacher_application_approved';
  static const String teacherApplicationRejected =
      'teacher_application_rejected';
  static const String teacherDashboardOpened = 'teacher_dashboard_opened';
  static const String quranSessionsEmptyStateSeen =
      'quran_sessions_empty_state_seen';
  static const String quranSessionsNotifyInterestSubmitted =
      'quran_sessions_notify_interest_submitted';

  // Scheduling experiment (Phase 1)
  static const String weekViewOpened = 'week_view_opened';
  static const String fridayReviewBannerShown = 'friday_review_banner_shown';
  static const String fridayReviewBannerTapped = 'friday_review_banner_tapped';
  static const String fridayReviewBannerDismissed =
      'friday_review_banner_dismissed';
  static const String weeklyTemplateOpened = 'weekly_template_opened';
  static const String weeklyTemplateSaved = 'weekly_template_saved';
  static const String bookingLostDueToNoAvailability =
      'booking_lost_due_to_no_availability';
}

class AnalyticsParams {
  // Common
  static const String method = 'method';
  static const String error = 'error';
  static const String count = 'count';
  static const String timestamp = 'timestamp';

  /// Wall-clock ms when the action occurred on device (for offline-delayed uploads).
  static const String clientTimestampMs = 'client_timestamp_ms';
  static const String reason = 'reason';
  static const String action = 'action';
  static const String source = 'source';
  static const String phase = 'phase';
  static const String elapsedMs = 'elapsed_ms';
  static const String appVersion = 'app_version';
  static const String buildNumber = 'build_number';
  static const String patchNumber = 'patch_number';
  static const String platform = 'platform';
  static const String sessionId = 'session_id';
  static const String releaseId = 'release_id';

  // Navigation
  static const String screenName = 'screen_name';
  static const String screenClass = 'screen_class';

  // Audio/Content
  static const String audioId = 'audio_id';
  static const String audioName = 'audio_name';
  static const String artist = 'artist';
  static const String position = 'position';

  // Downloads
  static const String downloadId = 'download_id';
  static const String fileName = 'file_name';
  static const String fileSize = 'file_size';
  static const String surahId = 'surah_id';
  static const String surahTitle = 'surah_title';
  static const String surahName = 'surah_name';
  static const String reciterName = 'reciter_name';
  static const String reciterId = 'reciter_id';
  static const String moshafName = 'moshaf_name';

  // Athkar
  static const String categoryId = 'category_id';
  static const String itemId = 'item_id';
  static const String itemText = 'item_text';
  static const String remainingCount = 'remaining_count';

  // Commerce
  static const String transactionId = 'transaction_id';
  static const String value = 'value';
  static const String currency = 'currency';
  static const String planId = 'plan_id';
  static const String subscriptionId = 'subscription_id';
  static const String productId = 'product_id';
  static const String purchaseReason = 'purchase_reason';

  // Other
  static const String searchTerm = 'search_term';
  static const String resultCount = 'result_count';
  static const String contentType = 'content_type';
  static const String itemType = 'item_type';
  static const String ratingValue = 'rating';

  // Screens
  static const String reciterDetailsScreen = 'ReciterDetailsScreen';
}

class UserProperties {
  static const String userType = 'user_type';
  static const String signInMethod = 'sign_in_method';
}

class UserPropertyValues {
  static const String authenticated = 'authenticated';
  static const String anonymous = 'anonymous';
  static const String unknown = 'unknown';
}

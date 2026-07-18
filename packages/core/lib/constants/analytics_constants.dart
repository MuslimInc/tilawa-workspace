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

  // Learn Quran funnel (student)
  static const String homeLearnQuranCardViewed = 'home_learn_quran_card_viewed';
  static const String homeLearnQuranCardTapped = 'home_learn_quran_card_tapped';
  static const String homeLearnQuranMySessionsTapped =
      'home_learn_quran_my_sessions_tapped';
  static const String teacherListViewed = 'teacher_list_viewed';
  static const String teacherProfileViewed = 'teacher_profile_viewed';
  static const String bookingStarted = 'booking_started';
  static const String bookingCompleted = 'booking_completed';
  static const String mySessionsOpened = 'my_sessions_opened';
  static const String sessionJoined = 'session_joined';
  static const String reviewSubmitted = 'review_submitted';

  // Teacher application (Google Form entry)
  static const String teacherApplicationEntrySeen =
      'teacher_application_entry_seen';
  static const String teacherApplicationEntryTapped =
      'teacher_application_entry_tapped';
  static const String teacherApplicationFormOpened =
      'teacher_application_form_opened';
  static const String teacherApplicationFormFailed =
      'teacher_application_form_failed';

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

  // Islamic Widgets
  static const String widgetAdded = 'widget_added';
  static const String widgetRemoved = 'widget_removed';
  static const String widgetTapped = 'widget_tapped';
  static const String widgetSnapshotGenerated = 'widget_snapshot_generated';

  // Islamic Reels
  static const String reelViewStart = 'reel_view_start';
  static const String reelViewComplete = 'reel_view_complete';
  static const String reelReaction = 'reel_reaction';
  static const String reelSave = 'reel_save';
  static const String reelShare = 'reel_share';

  // Islamic Radio
  static const String radioStationOpened = 'radio_station_opened';
  static const String radioPlay = 'radio_play';
  static const String radioStop = 'radio_stop';
  static const String radioFavorite = 'radio_favorite';
  static const String radioShare = 'radio_share';
  static const String radioListenDuration = 'radio_listen_duration';
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

  // Learn Quran funnel (safe IDs / enums only — no names, notes, or PII)
  static const String teacherId = 'teacher_id';
  static const String bookingId = 'booking_id';
  static const String isPaid = 'is_paid';
  static const String pricingType = 'pricing_type';
  static const String callType = 'call_type';

  // Other
  static const String searchTerm = 'search_term';
  static const String resultCount = 'result_count';
  static const String contentType = 'content_type';
  static const String itemType = 'item_type';
  static const String ratingValue = 'rating';

  // Widgets
  static const String widgetType = 'widget_type';
  static const String widgetSizeClass = 'widget_size_class';
  static const String widgetAction = 'widget_action';

  // Screens
  static const String reciterDetailsScreen = 'ReciterDetailsScreen';

  // Islamic Reels
  static const String reelId = 'reel_id';
  static const String reactionType = 'reaction_type';
  static const String shareMode = 'share_mode';

  // Islamic Radio
  static const String radioStationId = 'radio_station_id';
  static const String radioStationName = 'radio_station_name';
  static const String listenDurationSeconds = 'listen_duration_seconds';
  static const String isFavorite = 'is_favorite';
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

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

  // Engagement
  static const String search = 'search';
  static const String share = 'share';
  static const String favorite = 'favorite';
  static const String rating = 'rating';
}

class AnalyticsParams {
  // Common
  static const String method = 'method';
  static const String error = 'error';
  static const String count = 'count';
  static const String timestamp = 'timestamp';
  static const String reason = 'reason';
  static const String action = 'action';
  static const String source = 'source';

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

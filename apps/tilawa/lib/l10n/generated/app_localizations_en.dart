// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get unknownLocation => 'Unknown Location';

  @override
  String get toQibla => 'To Qibla';

  @override
  String get north => 'N';

  @override
  String get east => 'E';

  @override
  String get south => 'S';

  @override
  String get west => 'W';

  @override
  String get appTitle => 'MeMuslim';

  @override
  String get reciters => 'Reciters';

  @override
  String get searchReciters => 'Search reciters...';

  @override
  String get loadingReciters => 'Loading reciters...';

  @override
  String get homeTitle => 'Home';

  @override
  String get homeGreeting => 'Assalamu alaikum';

  @override
  String homeGreetingName(String name) {
    return 'Assalamu alaikum, $name';
  }

  @override
  String get homeProfileLabel => 'User profile';

  @override
  String get homeLocationUnavailable => 'Set location';

  @override
  String get homeNextPrayerUnavailable =>
      'Set your location to see the next prayer.';

  @override
  String get homePrayerTimesAction => 'Prayer times';

  @override
  String get homePrayerNow => 'It is time now';

  @override
  String homePrayerInMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'In $minutes minutes',
      one: 'In 1 minute',
    );
    return '$_temp0';
  }

  @override
  String homePrayerInHoursMinutes(int hours, int minutes) {
    return 'In ${hours}h ${minutes}m';
  }

  @override
  String get homeExploreTitle => 'Discover';

  @override
  String get homeExploreSubtitle => 'Prayer times and Quran teaching';

  @override
  String get homeSessionsTitle => 'Learn Quran recitation';

  @override
  String get homeSessionsSubtitle => 'Book sessions with certified teachers';

  @override
  String get homeExploreShowAsList => 'Show as list';

  @override
  String get homeExploreShowAsGrid => 'Show as grid';

  @override
  String get homeDashboardLoadError =>
      'Could not load prayer times. Check your connection and try again.';

  @override
  String get homeSearchHint => 'Search surahs, juz, or page';

  @override
  String get homeFeaturedTitle => 'Featured for you';

  @override
  String get homeTodayTitle => 'Today';

  @override
  String get homeYoursTitle => 'Yours';

  @override
  String homeListeningResumeSubtitle(String reciter, String surah) {
    return 'Continue · $reciter · $surah';
  }

  @override
  String get homeAthkarDone => 'Done';

  @override
  String homeAthkarRemaining(int count) {
    return '$count remaining';
  }

  @override
  String get homeAthkarNotStarted => 'Not started';

  @override
  String homeQuranStreakDays(int days) {
    return 'Day $days streak';
  }

  @override
  String homeQuranGoalProgress(int percent) {
    return '$percent% of today\'s goal';
  }

  @override
  String get homeDailyAyahBookmark => 'Bookmark';

  @override
  String get homeDailyAyahShare => 'Share';

  @override
  String get homeTodaySubtitle => 'Prayer, Quran, and dhikr for your day';

  @override
  String get homeContinueTitle => 'Continue';

  @override
  String get homeDailyPracticeTitle => 'Daily Practice';

  @override
  String get homeDailyPracticeSubtitle =>
      'Your pinned adhkar and supplications';

  @override
  String get homeAthkarRitualsTitle => 'Quick athkar';

  @override
  String get homePrayerStripTitle => 'Today\'s prayer times';

  @override
  String get homePrayerStripViewAll => 'View all';

  @override
  String get homeFeaturedRitualStart => 'Tap to begin';

  @override
  String get homeStartQuranTitle => 'Open the Mushaf';

  @override
  String get homeStartQuranSubtitle => 'Begin reading the Quran today';

  @override
  String get homeContinueQuranTitle => 'Continue Quran';

  @override
  String get homeContinueQuranSubtitle => 'Resume from your last read page';

  @override
  String homeQuranResumeSurahPage(String surah, int page) {
    return '$surah · page $page';
  }

  @override
  String homeQuranResumePage(int page) {
    return 'Page $page';
  }

  @override
  String homeQuranResumeProgress(int percent) {
    return '$percent% of the Mushaf';
  }

  @override
  String homeContextualAthkarPrompt(String name) {
    return 'A good moment for $name';
  }

  @override
  String get homeAthkarNowBadge => 'Now';

  @override
  String get experimentalBadgeLabel => 'Experimental';

  @override
  String get homeQuickQuran => 'Quran';

  @override
  String get homeQuickReciters => 'Reciters';

  @override
  String get homeQuickRecitersSubtitle => 'Browse recitations';

  @override
  String get homeQuickPrayer => 'Prayer';

  @override
  String get homeQuickQibla => 'Qibla';

  @override
  String get homeQuickQiblaSubtitle => 'Find prayer direction';

  @override
  String get homeQuickSettingsSubtitle => 'Theme, audio, and account';

  @override
  String get homeQuickTasbeeh => 'Tasbeeh';

  @override
  String get homeQuickTasbeehSubtitle => 'Count dhikr with one tap';

  @override
  String get homeQuickAthkar => 'Athkar';

  @override
  String get homeQuickSettings => 'Settings';

  @override
  String get homePinnedAthkarTitle => 'Quick athkar';

  @override
  String get homePinnedAthkarEdit => 'Edit athkar shortcuts';

  @override
  String get homePinnedAthkarChoose => 'Choose athkar';

  @override
  String get homePinnedAthkarEmptyTitle => 'Choose your daily athkar';

  @override
  String get homePinnedAthkarEmptyBody =>
      'Pin up to four categories for one-tap access from Home.';

  @override
  String get homePinnedAthkarPickerTitle => 'Choose quick athkar';

  @override
  String homePinnedAthkarPickerLimit(int count, int max) {
    return '$count of $max shortcuts selected';
  }

  @override
  String homePinnedAthkarMoveUp(String name) {
    return 'Move $name up';
  }

  @override
  String homePinnedAthkarMoveDown(String name) {
    return 'Move $name down';
  }

  @override
  String get homeDailyInspirationTitle => 'Daily inspiration';

  @override
  String get homeDailyInspirationSubtitle =>
      'A verse and supplication for your day';

  @override
  String get homeDailyAyahLabel => 'Daily ayah';

  @override
  String get homeDailyAyahBody =>
      'And establish prayer and give zakah and bow with those who bow.';

  @override
  String get homeDailyAyahReference => 'Quran 2:43';

  @override
  String get homeDailyDuaLabel => 'Daily dua';

  @override
  String get homeDailyDuaBody =>
      'O Allah, help me remember You, thank You, and worship You well.';

  @override
  String get homeDailyDuaReference => 'Abu Dawud';

  @override
  String get homeDailyAyahBody1 =>
      'So remember Me; I will remember you. And be grateful to Me and do not deny Me.';

  @override
  String get homeDailyAyahReference1 => 'Quran 2:152';

  @override
  String get homeDailyDuaBody1 =>
      'Our Lord, grant us good in this world and good in the Hereafter, and protect us from the Fire.';

  @override
  String get homeDailyDuaReference1 => 'Quran 2:201';

  @override
  String get homeDailyAyahBody2 =>
      'Indeed, prayer prohibits immorality and wrongdoing.';

  @override
  String get homeDailyAyahReference2 => 'Quran 29:45';

  @override
  String get homeDailyDuaBody2 =>
      'O Allah, I ask You for beneficial knowledge, wholesome provision, and accepted deeds.';

  @override
  String get homeDailyDuaReference2 => 'Ibn Majah';

  @override
  String get khatmaEmptyTitle => 'Start a Khatma';

  @override
  String get khatmaEmptySubtitle =>
      'Choose a calm reading plan. We will adjust gently when life gets busy.';

  @override
  String khatmaDurationDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get khatmaProgressTitle => 'Khatma Progress';

  @override
  String khatmaProgressSubtitle(int currentDay, int totalDays) {
    return 'Day $currentDay of $totalDays';
  }

  @override
  String get khatmaProgressPercent => 'Progress';

  @override
  String get khatmaTodayGoal => 'Today';

  @override
  String get khatmaRemaining => 'Remaining';

  @override
  String khatmaPagesShort(int pages) {
    String _temp0 = intl.Intl.pluralLogic(
      pages,
      locale: localeName,
      other: '$pages pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String khatmaDaysShort(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get khatmaAdjustedPlan => 'We adjusted your plan gently for today.';

  @override
  String khatmaContinueFromPage(int page) {
    return 'Continue from page $page';
  }

  @override
  String get khatmaRemainingPages => 'Pages left';

  @override
  String get khatmaCatchUpAction => 'Catch up today';

  @override
  String get khatmaExtendAction => 'Extend plan';

  @override
  String get khatmaResetAction => 'Reset plan';

  @override
  String get khatmaResetTitle => 'Reset Khatma plan?';

  @override
  String get khatmaResetMessage =>
      'This clears your current Khatma plan. Your last-read Quran page and bookmarks stay saved.';

  @override
  String get khatmaContinueReading => 'Continue Reading';

  @override
  String get khatmaHubTitle => 'Smart Khatma';

  @override
  String get khatmaHomeViewPlan => 'View plan';

  @override
  String get khatmaHubResetSubtitle =>
      'Clear the current plan. Your bookmarks stay saved.';

  @override
  String get todayPlanTitle => 'Today’s Plan';

  @override
  String get todayPlanMotivationDefault =>
      'A small amount every day is easier to protect.';

  @override
  String get todayPlanMotivationComplete =>
      'Today is complete. Keep the rhythm gentle and steady.';

  @override
  String todayPlanReadPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Read $count pages',
      one: 'Read 1 page',
    );
    return '$_temp0';
  }

  @override
  String todayPlanContinueFromPage(int page) {
    return 'Continue from page $page';
  }

  @override
  String get todayPlanShortReadingSession =>
      'Start with a short reading session';

  @override
  String todayPlanListenMinutes(int minutes) {
    return 'Listen for $minutes minutes';
  }

  @override
  String get todayPlanContinueListening => 'Continue listening';

  @override
  String todayPlanListeningSubtitle(String surahName, String reciterName) {
    return '$surahName · $reciterName';
  }

  @override
  String get todayPlanChooseReciter => 'Choose a reciter and listen calmly';

  @override
  String get todayPlanMorningAdhkar => 'Morning adhkar';

  @override
  String get todayPlanMorningAdhkarSubtitle =>
      'A short remembrance before the day gets busy';

  @override
  String get todayPlanTasbeehGoal => 'Tasbeeh goal';

  @override
  String todayPlanProgress(int completed, int total, int minutes) {
    return '$completed of $total completed · $minutes min left';
  }

  @override
  String get todayPlanContinue => 'Continue';

  @override
  String todayPlanStreakDays(int days) {
    return '$days d';
  }

  @override
  String todayPlanMinutesShort(int minutes) {
    return '${minutes}m';
  }

  @override
  String get searchSurah => 'Search surah...';

  @override
  String get noRecitersFound => 'No reciters found';

  @override
  String get noRecitersMatchSearch => 'No reciters match your search';

  @override
  String a11yOpenReciterDetails(String reciterName) {
    return 'Open $reciterName';
  }

  @override
  String get a11yFavoriteRecitersOnlyFilter => 'Show favorite reciters only';

  @override
  String get recitersShowAllReciters => 'Show all reciters';

  @override
  String get a11yRecitersLetterIndex => 'Letter index';

  @override
  String get a11yRecitersAlphabetScrollbarHint =>
      'Drag up or down to jump to a letter';

  @override
  String get showRecitersLetterIndex => 'Show letter index';

  @override
  String get hideRecitersLetterIndex => 'Hide letter index';

  @override
  String get recitersMoreActions => 'More actions';

  @override
  String get recitersLetterIndexMenuItem => 'Letter index';

  @override
  String recitersResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reciters',
      one: '1 reciter',
    );
    return '$_temp0';
  }

  @override
  String get recitersFilterChipFavorites => 'Favorites';

  @override
  String recitersFilterPillFavoritesCount(int count) {
    return 'Favorites ($count)';
  }

  @override
  String get recitersFilterPillAlphabet => 'A–Z';

  @override
  String recitersFilterChipLetter(String letter) {
    return 'Starts with $letter';
  }

  @override
  String recitersFilterChipSearch(String query) {
    return '“$query”';
  }

  @override
  String get a11yClearRecitersSearch => 'Clear search text';

  @override
  String get filteredByLetter => 'Filtered by letter:';

  @override
  String get selectRecitation => 'Select Recitation';

  @override
  String get loadingSurahList => 'Loading surah list...';

  @override
  String get noSurahsAvailable => 'No surahs available';

  @override
  String get noSurahsMatchSearch => 'No surahs match your search';

  @override
  String get continueListening => 'Continue Listening';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get currentPlaying => 'Now Playing';

  @override
  String get playingFrom => 'Playing from';

  @override
  String get playerQueueExpandHint => 'Swipe up for queue';

  @override
  String get playerQueueHandleSemanticLabel =>
      'Show or hide queue. Drag up or tap to expand.';

  @override
  String get playerExpandedSheetSemanticLabel =>
      'Now playing. Swipe down to minimize.';

  @override
  String get duration => 'Duration';

  @override
  String get position => 'Position';

  @override
  String get downloads => 'Downloads';

  @override
  String get playlists => 'Playlists';

  @override
  String get noDownloadsYet => 'No downloads yet';

  @override
  String get downloading => 'Downloading';

  @override
  String get downloaded => 'Downloaded';

  @override
  String get download => 'Download';

  @override
  String get delete => 'Delete';

  @override
  String get deleteAll => 'Delete All';

  @override
  String get clearAllDownloads => 'Clear All Downloads';

  @override
  String get clearAllDownloadsMessage =>
      'Are you sure you want to delete all downloaded surahs? This action cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get stopPlayback => 'Stop playback';

  @override
  String get stopPlaybackConfirmMessage =>
      'Are you sure you want to stop playback?';

  @override
  String get playerDismissed => 'Player closed';

  @override
  String get playAll => 'Play All';

  @override
  String get pauseAll => 'Pause All';

  @override
  String get playing => 'Playing';

  @override
  String get pending => 'Pending';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get completed => 'Completed';

  @override
  String get downloadProgress => 'Download Progress';

  @override
  String get fileSize => 'File Size';

  @override
  String get downloadedSize => 'Downloaded Size';

  @override
  String get playlistsScreen => 'Playlists Screen';

  @override
  String get back => 'Back';

  @override
  String get noPlaylistsYet => 'No playlists yet';

  @override
  String get createPlaylist => 'Create Playlist';

  @override
  String get retry => 'Retry';

  @override
  String get downloadStatusChecked => 'Download status checked';

  @override
  String get fileValidationCompleted => 'File validation completed';

  @override
  String get validDownloadsLoaded => 'Valid downloads loaded';

  @override
  String get playbackInitiated => 'Playback initiated';

  @override
  String get error => 'Error';

  @override
  String get settings => 'Settings';

  @override
  String get settingsYourAccount => 'Your account';

  @override
  String get settingsViewProfile => 'View profile';

  @override
  String settingsMemberSince(String date) {
    return 'Member since $date';
  }

  @override
  String get settingsLoginSection => 'Login';

  @override
  String get settingsSupportSection => 'Support';

  @override
  String get whatsNewSettingsTile => 'What\'s new';

  @override
  String whatsNewTitle(String version) {
    return 'What\'s new in $version';
  }

  @override
  String whatsNewSemanticsLabel(String version) {
    return 'What\'s new in version $version';
  }

  @override
  String get whatsNewGotIt => 'Got it';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsPlaybackAndStorage => 'Playback & storage';

  @override
  String get settingsRecitersSection => 'Reciters';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get chooseTheme => 'Choose Theme';

  @override
  String get bottomNavHome => 'Home';

  @override
  String get bottomNavReciters => 'Reciters';

  @override
  String get bottomNavSearch => 'Search';

  @override
  String get a11yBottomNavRecitersTab => 'Go to reciters';

  @override
  String get a11yBottomNavRecitersSearch => 'Search reciters';

  @override
  String recitersSearchResultsFor(String query) {
    return 'Results for “$query”';
  }

  @override
  String noRecitersForQuery(String query) {
    return 'No results for “$query”';
  }

  @override
  String get recitersClearSearch => 'Clear search';

  @override
  String get bottomNavPrayer => 'Prayer';

  @override
  String get bottomNavQibla => 'Qibla';

  @override
  String get bottomNavQuran => 'Quran';

  @override
  String get bottomNavAthkar => 'Dhikr';

  @override
  String get bottomNavSettings => 'Settings';

  @override
  String get audioSettings => 'Audio';

  @override
  String get retryDownload => 'Retry Download';

  @override
  String get retryDownloadTooltip => 'Retry Download';

  @override
  String get viewDownloads => 'View Downloads';

  @override
  String get premium => 'Premium';

  @override
  String get premiumFeatures => 'Premium Features';

  @override
  String get unlimitedDownloads => 'Unlimited Downloads';

  @override
  String get offlineMode => 'Offline Mode';

  @override
  String get highQualityAudio => 'High Quality Audio';

  @override
  String get adFreeExperience => 'Ad-Free Experience';

  @override
  String get prioritySupport => 'Priority Support';

  @override
  String get exclusiveContent => 'Exclusive Content';

  @override
  String get chooseYourPlan => 'Choose Your Plan';

  @override
  String get maybeLater => 'Maybe Later';

  @override
  String get upgradeNow => 'Upgrade Now';

  @override
  String get playlistName => 'Playlist Name';

  @override
  String get playlistDescription => 'Playlist Description';

  @override
  String get playlistNameHint => 'Enter playlist name';

  @override
  String get playlistDescriptionHint => 'Enter playlist description';

  @override
  String get createNewPlaylist => 'Create New Playlist';

  @override
  String get editPlaylist => 'Edit Playlist';

  @override
  String get save => 'Save';

  @override
  String get playlistCreated => 'Playlist created successfully';

  @override
  String get playlistUpdated => 'Playlist updated successfully';

  @override
  String get playlistDeleted => 'Playlist deleted successfully';

  @override
  String get deletePlaylist => 'Delete Playlist';

  @override
  String get deletePlaylistMessage =>
      'Are you sure you want to delete this playlist? This action cannot be undone.';

  @override
  String get addToPlaylist => 'Add to Playlist';

  @override
  String get removeFromPlaylist => 'Remove from Playlist';

  @override
  String get playlistItems => 'Playlist Items';

  @override
  String get playlistDuration => 'Duration';

  @override
  String get playlistItemCount => 'Items';

  @override
  String get searchPlaylists => 'Search Playlists';

  @override
  String get favorites => 'Favorites';

  @override
  String get clearFavorites => 'Clear Favorites';

  @override
  String get clearFavoritesConfirmation =>
      'Are you sure you want to remove all reciters from favorites?';

  @override
  String get noFavorites => 'No favorites';

  @override
  String get recent => 'Recent';

  @override
  String get public => 'Public';

  @override
  String get private => 'Private';

  @override
  String get makePublic => 'Make Public';

  @override
  String get makePrivate => 'Make Private';

  @override
  String get duplicatePlaylist => 'Duplicate Playlist';

  @override
  String get duplicatePlaylistName => 'Duplicate Playlist Name';

  @override
  String get enterDuplicateName => 'Enter name for duplicate playlist';

  @override
  String get playlistNameExists => 'A playlist with this name already exists';

  @override
  String get playlistNameRequired => 'Playlist name is required';

  @override
  String get playlistDescriptionRequired => 'Playlist description is required';

  @override
  String get playlistNotFound => 'Playlist not found';

  @override
  String get itemAlreadyInPlaylist => 'Item is already in this playlist';

  @override
  String get playlistEmpty => 'This playlist is empty';

  @override
  String get playPlaylist => 'Play Playlist';

  @override
  String get shufflePlaylist => 'Shuffle Playlist';

  @override
  String get playlistStats => 'Playlist Statistics';

  @override
  String get totalDuration => 'Total Duration';

  @override
  String get totalItems => 'Total Items';

  @override
  String get createdOn => 'Created On';

  @override
  String get lastUpdated => 'Last Updated';

  @override
  String get continueButton => 'Continue';

  @override
  String get premiumRequired => 'Premium Required';

  @override
  String get premiumRequiredMessage =>
      'This feature requires a premium subscription. Upgrade to unlock unlimited downloads and more!';

  @override
  String get language => 'Language';

  @override
  String get arabic => 'Arabic';

  @override
  String get english => 'English';

  @override
  String get refreshDownloads => 'Refresh Downloads';

  @override
  String downloadingSurahByReciter(String surahTitle, String reciterName) {
    return 'Downloading $surahTitle by $reciterName...';
  }

  @override
  String get deleteDownload => 'Delete Download';

  @override
  String deleteDownloadConfirmation(String title) {
    return 'Are you sure you want to delete \"$title\"?';
  }

  @override
  String deleteAllDownloadsConfirmation(String reciterName) {
    return 'Are you sure you want to delete all downloads for $reciterName?';
  }

  @override
  String get surahs => 'Surahs';

  @override
  String get signIn => 'Sign in';

  @override
  String get welcomeToApp => 'Welcome to Tilawa';

  @override
  String get signInWithGoogleDescription =>
      'Sign in with your Google account to continue';

  @override
  String get signingIn => 'Signing in...';

  @override
  String get continueWithGoogle => 'Sign in with Google';

  @override
  String get googleSignInNotConfigured =>
      'Google Sign-In not configured. Please contact support.';

  @override
  String get unableToSignInWithThirdPartyAccount =>
      'Unable to sign in with third-party account';

  @override
  String get googleSignInNoAccountsOnDevice =>
      'No Google account found on this device. Please add a Google account in your device settings and try again.';

  @override
  String get googleSignInFallbackTitle => 'Google sign-in could not open';

  @override
  String get googleSignInFallbackBody =>
      'The Google account picker may be hidden on this device. Update Google Play Services, then try again. If it still fails, ask your developer to register this build\'s SHA-1 in Firebase.';

  @override
  String get googleSignInUpdatePlayServices => 'Update Google Play Services';

  @override
  String get networkError => 'Please check your internet connection';

  @override
  String get downloadLowStorageWarning =>
      'Available storage may not be enough for this download. Free up space if downloads fail.';

  @override
  String get downloadLowStorageBlocked =>
      'Not enough storage space to download all surahs. Free up space and try again.';

  @override
  String recitationsAvailable(int count) {
    return '$count recitation(s) available';
  }

  @override
  String reciterAdditionalMoshafCount(int count) {
    return ' · $count more';
  }

  @override
  String loadingReciterSurahs(String reciterName) {
    return 'Loading $reciterName surahs...';
  }

  @override
  String get addToFavorites => 'Add to Favorites';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get createFirstPlaylistMessage =>
      'Create your first playlist to organize your favorite surahs';

  @override
  String get addedToFavorites => 'Added to favorites';

  @override
  String get removedFromFavorites => 'Removed from favorites';

  @override
  String get editPlaylistComingSoon =>
      'Edit playlist functionality coming soon';

  @override
  String get playlistDetailsComingSoon => 'Playlist details screen coming soon';

  @override
  String get playPlaylistComingSoon =>
      'Play playlist functionality coming soon';

  @override
  String get downloadSurahsOffline => 'Download surahs to listen offline';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String build(String build) {
    return 'Build $build';
  }

  @override
  String get notificationWaitingToStart => 'Waiting to start...';

  @override
  String notificationDownloadingProgress(int progress) {
    return 'Downloading: $progress%';
  }

  @override
  String get notificationDownloadComplete => 'Download complete';

  @override
  String get notificationDownloadFailed => 'Download failed';

  @override
  String notificationBatchDownloadingTitle(int count) {
    return 'Downloading $count files';
  }

  @override
  String notificationBatchProgress(int completed, int total, int progress) {
    return 'Progress: $completed/$total ($progress%)';
  }

  @override
  String notificationBatchComplete(int count) {
    return 'All $count files downloaded successfully';
  }

  @override
  String get notificationBatchFailed => 'Batch download failed';

  @override
  String get resume => 'Resume';

  @override
  String get appearance => 'Appearance';

  @override
  String get primaryColor => 'Primary Color';

  @override
  String get choosePrimaryColor => 'Choose Primary Color';

  @override
  String get colorCoral => 'Coral';

  @override
  String get colorCyan => 'Cyan';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorBrown => 'Brown';

  @override
  String get colorInk => 'Charcoal';

  @override
  String get colorPurple => 'Purple';

  @override
  String get colorGold => 'Gold';

  @override
  String get theme => 'Theme';

  @override
  String get systemTheme => 'System Default';

  @override
  String get lightTheme => 'Light Mode';

  @override
  String get darkTheme => 'Dark Mode';

  @override
  String get chooseLanguage => 'Choose Language';

  @override
  String get manageStorage => 'Manage Storage';

  @override
  String get manageStorageSubtitle => 'View and manage downloaded content';

  @override
  String get concurrentDownloads => 'Concurrent Downloads';

  @override
  String concurrentDownloadsSubtitle(int count) {
    return '$count downloads at once';
  }

  @override
  String get guestUser => 'Guest User';

  @override
  String get signInToSync => 'Sign in to sync your data';

  @override
  String get logoutConfirmation => 'Are you sure you want to logout?';

  @override
  String get logout => 'Logout';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountConfirmation =>
      'This permanently deletes your Tilawa account and synced profile data. Purchases verified with Google Play may be kept in anonymized records for fraud prevention. This cannot be undone.';

  @override
  String get deleteAccountFailed =>
      'Unable to delete your account. Please try again.';

  @override
  String get deleteAccountInProgress => 'Deleting your account...';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get requestAccountDeletionWeb => 'Request account deletion on the web';

  @override
  String get settingsLegalSection => 'Legal';

  @override
  String storageUsed(String size) {
    return 'Storage Used: $size';
  }

  @override
  String get serverError => 'Server error, please try again later';

  @override
  String get cacheError => 'Storage error';

  @override
  String get audioError => 'Audio playback error';

  @override
  String get validationError => 'Invalid data provided';

  @override
  String get permissionError => 'Permission denied';

  @override
  String get unexpectedError => 'An unexpected error occurred';

  @override
  String get persistenceError => 'Failed to save data';

  @override
  String get uiError => 'User interface error';

  @override
  String get unknownError => 'Unknown error occurred';

  @override
  String get startFreeTrial => 'Start Free Trial';

  @override
  String get goHome => 'Go Home';

  @override
  String pageNotFound(String uri) {
    return 'Page not found: $uri';
  }

  @override
  String daysRemaining(int days) {
    return '$days days remaining';
  }

  @override
  String get premiumAccessMessage => 'You have access to all premium features!';

  @override
  String get upgradeMessage => 'Upgrade to unlock premium features';

  @override
  String get freeTrialTitle => '7-Day Free Trial';

  @override
  String get freeTrialDescription =>
      'Try all premium features for 7 days, completely free!';

  @override
  String get anErrorOccurred => 'An error occurred';

  @override
  String get qiblaAligned => 'You are facing Qibla';

  @override
  String get reciterInfoNotAvailable => 'Reciter information not available';

  @override
  String errorLoadingReciter(String error) {
    return 'Error loading reciter: $error';
  }

  @override
  String downloadingSurah(String surahTitle) {
    return 'Downloading $surahTitle';
  }

  @override
  String get home => 'Home';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get homeLayout => 'Home Layout';

  @override
  String get recitersList => 'Reciters List';

  @override
  String get chooseHomeLayout => 'Choose Home Layout';

  @override
  String get restorePlaybackState => 'Restore Last Playback';

  @override
  String get restorePlaybackStateSubtitle =>
      'Resume audio from where you left off';

  @override
  String get showRecitersAlphabetIndex => 'Show Alphabet Index';

  @override
  String get showRecitersAlphabetIndexSubtitle =>
      'Display the A-Z shortcut rail while browsing reciters';

  @override
  String get timeRemaining => 'Time Remaining';

  @override
  String reciterRemovedFromFavorites(String reciterName) {
    return 'Removed $reciterName from favorites';
  }

  @override
  String get allDownloaded => 'All Downloaded';

  @override
  String get undo => 'Undo';

  @override
  String get athkar => 'Athkar';

  @override
  String get tasbeehCategory => 'Tasbeeh';

  @override
  String get tasbeehInputLabel => 'Dhikr';

  @override
  String get tasbeehInputHint => 'Write your dhikr, e.g. Subhan Allah';

  @override
  String get tasbeehSave => 'Save';

  @override
  String get tasbeehTapToCount => 'Tap anywhere to increment';

  @override
  String get tasbeehTargetLabel => 'Target';

  @override
  String get tasbeehTargetHint => 'e.g. 33';

  @override
  String get tasbeehSetTarget => 'Set target';

  @override
  String get tasbeehAddNewOptionTitle => 'Add new Tasbeeh';

  @override
  String get tasbeehAddNewOptionSubtitle =>
      'Create your dhikr and target, then start counting';

  @override
  String get tasbeehViewHistoryOptionTitle => 'View saved Tasbeeh';

  @override
  String get tasbeehViewHistoryOptionSubtitle =>
      'Choose one from your history and continue counting';

  @override
  String get tasbeehGoToCounting => 'Start counting';

  @override
  String get tasbeehBackToOptions => 'Back to options';

  @override
  String get tasbeehChooseSavedDhikr => 'Choose saved Tasbeeh';

  @override
  String get tasbeehHistoryEmpty => 'No saved Tasbeeh yet';

  @override
  String tasbeehDeleteConfirmationMessage(String tasbeehText) {
    return 'Delete \"$tasbeehText\" from your saved Tasbeeh history?';
  }

  @override
  String get tasbeehRemoveItem => 'Remove';

  @override
  String tasbeehCurrentTarget(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Current target: $countString';
  }

  @override
  String get tasbeehSelectOrCreatePrompt =>
      'Select or create a dhikr to start counting';

  @override
  String get tasbeehQuickCountTitle => 'Quick count';

  @override
  String get tasbeehQuickCountSubtitle => 'Count without saving — tap to begin';

  @override
  String tasbeehProgressLabel(int current, int target) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat targetNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String targetString = targetNumberFormat.format(target);

    return '$currentString / $targetString';
  }

  @override
  String get tasbeehShowAsList => 'Show as list';

  @override
  String get tasbeehShowAsGrid => 'Show as grid';

  @override
  String get tasbeehClearAllTitle => 'Clear all saved Tasbeeh?';

  @override
  String tasbeehClearAllMessage(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'This removes all $countString saved dhikr and their reminders. This cannot be undone.';
  }

  @override
  String get tasbeehReminderSheetTitle => 'Daily reminder';

  @override
  String get tasbeehReminderEnabledLabel => 'Daily reminder';

  @override
  String get tasbeehReminderEnabledSubtitle =>
      'Get a local notification at your chosen time';

  @override
  String tasbeehReminderPickTime(String time) {
    return 'Reminder time: $time';
  }

  @override
  String get tasbeehReminderAction => 'Reminder';

  @override
  String get tasbeehReminderNotificationBody => 'Time for your dhikr';

  @override
  String get done => 'Done';

  @override
  String get fileSizeUnitB => 'B';

  @override
  String get fileSizeUnitKB => 'KB';

  @override
  String get fileSizeUnitMB => 'MB';

  @override
  String get fileSizeUnitGB => 'GB';

  @override
  String get fileSizeUnitTB => 'TB';

  @override
  String get reset => 'Reset';

  @override
  String get athkarResetConfirmationMessage =>
      'Reset the count for this dhikr? Your progress on it will be cleared.';

  @override
  String get qibla => 'Qibla';

  @override
  String get qiblaDirection => 'Qibla Direction';

  @override
  String get qiblaFinderTitle => 'QIBLA FINDER';

  @override
  String get qiblaDeviceAngleLabel => 'Device\'s angle to qibla';

  @override
  String qiblaRotatePhoneLeft(int degrees) {
    return 'Rotate the phone $degrees° to the left';
  }

  @override
  String qiblaRotatePhoneRight(int degrees) {
    return 'Rotate the phone $degrees° to the right';
  }

  @override
  String get locationServiceDisabled => 'Location Service Disabled';

  @override
  String get enableLocationServiceMessage =>
      'Please enable location services to find Qibla direction.';

  @override
  String get permissionDenied => 'Permission Denied';

  @override
  String get locationPermissionRequiredMessage =>
      'Location permission is required to calculate the Qibla direction.';

  @override
  String get downloadAll => 'Download All';

  @override
  String downloadAllWithCount(int downloaded, int total) {
    final intl.NumberFormat downloadedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String downloadedString = downloadedNumberFormat.format(downloaded);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Download All ($downloadedString/$totalString)';
  }

  @override
  String get downloadingAllSurahs => 'Downloading all surahs...';

  @override
  String completeDownloadingWithCount(int downloaded, int total) {
    final intl.NumberFormat downloadedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String downloadedString = downloadedNumberFormat.format(downloaded);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Complete Downloading ($downloadedString/$totalString)';
  }

  @override
  String pauseProgressWithCount(int percent, int downloaded, int total) {
    final intl.NumberFormat percentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String percentString = percentNumberFormat.format(percent);
    final intl.NumberFormat downloadedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String downloadedString = downloadedNumberFormat.format(downloaded);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Pause $percentString% ($downloadedString/$totalString)';
  }

  @override
  String get completeDownloading => 'Complete Downloading';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get unableToFindQibla => 'Unable to find Qibla';

  @override
  String get qiblaCompassTip =>
      'Make sure the arrow moves when you rotate your device';

  @override
  String get qiblaCompassAccuracyPoor =>
      'Compass accuracy is low. Move your phone in a figure-eight motion to calibrate it.';

  @override
  String get onboardingTitle1 =>
      'Minutes with the Quran…\nChanges your whole day';

  @override
  String get onboardingDesc1 =>
      'Find verses that fit what you\'re going through, and take quiet minutes to read or listen.';

  @override
  String get onboardingTitle2 => 'Many reciter voices\nListen your way';

  @override
  String get onboardingDesc2 =>
      'Different reciters and riwayat — choose the voice and style that feels right.';

  @override
  String get onboardingTitle3 =>
      'Every verse and dhikr\nOngoing charity for Abu Hudhayfah';

  @override
  String get onboardingDesc3 =>
      'Every Qur\'an listen and every dhikr you repeat is ongoing charity for our brother Abu Hudhayfah Ahmad Mahmud Toni — may God have mercy on him and forgive him.';

  @override
  String onboardingPageSemantics(int current, int total) {
    return 'Screen $current of $total';
  }

  @override
  String get onboardingVisualHint2 =>
      'Browse reciters with search and favorites';

  @override
  String get startJourney => 'Get started';

  @override
  String get recitationDuration => 'Recitation Duration';

  @override
  String get chooseBackgroundSource => 'Choose Background Source';

  @override
  String get gallery => 'Gallery';

  @override
  String get camera => 'Camera';

  @override
  String get resetToDefault => 'Reset to Default';

  @override
  String get adjustVolume => 'Adjust volume';

  @override
  String get playbackSpeed => 'Playback speed';

  @override
  String get unknownReciter => 'Unknown Reciter';

  @override
  String get minutes15 => '15 Minutes';

  @override
  String get minutes30 => '30 Minutes';

  @override
  String get minutes60 => '60 Minutes';

  @override
  String get cancelTimer => 'Cancel Timer';

  @override
  String get custom => 'Custom';

  @override
  String get hourLabel => 'Hour';

  @override
  String get minuteLabel => 'Minute';

  @override
  String get enableRecitationDuration => 'Recitation Duration';

  @override
  String get enableRecitationDurationSubtitle =>
      'Show and enable recitation duration control feature';

  @override
  String get sleepTimerActive => 'Active';

  @override
  String get endOfTrack => 'End of Track';

  @override
  String get setTimer => 'Set Timer';

  @override
  String get noInternetConnection => 'No Internet Connection';

  @override
  String get offlinePlaybackError =>
      'This content is not available offline. Please download it first.';

  @override
  String get offlineFileMissingError =>
      'Downloaded file is missing. Please re-download this content.';

  @override
  String get offlineDownloadIncompleteError =>
      'This content is not fully downloaded. Please complete the download first.';

  @override
  String get bookmarks => 'Bookmarks';

  @override
  String get addBookmark => 'Add Bookmark';

  @override
  String get deleteBookmark => 'Delete Bookmark';

  @override
  String get editBookmark => 'Edit Bookmark';

  @override
  String get searchBookmarks => 'Search bookmarks...';

  @override
  String get noBookmarksYet => 'No Bookmarks Yet';

  @override
  String get noBookmarksDescription =>
      'Save your favorite moments while listening to the Quran';

  @override
  String get bookmarkAdded => 'Bookmark added';

  @override
  String get bookmarkDeleted => 'Bookmark deleted';

  @override
  String get bookmarkLabel => 'Label (optional)';

  @override
  String get deleteBookmarkConfirmation =>
      'Are you sure you want to delete this bookmark?';

  @override
  String get listeningHistory => 'Listening History';

  @override
  String get noHistoryYet => 'No History Yet';

  @override
  String get noHistoryDescription => 'Your listening history will appear here';

  @override
  String get clearHistory => 'Clear History';

  @override
  String get clearHistoryConfirmation =>
      'Are you sure you want to clear all listening history?';

  @override
  String get historyDeleted => 'History deleted';

  @override
  String get totalSurahs => 'Total Surahs';

  @override
  String get totalListeningTime => 'Total Time';

  @override
  String get searchHistory => 'Search history...';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String playedTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Played $count times',
      one: 'Played 1 time',
    );
    return '$_temp0';
  }

  @override
  String get prayerTimes => 'Prayer Times';

  @override
  String get prayerSettings => 'Prayer Settings';

  @override
  String get fajr => 'Fajr';

  @override
  String get sunrise => 'Sunrise';

  @override
  String get dhuhr => 'Dhuhr';

  @override
  String get asr => 'Asr';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get isha => 'Isha';

  @override
  String get midnight => 'Midnight';

  @override
  String get lastThird => 'Last Third';

  @override
  String get nextPrayer => 'Next Prayer';

  @override
  String get calculationMethod => 'Calculation Method';

  @override
  String get calculationMethodMuslimWorldLeague => 'Muslim World League';

  @override
  String get calculationMethodEgyptian => 'Egyptian General Authority';

  @override
  String get calculationMethodKarachi => 'University of Karachi';

  @override
  String get calculationMethodUmmAlQura => 'Umm Al-Qura, Makkah';

  @override
  String get calculationMethodIsna => 'ISNA (North America)';

  @override
  String get calculationMethodTehran => 'Tehran';

  @override
  String get calculationMethodGulf => 'Gulf Region';

  @override
  String get calculationMethodKuwait => 'Kuwait';

  @override
  String get calculationMethodQatar => 'Qatar';

  @override
  String get calculationMethodSingapore => 'Singapore (MUIS)';

  @override
  String get calculationMethodTurkey => 'Turkey (Diyanet)';

  @override
  String get asrCalculation => 'Asr Calculation';

  @override
  String get asrCalculationShafii => 'Shafi\'i, Maliki, Hanbali';

  @override
  String get asrCalculationHanafi => 'Hanafi';

  @override
  String get displayOptions => 'Display Options';

  @override
  String get use24HourFormat => 'Use 24-hour format';

  @override
  String get showSunrise => 'Show Sunrise';

  @override
  String get showPrayerTimesAlertChipLabels => 'Show alert chip labels';

  @override
  String get locationRequired => 'Location Required';

  @override
  String get locationRequiredDescription =>
      'Prayer times require your location to calculate accurately';

  @override
  String get enableLocation => 'Enable Location';

  @override
  String get updateLocation => 'Update Location';

  @override
  String get currentLocation => 'Current Location';

  @override
  String get prayerTimesTodaySchedule => 'Today\'s schedule';

  @override
  String get prayerTimesTodayScheduleSubtitle =>
      'Prayer times and nightly markers';

  @override
  String get prayerTimesRefreshingLocation => 'Refreshing location...';

  @override
  String get prayerTimesLoading => 'Loading prayer times...';

  @override
  String get prayerTimesTapToRefreshLocation => 'Tap to refresh location';

  @override
  String prayerTimesTimeRemainingUntil(String prayerName) {
    return 'Time remaining until $prayerName';
  }

  @override
  String get prayerTimesTimeRemainingCaption => 'Time remaining';

  @override
  String get prayerTimesScheduled => 'Scheduled';

  @override
  String get prayerTimesUpcoming => 'Upcoming';

  @override
  String get prayerTimesPassed => 'Passed';

  @override
  String prayerTimesIqamahAt(String time) {
    return 'Iqamah: $time';
  }

  @override
  String prayerTimesIshraqAt(String time) {
    return 'Ishraq: $time';
  }

  @override
  String get prayerTimesNightMidpointMarker => 'Night midpoint marker';

  @override
  String get prayerTimesLastThirdBegins => 'Last third begins';

  @override
  String get hours => 'hours';

  @override
  String get minutes => 'minutes';

  @override
  String get minutesShort => 'min';

  @override
  String get seconds => 'seconds';

  @override
  String get at => 'at';

  @override
  String get monthly => 'Monthly';

  @override
  String get notifications => 'Notifications';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String minutesBefore(int count) {
    return '$count minutes before';
  }

  @override
  String get readerSettings => 'Reader Settings';

  @override
  String get fontSize => 'Font Size';

  @override
  String get lineHeight => 'Line Height';

  @override
  String get fontType => 'Font Type';

  @override
  String get showTranslation => 'Show Translation';

  @override
  String quranTranslationAttribution(
    String translationName,
    String sourceName,
  ) {
    return 'Translation: $translationName ($sourceName)';
  }

  @override
  String get showAyahNumbers => 'Show Ayah Numbers';

  @override
  String get showTransliteration => 'Show Transliteration';

  @override
  String get ayah => 'Ayah';

  @override
  String get ayahs => 'Ayahs';

  @override
  String get surahNotFound => 'Surah not found';

  @override
  String get playAyah => 'Play Ayah';

  @override
  String get copyAyah => 'Copy Ayah';

  @override
  String get shareAyah => 'Share Ayah';

  @override
  String get searchAyahs => 'Search Ayahs';

  @override
  String get searchAyahsHint => 'Enter Arabic text to search...';

  @override
  String get enterSearchQuery => 'Enter a search query';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get close => 'Close';

  @override
  String get continueReading => 'Continue Reading';

  @override
  String get lastRead => 'Last Read';

  @override
  String get goToAyah => 'Go to Ayah';

  @override
  String get juz => 'Juz';

  @override
  String get page => 'Page';

  @override
  String get verses => 'Verses';

  @override
  String get meccan => 'Meccan';

  @override
  String get medinan => 'Medinan';

  @override
  String get bookmarkUpdated => 'Bookmark updated';

  @override
  String get noBookmarksFound => 'No bookmarks found';

  @override
  String get noBookmarks => 'No bookmarks';

  @override
  String get tryDifferentSearch => 'Try a different search term';

  @override
  String get noBookmarksHint =>
      'Bookmark your favorite moments while listening';

  @override
  String get editBookmarkLabel => 'Edit Bookmark Label';

  @override
  String get enterBookmarkLabel => 'Enter bookmark label';

  @override
  String get noSearchResults => 'No search results';

  @override
  String get clearAll => 'Clear All';

  @override
  String get timeAdjustments => 'Time Adjustments';

  @override
  String get day => 'Day';

  @override
  String get features => 'Features';

  @override
  String get quranReader => 'Mushaf';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get errorPlayingAudio => 'Error playing audio';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get seeAll => 'See All';

  @override
  String get welcomeBack => 'Welcome Back!';

  @override
  String get continueSpiritualJourney => 'Continue your spiritual journey.';

  @override
  String get recentlyPlayed => 'Recently Played';

  @override
  String get quickAccess => 'Quick Access';

  @override
  String get dashboardLastRead => 'Last Read';

  @override
  String get dashboardQuran => 'Quran';

  @override
  String get dashboardDuas => 'Duas';

  @override
  String get hifz => 'Hifz';

  @override
  String get apps => 'Apps';

  @override
  String get donation => 'Donation';

  @override
  String get todaysActivities => 'Today\'s Activities';

  @override
  String get dailyActivitiesSubtitle =>
      'Complete the daily activity checklist.';

  @override
  String tasksProgress(int completed, int total) {
    return '$completed of $total Tasks';
  }

  @override
  String get goToChecklist => 'Go to Checklist';

  @override
  String prayerAwayFrom(String prayer, String time) {
    return '$time remaining until $prayer';
  }

  @override
  String get quran => 'Quran';

  @override
  String get quranHubTitle => 'QURAN';

  @override
  String get quranCatalogSectionTitle => 'Al Quran';

  @override
  String get quranOpenMushaf => 'Open Mushaf';

  @override
  String get quranSwitchToAyahList => 'Ayah list view';

  @override
  String get quranSwitchToMushaf => 'Mushaf view';

  @override
  String get continueReadingQuran => 'Continue Reading Quran';

  @override
  String get surahIndex => 'Surah Index';

  @override
  String get hijriCalendarTitle => 'Islamic calendar';

  @override
  String get hijriCalendarOpenLabel => 'Open Islamic calendar';

  @override
  String get hijriCalendarPreviousMonth => 'Previous month';

  @override
  String get hijriCalendarNextMonth => 'Next month';

  @override
  String surahCountLabel(int count) {
    return '$count Surahs';
  }

  @override
  String get noSurahsFound => 'No surahs found';

  @override
  String surahProgress(int current, int total) {
    return 'Surah $current / $total';
  }

  @override
  String surahAyahLabel(int surah, int ayah) {
    return 'Surah $surah, Ayah $ayah';
  }

  @override
  String ayahCountWithPlace(int count, String place) {
    return '$count Ayahs · $place';
  }

  @override
  String get sajda => 'Sajda';

  @override
  String get surahPrefix => 'Surah';

  @override
  String ayahCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ayahs',
      one: '1 Ayah',
    );
    return '$_temp0';
  }

  @override
  String get juzPart => 'Part';

  @override
  String get hizb => 'Hizb';

  @override
  String get preparingFonts => 'Preparing High-Quality Quran Fonts...';

  @override
  String get loadingQuran => 'Loading Quran...';

  @override
  String get fontsDownloadDescription =>
      'This is a one-time download (~50MB) for the best reading experience.';

  @override
  String get fontsFailedToLoad => 'Failed to load fonts';

  @override
  String get share => 'Share';

  @override
  String get shareScreenshot => 'Share Screenshot';

  @override
  String get shareAudioClip => 'Share Audio Clip';

  @override
  String get shareAsText => 'Share as Text';

  @override
  String get shareVerseAudioClip => 'Share Verse Audio';

  @override
  String get fromAyah => 'From Ayah';

  @override
  String get toAyah => 'To Ayah';

  @override
  String get generateAndShare => 'Generate & Share';

  @override
  String maxVersesExceeded(int count) {
    return 'Maximum $count verses per clip.';
  }

  @override
  String get shareInvalidRangeOrder =>
      'First ayah must be before or equal to the last.';

  @override
  String get shareInvalidRangeBounds => 'Selected range is outside this surah.';

  @override
  String get sharing => 'Sharing...';

  @override
  String get sharedViaTilawa => 'Shared via Tilawa';

  @override
  String get reciterNotAvailable =>
      'Verse audio not available for this reciter. Using default reciter.';

  @override
  String get shareAudio => 'Share Audio Clip';

  @override
  String get generateReel => 'Generate Reel (Video)';

  @override
  String get reviewReel => 'Review Reel';

  @override
  String get shareReel => 'Share Reel';

  @override
  String get shareSheetSubtitle =>
      'Choose a format that carries these verses beautifully.';

  @override
  String get selectSurahToShare => 'Select Surah to share';

  @override
  String get shareScreenshotDescription =>
      'A clean Quran page capture ready to send.';

  @override
  String get shareAudioClipDescription =>
      'Create a recitation clip or reel with audio.';

  @override
  String get audioClipConfigSubtitle =>
      'Select a verse range and generate audio or a vertical reel.';

  @override
  String shareVerseLimit(int count) {
    return 'Up to $count verses per clip.';
  }

  @override
  String get liveReelPreview => 'Live Reel Preview';

  @override
  String get createShare => 'Create Share';

  @override
  String get shareComposerSubtitle =>
      'Build a polished Quran share with live preview and simple controls.';

  @override
  String get shareReadyTitle => 'Ready to Share';

  @override
  String get shareReviewSubtitle =>
      'Review the final result, then share it when it feels right.';

  @override
  String get readyToShare => 'Ready to Share';

  @override
  String get shareMode => 'Share Format';

  @override
  String get shareModeScreenshot => 'Screenshot';

  @override
  String get shareModeAudio => 'Audio';

  @override
  String get shareModeReel => 'Reel';

  @override
  String get shareStepConfigure => 'Configure';

  @override
  String get shareStepGenerating => 'Generating';

  @override
  String get shareStepReview => 'Review';

  @override
  String get shareContentLayout => 'Visual Layout';

  @override
  String get shareLayoutReaderPage => 'Reader Page';

  @override
  String get shareLayoutPassageCard => 'Passage Card';

  @override
  String get shareReaderPageHint =>
      'Reader Page uses the current Quran page exactly as shown in the reader.';

  @override
  String get shareDuration => 'Clip Duration';

  @override
  String get shareDurationAuto => 'Full Range';

  @override
  String get shareDurationShort => '30 sec';

  @override
  String get shareDurationMedium => '60 sec';

  @override
  String get shareDurationLong => '90 sec';

  @override
  String get shareDurationHint =>
      'Duration presets keep the full-ayah flow when timing data is available.';

  @override
  String get prepareScreenshot => 'Prepare Screenshot';

  @override
  String get prepareAudioClip => 'Prepare Audio Clip';

  @override
  String get prepareReel => 'Prepare Reel';

  @override
  String get preparingScreenshot => 'Preparing screenshot...';

  @override
  String get preparingAudioClip => 'Preparing audio clip...';

  @override
  String get preparingReelStatus => 'Preparing reel...';

  @override
  String get generatingAudioClipStatus => 'Generating audio clip...';

  @override
  String get capturingReaderVisuals => 'Capturing reader visuals...';

  @override
  String get combiningReelMedia => 'Combining visuals and audio into a reel...';

  @override
  String get preparingToTrimLocalAudio => 'Preparing to trim local audio...';

  @override
  String get reciterNotSupportedForLocalTrim =>
      'Reciter not supported for local trimming. Falling back to online download...';

  @override
  String get fetchingAyahTimings => 'Fetching ayah timings...';

  @override
  String get noTimingsFound =>
      'No timings found. Falling back to online download...';

  @override
  String get noTimingsFoundForRange =>
      'No timings found for the selected range. Falling back to online download...';

  @override
  String get trimmingAudio => 'Trimming audio...';

  @override
  String get generatedAudioFileNotFound =>
      'Generated audio file was not found.';

  @override
  String get generatedReelFileNotFound => 'Generated reel file was not found.';

  @override
  String downloadingVerseProgress(int currentVerse, int totalVerses) {
    return 'Downloading verse $currentVerse of $totalVerses...';
  }

  @override
  String get assemblingAudioClip => 'Assembling audio clip...';

  @override
  String get preparingVideoEncoding => 'Preparing video encoding...';

  @override
  String get encodingVerticalVideo =>
      'Encoding vertical video (this may take a moment)...';

  @override
  String get reelGenerationFailed =>
      'Failed to generate reel video. Please try again.';

  @override
  String get reelGenerationFailedInvalidFrame =>
      'Failed to process captured frame data for reel generation. Please retry.';

  @override
  String get reelGenerationFailedMissingScreenshot =>
      'No captured frame was found for reel generation.';

  @override
  String get reelGenerationFailedInvalidOutput =>
      'Generated reel output is invalid and could not be opened. Please try again.';

  @override
  String get reelPreviewLoadFailed => 'Unable to load generated video preview.';

  @override
  String get reelGenerated => 'Reel generated!';

  @override
  String get shareReviewTitle => 'Review Your Share';

  @override
  String get shareReviewScreenshot => 'Screenshot is ready to share.';

  @override
  String get shareReviewAudio => 'Audio clip is ready to share.';

  @override
  String get shareReviewReel => 'Reel is ready to share.';

  @override
  String shareDurationPresetLabel(int seconds) {
    return '$seconds sec max';
  }

  @override
  String get edit => 'Edit';

  @override
  String get prayerNotifications => 'Prayer Notifications';

  @override
  String get manageAlerts => 'Manage Alerts';

  @override
  String get prayerNotificationsEnabledAll => 'All Prayer Notifications';

  @override
  String get playAdhan => 'Play Adhan';

  @override
  String get atPrayerTime => 'At prayer time';

  @override
  String get exactAlarmPermissionRequired =>
      'Exact alarm permission required for reliable prayer reminders.';

  @override
  String get notificationPermissionRequired =>
      'Notification permission required to receive prayer alerts.';

  @override
  String get batteryOptimizationExemptionRequired =>
      'Disable battery optimization to keep prayer reminders on time when the screen is off.';

  @override
  String get oemAutostartHint =>
      'On this device, also enable Autostart for Tilawa in your phone\'s settings so reminders are not stopped in the background.';

  @override
  String get prayerAlertsPermissionLocationTitle => 'Location';

  @override
  String get prayerAlertsPermissionLocationBody =>
      'Allow location access so prayer times are calculated for where you are. Times update automatically when you travel.';

  @override
  String get prayerAlertsPermissionNotificationsTitle => 'Allow notifications';

  @override
  String get prayerAlertsPermissionNotificationsBody =>
      'To make sure you never miss a prayer time, allow notifications. You will be reminded when each prayer begins.';

  @override
  String get prayerAlertsPermissionExactAlarmTitle => 'Alarms & reminders';

  @override
  String get prayerAlertsPermissionExactAlarmBody =>
      'Allow Alarms & reminders so Adhan and prayer alerts play on time, even when the phone is idle or the screen is off.';

  @override
  String get prayerAlertsPermissionBatteryTitle => 'Battery optimization';

  @override
  String get prayerAlertsPermissionBatteryBody =>
      'Exclude Tilawa from battery optimization so prayer reminders are not delayed overnight.';

  @override
  String get prayerAlertsPermissionOemAutostartTitle => 'Background access';

  @override
  String get prayerAlertsPermissionOemAutostartBody =>
      'On this device, enable Autostart for Tilawa in your phone settings so reminders are not stopped in the background.';

  @override
  String get prayerAlertsPermissionAllow => 'Allow';

  @override
  String get prayerAlertsPermissionSkip => 'Skip';

  @override
  String get prayerAlertsPermissionContinue => 'Continue';

  @override
  String get prayerAlertsPermissionSetupRequired =>
      'Some permissions are needed for reliable prayer alerts and Adhan.';

  @override
  String get prayerAlertsPermissionSetupAction => 'Set up permissions';

  @override
  String prayerNotificationBody(String prayerName) {
    return 'It is time for $prayerName';
  }

  @override
  String prayerNotificationTitleWithLocation(
    String prayerName,
    String locationName,
  ) {
    return '$prayerName · $locationName';
  }

  @override
  String prayerNotificationBodyWithLocation(
    String prayerName,
    String locationName,
  ) {
    return 'It is time for $prayerName in $locationName';
  }

  @override
  String get prayerNotificationsChannelName => 'Prayer Times';

  @override
  String get prayerNotificationsChannelDescription =>
      'Reminders for the five daily prayer times';

  @override
  String get prayerNotificationsAdhanChannelName => 'Prayer Times (Adhan)';

  @override
  String get prayerNotificationsAdhanChannelDescription =>
      'Prayer time reminders that play the adhan sound';

  @override
  String get prayerNotificationsSilentAdhanChannelName =>
      'Prayer Times (Silent)';

  @override
  String get prayerNotificationsSilentAdhanChannelDescription =>
      'Silent prayer time reminders when Adhan plays natively';

  @override
  String get adhanIsPlaying => 'Adhan is playing…';

  @override
  String adhanPlayingNotificationBodyWithLocation(String locationName) {
    return 'Adhan is playing for $locationName';
  }

  @override
  String get stopAdhan => 'Stop Adhan';

  @override
  String get adhanStillPlayingMessage =>
      'Would you like to stop the adhan before leaving?';

  @override
  String get prayerNotificationReceived => 'Prayer notification received';

  @override
  String get viewAllPrayerTimes => 'View All Prayer Times';

  @override
  String prayerTimeAt(String time) {
    return 'at $time';
  }

  @override
  String get prayerAlertModeOff => 'Off';

  @override
  String get prayerAlertModeNotifyOnly => 'Notify only';

  @override
  String get prayerAlertModeAdhan => 'Adhan';

  @override
  String get prayerAlertModeOffDescription =>
      'No notification or Adhan for this prayer.';

  @override
  String get prayerAlertModeNotifyOnlyDescription =>
      'Show a prayer-time notification without Adhan.';

  @override
  String get prayerAlertModeAdhanDescription =>
      'Show a notification and play the Adhan.';

  @override
  String get notificationStatus => 'Notification';

  @override
  String get adhanStatus => 'Adhan';

  @override
  String get received => 'Received';

  @override
  String get sound => 'Sound';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get errorMissingNotificationPayload => 'Missing notification payload.';

  @override
  String get errorInvalidNotificationPayload => 'Invalid notification payload.';

  @override
  String get moreOptions => 'More options';

  @override
  String get supportTilawa => 'Support Tilawa';

  @override
  String get rateTilawa => 'Rate Tilawa';

  @override
  String get rateTilawaSubtitle => 'Share your feedback on the app store.';

  @override
  String get shareTilawa => 'Share Tilawa';

  @override
  String shareTilawaMessage(String appName, String storeUrl) {
    return 'Check out $appName:\n$storeUrl';
  }

  @override
  String get shareTilawaFailed =>
      'We could not open the share sheet. Please try again.';

  @override
  String get supportIntroLine => 'Your contribution helps keep Tilawa going.';

  @override
  String get supportTilawaSubtitle =>
      'Your contribution helps keep Tilawa going.';

  @override
  String get supportMissionBody => 'Your contribution helps keep Tilawa going.';

  @override
  String get supportImpactWhyTitle => 'Why?';

  @override
  String get supportImpactTitle => 'Where your contribution goes';

  @override
  String get supportImpactQuranHosting => 'Mushaf and recitation audio';

  @override
  String get supportImpactReciterAudio => 'Mushaf and recitation audio';

  @override
  String get supportImpactPrayerTools => 'Prayer times and tools';

  @override
  String get supportImpactDevelopment => 'Operations and development';

  @override
  String get supportImpactAdFree => 'Operations and development';

  @override
  String get supportTierSmall => 'Light';

  @override
  String get supportTierKind => 'Kind';

  @override
  String get supportTierGenerous => 'Generous';

  @override
  String get supportContinueWithPlay => 'Continue on Google Play';

  @override
  String get supportConfirmationTitle => 'Confirm';

  @override
  String get supportConfirmationBody =>
      'Payment via Google Play. Tilawa does not store your card details.';

  @override
  String get supportConfirm => 'Continue';

  @override
  String get supportCancel => 'Cancel';

  @override
  String get supportThankYouTitle => 'Thank you';

  @override
  String get supportThankYouBody =>
      'Your contribution went through. We appreciate your trust.';

  @override
  String get supportDone => 'Done';

  @override
  String get supportRestorePurchases => 'Restore';

  @override
  String get supportRestoreHint => 'If a payment did not finish, tap Restore.';

  @override
  String get supportTrustLinePrefix =>
      'Payment via Google Play · Part of your contribution goes to Tilawa Tech Organization and charities (';

  @override
  String get supportCharitiesLinkLabel => 'partner charities list';

  @override
  String get supportCharitiesSheetTitle => 'Partner charities';

  @override
  String get supportCharityDarAlArqam => 'Dar Al-Arqam Quran Center';

  @override
  String get supportCharityIslaheg => 'Al-Islah Charitable Foundation';

  @override
  String get supportTrustLineSuffix => ')';

  @override
  String get supportTrustLine =>
      'Payment via Google Play · Part of your contribution goes to Tilawa Tech Organization and charities (partner charities list)';

  @override
  String get supportPlayFooter =>
      'Payment via Google Play · Part of your contribution goes to Tilawa Tech Organization and charities (partner charities list)';

  @override
  String get supportDisclaimer =>
      'Payment via Google Play · Part of your contribution goes to Tilawa Tech Organization and charities (partner charities list)';

  @override
  String get supportOfflineMessage => 'An internet connection is required.';

  @override
  String get supportBillingUnavailable =>
      'Google Play payment is not available on this device.';

  @override
  String get supportProductsUnavailable =>
      'Options are unavailable right now. Try again later.';

  @override
  String get supportPurchasePending => 'Processing in Google Play.';

  @override
  String get supportPurchaseVerifyFailed =>
      'Could not confirm yet. Try again later.';

  @override
  String get supportRestoreNothingFound =>
      'No previous payment found for this account.';

  @override
  String get supportRestoreComplete => 'Restore complete.';

  @override
  String get supportSelectTier => 'Choose an amount';

  @override
  String get supportSettingsGroupTitle => 'Support Tilawa';

  @override
  String get supportHelpKeepFree => 'Optional';

  @override
  String get purchaseBillingUnavailable =>
      'Payment is not available right now.';

  @override
  String get purchaseProductNotFound => 'This option is not available.';

  @override
  String get purchaseVerificationFailed =>
      'Could not confirm. Try again later.';

  @override
  String get purchasePending => 'Still processing.';

  @override
  String get purchaseAlreadyOwned => 'This contribution was already completed.';

  @override
  String get appReviewUnavailable =>
      'Reviews are not available on this device right now.';

  @override
  String get appReviewRequestFailed =>
      'We could not open the review dialog. Please try again.';

  @override
  String get appReviewStoreListingFailed =>
      'We could not open the app store. Please try again.';

  @override
  String get appReviewPlatformUnsupported =>
      'Store reviews are not supported on this platform.';

  @override
  String get a11ySplashLoading => 'Tilawa, loading';

  @override
  String get splashSlowLoadingNotice =>
      'Some content may take a moment to load';

  @override
  String get tourActionNext => 'Next';

  @override
  String get tourActionFinish => 'Done';

  @override
  String get tourActionSkip => 'Skip';

  @override
  String tourStepSemantics(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get tourRecitersSearchTitle => 'Find a reciter';

  @override
  String get tourRecitersSearchDescription =>
      'Search by name to quickly jump to any reciter.';

  @override
  String get tourRecitersFavoritesTitle => 'Save your favorites';

  @override
  String get tourRecitersFavoritesDescription =>
      'Tap the heart to keep the reciters you love within reach.';

  @override
  String get tourRecitersOpenReciterTitle => 'Open a reciter';

  @override
  String get tourRecitersOpenReciterDescription =>
      'Tap a reciter to browse their recitations and start listening.';

  @override
  String get tourReciterPlaybackPlayingTitle => 'Now playing';

  @override
  String get tourReciterPlaybackPlayingDescription =>
      'The highlighted surah is playing now. Tap any surah to switch.';

  @override
  String get tourReciterPlaybackMiniPlayerTitle => 'Mini player';

  @override
  String get tourReciterPlaybackMiniPlayerDescription =>
      'Control playback from here while you keep browsing.';

  @override
  String get tourDebugResetTitle => 'Reset product tours';

  @override
  String get tourDebugResetDone => 'Product tours reset';

  @override
  String get inAppUpdateFlexibleRestartMessage =>
      'Update downloaded. Restart when you are ready to install it.';

  @override
  String get inAppUpdateOptionalMessage =>
      'A new version of Tilawa is available.';

  @override
  String get inAppUpdateRequiredMessage =>
      'An update is required to continue using Tilawa.';

  @override
  String get inAppUpdateRestartAction => 'Restart';

  @override
  String get inAppUpdateUpdateAction => 'Update';

  @override
  String recitationPracticeTitle(int surah, int ayah) {
    return 'Practice $surah:$ayah';
  }

  @override
  String get recitationPracticeStart => 'Start reciting';

  @override
  String get recitationPracticeStop => 'Stop';

  @override
  String recitationPracticeScore(int percent) {
    return '$percent% match';
  }

  @override
  String get recitationPracticeNextAyah => 'Next ayah';

  @override
  String get recitationPracticeTooltip => 'Practice recitation';

  @override
  String recitationPracticeSessionProgress(int current, int total) {
    return 'Ayah $current of $total';
  }

  @override
  String get recitationPracticeListening => 'Listening…';

  @override
  String get recitationPracticeEndSession => 'End session';

  @override
  String get recitationPracticeSessionComplete => 'Page complete';

  @override
  String recitationPracticeCompletedCount(int count, int total) {
    return '$count of $total passed';
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// Fallback text when location name is not available
  ///
  /// In en, this message translates to:
  /// **'Unknown Location'**
  String get unknownLocation;

  /// The title of the qibla direction screen
  ///
  /// In en, this message translates to:
  /// **'To Qibla'**
  String get toQibla;

  /// North direction label
  ///
  /// In en, this message translates to:
  /// **'N'**
  String get north;

  /// East direction label
  ///
  /// In en, this message translates to:
  /// **'E'**
  String get east;

  /// South direction label
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get south;

  /// West direction label
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get west;

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Tilawa'**
  String get appTitle;

  /// Reciters section title
  ///
  /// In en, this message translates to:
  /// **'Reciters'**
  String get reciters;

  /// Search reciters placeholder text
  ///
  /// In en, this message translates to:
  /// **'Search reciters...'**
  String get searchReciters;

  /// Loading reciters message
  ///
  /// In en, this message translates to:
  /// **'Loading reciters...'**
  String get loadingReciters;

  /// Search surah hint text
  ///
  /// In en, this message translates to:
  /// **'Search surah...'**
  String get searchSurah;

  /// No reciters found message
  ///
  /// In en, this message translates to:
  /// **'No reciters found'**
  String get noRecitersFound;

  /// No reciters match search message
  ///
  /// In en, this message translates to:
  /// **'No reciters match your search'**
  String get noRecitersMatchSearch;

  /// Filtered by letter indicator
  ///
  /// In en, this message translates to:
  /// **'Filtered by letter:'**
  String get filteredByLetter;

  /// Select recitation dropdown label
  ///
  /// In en, this message translates to:
  /// **'Select Recitation'**
  String get selectRecitation;

  /// Loading surah list message
  ///
  /// In en, this message translates to:
  /// **'Loading surah list...'**
  String get loadingSurahList;

  /// No surahs available message
  ///
  /// In en, this message translates to:
  /// **'No surahs available'**
  String get noSurahsAvailable;

  /// No surahs match search message
  ///
  /// In en, this message translates to:
  /// **'No surahs match your search'**
  String get noSurahsMatchSearch;

  /// Continue listening section title
  ///
  /// In en, this message translates to:
  /// **'Continue Listening'**
  String get continueListening;

  /// Play button text
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// Pause button text
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// Next button text
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Previous button text
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// Current playing indicator
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get currentPlaying;

  /// Duration label
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// Position label
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get position;

  /// Downloads section title
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// Playlists section title
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlists;

  /// No downloads message
  ///
  /// In en, this message translates to:
  /// **'No downloads yet'**
  String get noDownloadsYet;

  /// Downloading status
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloading;

  /// Downloaded status
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloaded;

  /// Download button text
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Delete all button text
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get deleteAll;

  /// Clear all downloads dialog title
  ///
  /// In en, this message translates to:
  /// **'Clear All Downloads'**
  String get clearAllDownloads;

  /// Clear all downloads confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all downloaded surahs? This action cannot be undone.'**
  String get clearAllDownloadsMessage;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Play all button text
  ///
  /// In en, this message translates to:
  /// **'Play All'**
  String get playAll;

  /// Pause all button text
  ///
  /// In en, this message translates to:
  /// **'Pause All'**
  String get pauseAll;

  /// Playing status
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get playing;

  /// Pending status
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Cancelled status
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// Completed status
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// Download progress label
  ///
  /// In en, this message translates to:
  /// **'Download Progress'**
  String get downloadProgress;

  /// File size label
  ///
  /// In en, this message translates to:
  /// **'File Size'**
  String get fileSize;

  /// Downloaded size label
  ///
  /// In en, this message translates to:
  /// **'Downloaded Size'**
  String get downloadedSize;

  /// Playlists screen content
  ///
  /// In en, this message translates to:
  /// **'Playlists Screen'**
  String get playlistsScreen;

  /// Back button text
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No playlists message
  ///
  /// In en, this message translates to:
  /// **'No playlists yet'**
  String get noPlaylistsYet;

  /// Create playlist button text
  ///
  /// In en, this message translates to:
  /// **'Create Playlist'**
  String get createPlaylist;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Download status checked message
  ///
  /// In en, this message translates to:
  /// **'Download status checked'**
  String get downloadStatusChecked;

  /// File validation completed message
  ///
  /// In en, this message translates to:
  /// **'File validation completed'**
  String get fileValidationCompleted;

  /// Valid downloads loaded message
  ///
  /// In en, this message translates to:
  /// **'Valid downloads loaded'**
  String get validDownloadsLoaded;

  /// Playback initiated message
  ///
  /// In en, this message translates to:
  /// **'Playback initiated'**
  String get playbackInitiated;

  /// Error label
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Settings section title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Audio settings section title
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audioSettings;

  /// Retry download button text
  ///
  /// In en, this message translates to:
  /// **'Retry Download'**
  String get retryDownload;

  /// Retry download button tooltip
  ///
  /// In en, this message translates to:
  /// **'Retry Download'**
  String get retryDownloadTooltip;

  /// View downloads action text
  ///
  /// In en, this message translates to:
  /// **'View Downloads'**
  String get viewDownloads;

  /// Premium section title
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// Premium features section title
  ///
  /// In en, this message translates to:
  /// **'Premium Features'**
  String get premiumFeatures;

  /// Unlimited downloads feature
  ///
  /// In en, this message translates to:
  /// **'Unlimited Downloads'**
  String get unlimitedDownloads;

  /// Offline mode feature
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

  /// High quality audio feature
  ///
  /// In en, this message translates to:
  /// **'High Quality Audio'**
  String get highQualityAudio;

  /// Ad-free experience feature
  ///
  /// In en, this message translates to:
  /// **'Ad-Free Experience'**
  String get adFreeExperience;

  /// Priority support feature
  ///
  /// In en, this message translates to:
  /// **'Priority Support'**
  String get prioritySupport;

  /// Exclusive content feature
  ///
  /// In en, this message translates to:
  /// **'Exclusive Content'**
  String get exclusiveContent;

  /// Choose your plan section title
  ///
  /// In en, this message translates to:
  /// **'Choose Your Plan'**
  String get chooseYourPlan;

  /// Maybe later button text
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get maybeLater;

  /// Upgrade now button text
  ///
  /// In en, this message translates to:
  /// **'Upgrade Now'**
  String get upgradeNow;

  /// Playlist name label
  ///
  /// In en, this message translates to:
  /// **'Playlist Name'**
  String get playlistName;

  /// Playlist description label
  ///
  /// In en, this message translates to:
  /// **'Playlist Description'**
  String get playlistDescription;

  /// Playlist name hint text
  ///
  /// In en, this message translates to:
  /// **'Enter playlist name'**
  String get playlistNameHint;

  /// Playlist description hint text
  ///
  /// In en, this message translates to:
  /// **'Enter playlist description'**
  String get playlistDescriptionHint;

  /// Create new playlist dialog title
  ///
  /// In en, this message translates to:
  /// **'Create New Playlist'**
  String get createNewPlaylist;

  /// Edit playlist dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit Playlist'**
  String get editPlaylist;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Playlist created success message
  ///
  /// In en, this message translates to:
  /// **'Playlist created successfully'**
  String get playlistCreated;

  /// Playlist updated success message
  ///
  /// In en, this message translates to:
  /// **'Playlist updated successfully'**
  String get playlistUpdated;

  /// Playlist deleted success message
  ///
  /// In en, this message translates to:
  /// **'Playlist deleted successfully'**
  String get playlistDeleted;

  /// Delete playlist dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Playlist'**
  String get deletePlaylist;

  /// Delete playlist confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this playlist? This action cannot be undone.'**
  String get deletePlaylistMessage;

  /// Add to playlist button text
  ///
  /// In en, this message translates to:
  /// **'Add to Playlist'**
  String get addToPlaylist;

  /// Remove from playlist button text
  ///
  /// In en, this message translates to:
  /// **'Remove from Playlist'**
  String get removeFromPlaylist;

  /// Playlist items label
  ///
  /// In en, this message translates to:
  /// **'Playlist Items'**
  String get playlistItems;

  /// Playlist duration label
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get playlistDuration;

  /// Playlist item count label
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get playlistItemCount;

  /// Search playlists hint text
  ///
  /// In en, this message translates to:
  /// **'Search Playlists'**
  String get searchPlaylists;

  /// Favorites section title
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No favorites message
  ///
  /// In en, this message translates to:
  /// **'No favorites'**
  String get noFavorites;

  /// Recent section title
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// Public visibility label
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get public;

  /// Private visibility label
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get private;

  /// Make public button text
  ///
  /// In en, this message translates to:
  /// **'Make Public'**
  String get makePublic;

  /// Make private button text
  ///
  /// In en, this message translates to:
  /// **'Make Private'**
  String get makePrivate;

  /// Duplicate playlist button text
  ///
  /// In en, this message translates to:
  /// **'Duplicate Playlist'**
  String get duplicatePlaylist;

  /// Duplicate playlist name dialog title
  ///
  /// In en, this message translates to:
  /// **'Duplicate Playlist Name'**
  String get duplicatePlaylistName;

  /// Enter duplicate name hint text
  ///
  /// In en, this message translates to:
  /// **'Enter name for duplicate playlist'**
  String get enterDuplicateName;

  /// Playlist name exists error message
  ///
  /// In en, this message translates to:
  /// **'A playlist with this name already exists'**
  String get playlistNameExists;

  /// Playlist name required error message
  ///
  /// In en, this message translates to:
  /// **'Playlist name is required'**
  String get playlistNameRequired;

  /// Playlist description required error message
  ///
  /// In en, this message translates to:
  /// **'Playlist description is required'**
  String get playlistDescriptionRequired;

  /// Playlist not found error message
  ///
  /// In en, this message translates to:
  /// **'Playlist not found'**
  String get playlistNotFound;

  /// Item already in playlist error message
  ///
  /// In en, this message translates to:
  /// **'Item is already in this playlist'**
  String get itemAlreadyInPlaylist;

  /// Empty playlist message
  ///
  /// In en, this message translates to:
  /// **'This playlist is empty'**
  String get playlistEmpty;

  /// Play playlist button text
  ///
  /// In en, this message translates to:
  /// **'Play Playlist'**
  String get playPlaylist;

  /// Shuffle playlist button text
  ///
  /// In en, this message translates to:
  /// **'Shuffle Playlist'**
  String get shufflePlaylist;

  /// Playlist statistics title
  ///
  /// In en, this message translates to:
  /// **'Playlist Statistics'**
  String get playlistStats;

  /// Total duration label
  ///
  /// In en, this message translates to:
  /// **'Total Duration'**
  String get totalDuration;

  /// Total items label
  ///
  /// In en, this message translates to:
  /// **'Total Items'**
  String get totalItems;

  /// Created on label
  ///
  /// In en, this message translates to:
  /// **'Created On'**
  String get createdOn;

  /// Last updated label
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastUpdated;

  /// Continue button text
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Premium required dialog title
  ///
  /// In en, this message translates to:
  /// **'Premium Required'**
  String get premiumRequired;

  /// Premium required message
  ///
  /// In en, this message translates to:
  /// **'This feature requires a premium subscription. Upgrade to unlock unlimited downloads and more!'**
  String get premiumRequiredMessage;

  /// Language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Arabic language option
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Refresh downloads tooltip
  ///
  /// In en, this message translates to:
  /// **'Refresh Downloads'**
  String get refreshDownloads;

  /// Download progress message
  ///
  /// In en, this message translates to:
  /// **'Downloading {surahTitle} by {reciterName}...'**
  String downloadingSurahByReciter(String surahTitle, String reciterName);

  /// Delete download dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Download'**
  String get deleteDownload;

  /// Delete download confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?'**
  String deleteDownloadConfirmation(String title);

  /// Delete all downloads confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all downloads for {reciterName}?'**
  String deleteAllDownloadsConfirmation(String reciterName);

  /// Surahs count text
  ///
  /// In en, this message translates to:
  /// **'Surahs'**
  String get surahs;

  /// Sign in button text
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// Welcome message on login screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to Tilawa'**
  String get welcomeToApp;

  /// Description text for Google sign in
  ///
  /// In en, this message translates to:
  /// **'Sign in with your Google account to continue'**
  String get signInWithGoogleDescription;

  /// Signing in progress text
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingIn;

  /// Continue with Google button text
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Google Sign-In configuration error message
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In not configured. Please contact support.'**
  String get googleSignInNotConfigured;

  /// Error message shown when third-party sign-in fails
  ///
  /// In en, this message translates to:
  /// **'Unable to sign in with third-party account'**
  String get unableToSignInWithThirdPartyAccount;

  /// Network error message
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection'**
  String get networkError;

  /// Number of recitations available for a reciter
  ///
  /// In en, this message translates to:
  /// **'{count} recitation(s) available'**
  String recitationsAvailable(int count);

  /// Loading surahs for a specific reciter message
  ///
  /// In en, this message translates to:
  /// **'Loading {reciterName} surahs...'**
  String loadingReciterSurahs(String reciterName);

  /// Add to favorites button text
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get addToFavorites;

  /// Message shown when no playlists exist
  ///
  /// In en, this message translates to:
  /// **'Create your first playlist to organize your favorite surahs'**
  String get createFirstPlaylistMessage;

  /// Added to favorites success message
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get addedToFavorites;

  /// Removed from favorites success message
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get removedFromFavorites;

  /// Edit playlist coming soon message
  ///
  /// In en, this message translates to:
  /// **'Edit playlist functionality coming soon'**
  String get editPlaylistComingSoon;

  /// Playlist details coming soon message
  ///
  /// In en, this message translates to:
  /// **'Playlist details screen coming soon'**
  String get playlistDetailsComingSoon;

  /// Play playlist coming soon message
  ///
  /// In en, this message translates to:
  /// **'Play playlist functionality coming soon'**
  String get playPlaylistComingSoon;

  /// Text prompting users to download surahs for offline listening
  ///
  /// In en, this message translates to:
  /// **'Download surahs to listen offline'**
  String get downloadSurahsOffline;

  /// App version label
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// App build number label
  ///
  /// In en, this message translates to:
  /// **'Build {build}'**
  String build(String build);

  /// Notification message when download is pending
  ///
  /// In en, this message translates to:
  /// **'Waiting to start...'**
  String get notificationWaitingToStart;

  /// Notification message showing download progress
  ///
  /// In en, this message translates to:
  /// **'Downloading: {progress}%'**
  String notificationDownloadingProgress(int progress);

  /// Notification message when download completes
  ///
  /// In en, this message translates to:
  /// **'Download complete'**
  String get notificationDownloadComplete;

  /// Notification message when download fails
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get notificationDownloadFailed;

  /// Notification title for batch download
  ///
  /// In en, this message translates to:
  /// **'Downloading {count} files'**
  String notificationBatchDownloadingTitle(int count);

  /// Notification body for batch download progress
  ///
  /// In en, this message translates to:
  /// **'Progress: {completed}/{total} ({progress}%)'**
  String notificationBatchProgress(int completed, int total, int progress);

  /// Notification message when batch download completes
  ///
  /// In en, this message translates to:
  /// **'All {count} files downloaded successfully'**
  String notificationBatchComplete(int count);

  /// Notification message when batch download fails
  ///
  /// In en, this message translates to:
  /// **'Batch download failed'**
  String get notificationBatchFailed;

  /// Resume button text
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// Appearance section title
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Primary color setting title
  ///
  /// In en, this message translates to:
  /// **'Primary Color'**
  String get primaryColor;

  /// Choose primary color dialog title
  ///
  /// In en, this message translates to:
  /// **'Choose Primary Color'**
  String get choosePrimaryColor;

  /// Cyan color name
  ///
  /// In en, this message translates to:
  /// **'Cyan'**
  String get colorCyan;

  /// Green color name
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// Brown color name
  ///
  /// In en, this message translates to:
  /// **'Brown'**
  String get colorBrown;

  /// Purple color name
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get colorPurple;

  /// Theme setting title
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// System theme option
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemTheme;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightTheme;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkTheme;

  /// Choose theme dialog title
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get chooseTheme;

  /// Choose language dialog title
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// Manage storage setting title
  ///
  /// In en, this message translates to:
  /// **'Manage Storage'**
  String get manageStorage;

  /// Manage storage setting subtitle
  ///
  /// In en, this message translates to:
  /// **'View and manage downloaded content'**
  String get manageStorageSubtitle;

  /// Concurrent downloads setting title
  ///
  /// In en, this message translates to:
  /// **'Concurrent Downloads'**
  String get concurrentDownloads;

  /// Concurrent downloads setting subtitle
  ///
  /// In en, this message translates to:
  /// **'{count} downloads at once'**
  String concurrentDownloadsSubtitle(int count);

  /// Guest user display name
  ///
  /// In en, this message translates to:
  /// **'Guest User'**
  String get guestUser;

  /// Sign in prompt subtitle
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your data'**
  String get signInToSync;

  /// Logout confirmation dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Storage used label
  ///
  /// In en, this message translates to:
  /// **'Storage Used: {size}'**
  String storageUsed(String size);

  /// Start free trial button text
  ///
  /// In en, this message translates to:
  /// **'Start Free Trial'**
  String get startFreeTrial;

  /// Go Home button text
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get goHome;

  /// Page not found message
  ///
  /// In en, this message translates to:
  /// **'Page not found: {uri}'**
  String pageNotFound(String uri);

  /// Days remaining in subscription
  ///
  /// In en, this message translates to:
  /// **'{days} days remaining'**
  String daysRemaining(int days);

  /// Message for premium users
  ///
  /// In en, this message translates to:
  /// **'You have access to all premium features!'**
  String get premiumAccessMessage;

  /// Message prompting upgrade
  ///
  /// In en, this message translates to:
  /// **'Upgrade to unlock premium features'**
  String get upgradeMessage;

  /// Free trial section title
  ///
  /// In en, this message translates to:
  /// **'7-Day Free Trial'**
  String get freeTrialTitle;

  /// Free trial description
  ///
  /// In en, this message translates to:
  /// **'Try all premium features for 7 days, completely free!'**
  String get freeTrialDescription;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get anErrorOccurred;

  /// Message shown when the user is aligned with Qibla
  ///
  /// In en, this message translates to:
  /// **'You are facing Qibla'**
  String get qiblaAligned;

  /// Message when reciter info is missing
  ///
  /// In en, this message translates to:
  /// **'Reciter information not available'**
  String get reciterInfoNotAvailable;

  /// Error message when loading reciter fails
  ///
  /// In en, this message translates to:
  /// **'Error loading reciter: {error}'**
  String errorLoadingReciter(String error);

  /// Downloading surah message
  ///
  /// In en, this message translates to:
  /// **'Downloading {surahTitle}'**
  String downloadingSurah(String surahTitle);

  /// Home screen title
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Dashboard layout option
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Home layout setting title
  ///
  /// In en, this message translates to:
  /// **'Home Layout'**
  String get homeLayout;

  /// Reciters list layout option
  ///
  /// In en, this message translates to:
  /// **'Reciters List'**
  String get recitersList;

  /// Choose home layout dialog title
  ///
  /// In en, this message translates to:
  /// **'Choose Home Layout'**
  String get chooseHomeLayout;

  /// Restore playback state setting title
  ///
  /// In en, this message translates to:
  /// **'Restore Last Playback'**
  String get restorePlaybackState;

  /// Restore playback state setting subtitle
  ///
  /// In en, this message translates to:
  /// **'Resume audio from where you left off'**
  String get restorePlaybackStateSubtitle;

  /// Label for the time remaining until next prayer
  ///
  /// In en, this message translates to:
  /// **'Time Remaining'**
  String get timeRemaining;

  /// Reciter removed from favorites message
  ///
  /// In en, this message translates to:
  /// **'Removed {reciterName} from favorites'**
  String reciterRemovedFromFavorites(String reciterName);

  /// Text shown when all surahs for a reciter are downloaded
  ///
  /// In en, this message translates to:
  /// **'All Downloaded'**
  String get allDownloaded;

  /// Undo button text
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// Athkar tab label
  ///
  /// In en, this message translates to:
  /// **'Athkar'**
  String get athkar;

  /// Done label for thikr completion
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Bytes unit
  ///
  /// In en, this message translates to:
  /// **'B'**
  String get fileSizeUnitB;

  /// Kilobytes unit
  ///
  /// In en, this message translates to:
  /// **'KB'**
  String get fileSizeUnitKB;

  /// Megabytes unit
  ///
  /// In en, this message translates to:
  /// **'MB'**
  String get fileSizeUnitMB;

  /// Gigabytes unit
  ///
  /// In en, this message translates to:
  /// **'GB'**
  String get fileSizeUnitGB;

  /// Terabytes unit
  ///
  /// In en, this message translates to:
  /// **'TB'**
  String get fileSizeUnitTB;

  /// Reset label for thikr
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Qibla tab label
  ///
  /// In en, this message translates to:
  /// **'Qibla'**
  String get qibla;

  /// Qibla direction screen title
  ///
  /// In en, this message translates to:
  /// **'Qibla Direction'**
  String get qiblaDirection;

  /// Error title when location service is disabled
  ///
  /// In en, this message translates to:
  /// **'Location Service Disabled'**
  String get locationServiceDisabled;

  /// Error message when location service is disabled
  ///
  /// In en, this message translates to:
  /// **'Please enable location services to find Qibla direction.'**
  String get enableLocationServiceMessage;

  /// Error title when location permission is denied
  ///
  /// In en, this message translates to:
  /// **'Permission Denied'**
  String get permissionDenied;

  /// Error message when location permission is denied
  ///
  /// In en, this message translates to:
  /// **'Location permission is required to calculate the Qibla direction.'**
  String get locationPermissionRequiredMessage;

  /// Button to download all surahs
  ///
  /// In en, this message translates to:
  /// **'Download All'**
  String get downloadAll;

  /// Button to download all surahs with count
  ///
  /// In en, this message translates to:
  /// **'Download All ({downloaded}/{total})'**
  String downloadAllWithCount(int downloaded, int total);

  /// Download progress message
  ///
  /// In en, this message translates to:
  /// **'Downloading all surahs...'**
  String get downloadingAllSurahs;

  /// Button text to complete downloading with count
  ///
  /// In en, this message translates to:
  /// **'Complete Downloading ({downloaded}/{total})'**
  String completeDownloadingWithCount(int downloaded, int total);

  /// Pause progress with count
  ///
  /// In en, this message translates to:
  /// **'Pause {percent}% ({downloaded}/{total})'**
  String pauseProgressWithCount(int percent, int downloaded, int total);

  /// Button text to complete downloading remaining surahs
  ///
  /// In en, this message translates to:
  /// **'Complete Downloading'**
  String get completeDownloading;

  /// Try again button text
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// Open settings button text
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// Generic error title for Qibla
  ///
  /// In en, this message translates to:
  /// **'Unable to find Qibla'**
  String get unableToFindQibla;

  /// Tip message displayed on Qibla compass screen
  ///
  /// In en, this message translates to:
  /// **'Make sure the arrow moves when you rotate your device'**
  String get qiblaCompassTip;

  /// Onboarding page 1 title
  ///
  /// In en, this message translates to:
  /// **'Minutes from the Quran... change your whole day'**
  String get onboardingTitle1;

  /// Onboarding page 1 description
  ///
  /// In en, this message translates to:
  /// **'When you feel life\'s constraints, remember there are verses in the Quran that speak exactly to your state. Just search for them and you will find tranquility.'**
  String get onboardingDesc1;

  /// Onboarding page 2 title
  ///
  /// In en, this message translates to:
  /// **'A spiritual journey with multiple Quranic voices'**
  String get onboardingTitle2;

  /// Onboarding page 2 description
  ///
  /// In en, this message translates to:
  /// **'Here, the voices of reciters from all over the nation gather, in recitations that weave the beauty of letters with the light of meaning.'**
  String get onboardingDesc2;

  /// Onboarding page 3 title
  ///
  /// In en, this message translates to:
  /// **'Every verse and dhikr is an ongoing charity for Abu Hudhayfah'**
  String get onboardingTitle3;

  /// Onboarding page 3 description
  ///
  /// In en, this message translates to:
  /// **'Every verse you hear and every dhikr you repeat is an ongoing charity for our friend and brother Abu Hudhayfah Ahmed Mahmoud Toni, may God have mercy on him, forgive him, and grant him the highest level of Paradise.'**
  String get onboardingDesc3;

  /// Start button text
  ///
  /// In en, this message translates to:
  /// **'Let\'s start our journey with the Quran'**
  String get startJourney;

  /// Sleep timer dialog title
  ///
  /// In en, this message translates to:
  /// **'Recitation Duration'**
  String get recitationDuration;

  /// 15 minutes option
  ///
  /// In en, this message translates to:
  /// **'15 Minutes'**
  String get minutes15;

  /// 30 minutes option
  ///
  /// In en, this message translates to:
  /// **'30 Minutes'**
  String get minutes30;

  /// 60 minutes option
  ///
  /// In en, this message translates to:
  /// **'60 Minutes'**
  String get minutes60;

  /// Cancel timer button text
  ///
  /// In en, this message translates to:
  /// **'Cancel Timer'**
  String get cancelTimer;

  /// Custom timer option
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// Hour label for duration picker
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get hourLabel;

  /// Minute label for duration picker
  ///
  /// In en, this message translates to:
  /// **'Minute'**
  String get minuteLabel;

  /// Settings label to enable recitation duration control feature
  ///
  /// In en, this message translates to:
  /// **'Recitation Duration'**
  String get enableRecitationDuration;

  /// Settings subtitle to enable recitation duration control feature
  ///
  /// In en, this message translates to:
  /// **'Show and enable recitation duration control feature'**
  String get enableRecitationDurationSubtitle;

  /// Recitation duration control feature active status
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get sleepTimerActive;

  /// Recitation duration control feature end of track option
  ///
  /// In en, this message translates to:
  /// **'End of Track'**
  String get endOfTrack;

  /// Set timer title
  ///
  /// In en, this message translates to:
  /// **'Set Timer'**
  String get setTimer;

  /// No internet connection message
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternetConnection;

  /// Error shown when user tries to play undownloaded content while offline
  ///
  /// In en, this message translates to:
  /// **'This content is not available offline. Please download it first.'**
  String get offlinePlaybackError;

  /// Error shown when downloaded file no longer exists on disk
  ///
  /// In en, this message translates to:
  /// **'Downloaded file is missing. Please re-download this content.'**
  String get offlineFileMissingError;

  /// Error shown when download exists but is not completed
  ///
  /// In en, this message translates to:
  /// **'This content is not fully downloaded. Please complete the download first.'**
  String get offlineDownloadIncompleteError;

  /// Bookmarks screen title
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// Add bookmark button text
  ///
  /// In en, this message translates to:
  /// **'Add Bookmark'**
  String get addBookmark;

  /// Delete bookmark button text
  ///
  /// In en, this message translates to:
  /// **'Delete Bookmark'**
  String get deleteBookmark;

  /// Edit bookmark button text
  ///
  /// In en, this message translates to:
  /// **'Edit Bookmark'**
  String get editBookmark;

  /// Search bookmarks hint text
  ///
  /// In en, this message translates to:
  /// **'Search bookmarks...'**
  String get searchBookmarks;

  /// No bookmarks empty state title
  ///
  /// In en, this message translates to:
  /// **'No Bookmarks Yet'**
  String get noBookmarksYet;

  /// No bookmarks empty state description
  ///
  /// In en, this message translates to:
  /// **'Save your favorite moments while listening to the Quran'**
  String get noBookmarksDescription;

  /// Bookmark added confirmation message
  ///
  /// In en, this message translates to:
  /// **'Bookmark added'**
  String get bookmarkAdded;

  /// Bookmark deleted confirmation message
  ///
  /// In en, this message translates to:
  /// **'Bookmark deleted'**
  String get bookmarkDeleted;

  /// Bookmark label input hint
  ///
  /// In en, this message translates to:
  /// **'Label (optional)'**
  String get bookmarkLabel;

  /// Delete bookmark confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this bookmark?'**
  String get deleteBookmarkConfirmation;

  /// Listening history screen title
  ///
  /// In en, this message translates to:
  /// **'Listening History'**
  String get listeningHistory;

  /// No history empty state title
  ///
  /// In en, this message translates to:
  /// **'No History Yet'**
  String get noHistoryYet;

  /// No history empty state description
  ///
  /// In en, this message translates to:
  /// **'Your listening history will appear here'**
  String get noHistoryDescription;

  /// Clear history button text
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get clearHistory;

  /// Clear history confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all listening history?'**
  String get clearHistoryConfirmation;

  /// History deleted confirmation message
  ///
  /// In en, this message translates to:
  /// **'History deleted'**
  String get historyDeleted;

  /// Total surahs listened label
  ///
  /// In en, this message translates to:
  /// **'Total Surahs'**
  String get totalSurahs;

  /// Total listening time label
  ///
  /// In en, this message translates to:
  /// **'Total Time'**
  String get totalListeningTime;

  /// Search history hint text
  ///
  /// In en, this message translates to:
  /// **'Search history...'**
  String get searchHistory;

  /// Today date label
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Yesterday date label
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// Number of times played
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Played 1 time} other{Played {count} times}}'**
  String playedTimes(int count);

  /// Prayer times screen title
  ///
  /// In en, this message translates to:
  /// **'Prayer Times'**
  String get prayerTimes;

  /// Prayer settings title
  ///
  /// In en, this message translates to:
  /// **'Prayer Settings'**
  String get prayerSettings;

  /// Fajr prayer name
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get fajr;

  /// Sunrise time label
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get sunrise;

  /// Dhuhr prayer name
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get dhuhr;

  /// Asr prayer name
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get asr;

  /// Maghrib prayer name
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get maghrib;

  /// Isha prayer name
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get isha;

  /// Midnight marker label
  ///
  /// In en, this message translates to:
  /// **'Midnight'**
  String get midnight;

  /// Last third of night label
  ///
  /// In en, this message translates to:
  /// **'Last Third'**
  String get lastThird;

  /// Next prayer label
  ///
  /// In en, this message translates to:
  /// **'Next Prayer'**
  String get nextPrayer;

  /// Prayer calculation method label
  ///
  /// In en, this message translates to:
  /// **'Calculation Method'**
  String get calculationMethod;

  /// Muslim World League calculation method
  ///
  /// In en, this message translates to:
  /// **'Muslim World League'**
  String get calculationMethodMuslimWorldLeague;

  /// Egyptian General Authority of Survey calculation method
  ///
  /// In en, this message translates to:
  /// **'Egyptian General Authority'**
  String get calculationMethodEgyptian;

  /// University of Islamic Sciences, Karachi calculation method
  ///
  /// In en, this message translates to:
  /// **'University of Karachi'**
  String get calculationMethodKarachi;

  /// Umm al-Qura University, Makkah calculation method
  ///
  /// In en, this message translates to:
  /// **'Umm Al-Qura, Makkah'**
  String get calculationMethodUmmAlQura;

  /// Islamic Society of North America calculation method
  ///
  /// In en, this message translates to:
  /// **'ISNA (North America)'**
  String get calculationMethodIsna;

  /// Tehran, Institute of Geophysics calculation method
  ///
  /// In en, this message translates to:
  /// **'Tehran'**
  String get calculationMethodTehran;

  /// Gulf Region calculation method
  ///
  /// In en, this message translates to:
  /// **'Gulf Region'**
  String get calculationMethodGulf;

  /// Kuwait calculation method
  ///
  /// In en, this message translates to:
  /// **'Kuwait'**
  String get calculationMethodKuwait;

  /// Qatar calculation method
  ///
  /// In en, this message translates to:
  /// **'Qatar'**
  String get calculationMethodQatar;

  /// Singapore, MUIS calculation method
  ///
  /// In en, this message translates to:
  /// **'Singapore (MUIS)'**
  String get calculationMethodSingapore;

  /// Turkey, Diyanet calculation method
  ///
  /// In en, this message translates to:
  /// **'Turkey (Diyanet)'**
  String get calculationMethodTurkey;

  /// Asr calculation method label
  ///
  /// In en, this message translates to:
  /// **'Asr Calculation'**
  String get asrCalculation;

  /// Standard Asr calculation method (Shafi'i, Maliki, Hanbali)
  ///
  /// In en, this message translates to:
  /// **'Shafi\'i, Maliki, Hanbali'**
  String get asrCalculationShafii;

  /// Hanafi Asr calculation method
  ///
  /// In en, this message translates to:
  /// **'Hanafi'**
  String get asrCalculationHanafi;

  /// Display options section title
  ///
  /// In en, this message translates to:
  /// **'Display Options'**
  String get displayOptions;

  /// 24-hour format toggle label
  ///
  /// In en, this message translates to:
  /// **'Use 24-hour format'**
  String get use24HourFormat;

  /// Show sunrise toggle label
  ///
  /// In en, this message translates to:
  /// **'Show Sunrise'**
  String get showSunrise;

  /// Location required title
  ///
  /// In en, this message translates to:
  /// **'Location Required'**
  String get locationRequired;

  /// Location required description
  ///
  /// In en, this message translates to:
  /// **'Prayer times require your location to calculate accurately'**
  String get locationRequiredDescription;

  /// Enable location button text
  ///
  /// In en, this message translates to:
  /// **'Enable Location'**
  String get enableLocation;

  /// Update location button text
  ///
  /// In en, this message translates to:
  /// **'Update Location'**
  String get updateLocation;

  /// Current location label
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// Title for today's prayer times schedule section
  ///
  /// In en, this message translates to:
  /// **'Today\'s schedule'**
  String get prayerTimesTodaySchedule;

  /// Subtitle for today's prayer times schedule section
  ///
  /// In en, this message translates to:
  /// **'Prayer times and nightly markers'**
  String get prayerTimesTodayScheduleSubtitle;

  /// Helper text shown while refreshing prayer times location
  ///
  /// In en, this message translates to:
  /// **'Refreshing location...'**
  String get prayerTimesRefreshingLocation;

  /// Helper text inviting the user to refresh prayer times location
  ///
  /// In en, this message translates to:
  /// **'Tap to refresh location'**
  String get prayerTimesTapToRefreshLocation;

  /// Countdown label until the next prayer
  ///
  /// In en, this message translates to:
  /// **'Time remaining until {prayerName}'**
  String prayerTimesTimeRemainingUntil(String prayerName);

  /// Label for the scheduled time of the next prayer
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get prayerTimesScheduled;

  /// Status label for an upcoming prayer
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get prayerTimesUpcoming;

  /// Status label for a prayer that has passed
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get prayerTimesPassed;

  /// Label for iqamah time
  ///
  /// In en, this message translates to:
  /// **'Iqamah: {time}'**
  String prayerTimesIqamahAt(String time);

  /// Label for ishraq time
  ///
  /// In en, this message translates to:
  /// **'Ishraq: {time}'**
  String prayerTimesIshraqAt(String time);

  /// Description for the midnight marker card
  ///
  /// In en, this message translates to:
  /// **'Night midpoint marker'**
  String get prayerTimesNightMidpointMarker;

  /// Description for the last third of night marker card
  ///
  /// In en, this message translates to:
  /// **'Last third begins'**
  String get prayerTimesLastThirdBegins;

  /// Hours label
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// Minutes label
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// Minutes short label
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutesShort;

  /// Seconds label
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// At preposition for time
  ///
  /// In en, this message translates to:
  /// **'at'**
  String get at;

  /// Monthly view tab title
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// Notifications section title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Enable notifications toggle label
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// Minutes before prayer notification
  ///
  /// In en, this message translates to:
  /// **'{count} minutes before'**
  String minutesBefore(int count);

  /// Reader settings title
  ///
  /// In en, this message translates to:
  /// **'Reader Settings'**
  String get readerSettings;

  /// Font size setting label
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// Line height setting label
  ///
  /// In en, this message translates to:
  /// **'Line Height'**
  String get lineHeight;

  /// Font type setting label
  ///
  /// In en, this message translates to:
  /// **'Font Type'**
  String get fontType;

  /// Show translation toggle label
  ///
  /// In en, this message translates to:
  /// **'Show Translation'**
  String get showTranslation;

  /// Show ayah numbers toggle label
  ///
  /// In en, this message translates to:
  /// **'Show Ayah Numbers'**
  String get showAyahNumbers;

  /// Show transliteration toggle label
  ///
  /// In en, this message translates to:
  /// **'Show Transliteration'**
  String get showTransliteration;

  /// Ayah label
  ///
  /// In en, this message translates to:
  /// **'Ayah'**
  String get ayah;

  /// Ayahs plural label
  ///
  /// In en, this message translates to:
  /// **'Ayahs'**
  String get ayahs;

  /// Surah not found error message
  ///
  /// In en, this message translates to:
  /// **'Surah not found'**
  String get surahNotFound;

  /// Play ayah option
  ///
  /// In en, this message translates to:
  /// **'Play Ayah'**
  String get playAyah;

  /// Copy ayah option
  ///
  /// In en, this message translates to:
  /// **'Copy Ayah'**
  String get copyAyah;

  /// Share ayah option
  ///
  /// In en, this message translates to:
  /// **'Share Ayah'**
  String get shareAyah;

  /// Search ayahs title
  ///
  /// In en, this message translates to:
  /// **'Search Ayahs'**
  String get searchAyahs;

  /// Search ayahs hint text
  ///
  /// In en, this message translates to:
  /// **'Enter Arabic text to search...'**
  String get searchAyahsHint;

  /// Enter search query message
  ///
  /// In en, this message translates to:
  /// **'Enter a search query'**
  String get enterSearchQuery;

  /// No search results message
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// Close button text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Continue reading button text
  ///
  /// In en, this message translates to:
  /// **'Continue Reading'**
  String get continueReading;

  /// Last read position label
  ///
  /// In en, this message translates to:
  /// **'Last Read'**
  String get lastRead;

  /// Go to ayah option
  ///
  /// In en, this message translates to:
  /// **'Go to Ayah'**
  String get goToAyah;

  /// Juz label
  ///
  /// In en, this message translates to:
  /// **'Juz'**
  String get juz;

  /// Page label
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get page;

  /// Verses label
  ///
  /// In en, this message translates to:
  /// **'Verses'**
  String get verses;

  /// Meccan surah type
  ///
  /// In en, this message translates to:
  /// **'Meccan'**
  String get meccan;

  /// Medinan surah type
  ///
  /// In en, this message translates to:
  /// **'Medinan'**
  String get medinan;

  /// Bookmark updated confirmation message
  ///
  /// In en, this message translates to:
  /// **'Bookmark updated'**
  String get bookmarkUpdated;

  /// No bookmarks found in search
  ///
  /// In en, this message translates to:
  /// **'No bookmarks found'**
  String get noBookmarksFound;

  /// No bookmarks message
  ///
  /// In en, this message translates to:
  /// **'No bookmarks'**
  String get noBookmarks;

  /// Try different search suggestion
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearch;

  /// No bookmarks hint text
  ///
  /// In en, this message translates to:
  /// **'Bookmark your favorite moments while listening'**
  String get noBookmarksHint;

  /// Edit bookmark label dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit Bookmark Label'**
  String get editBookmarkLabel;

  /// Enter bookmark label hint
  ///
  /// In en, this message translates to:
  /// **'Enter bookmark label'**
  String get enterBookmarkLabel;

  /// No search results message
  ///
  /// In en, this message translates to:
  /// **'No search results'**
  String get noSearchResults;

  /// Clear all button text
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// Time adjustments section title
  ///
  /// In en, this message translates to:
  /// **'Time Adjustments'**
  String get timeAdjustments;

  /// Day label for calendar
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// Features section title in settings
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

  /// Quran reader feature title
  ///
  /// In en, this message translates to:
  /// **'Quran Reader'**
  String get quranReader;

  /// Message shown when text is copied
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// Error message when audio fails to play
  ///
  /// In en, this message translates to:
  /// **'Error playing audio'**
  String get errorPlayingAudio;

  /// Message for features not yet implemented
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// See all button text
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// Welcome back message
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBack;

  /// Subtitle for welcome message
  ///
  /// In en, this message translates to:
  /// **'Continue your spiritual journey.'**
  String get continueSpiritualJourney;

  /// Recently played section title
  ///
  /// In en, this message translates to:
  /// **'Recently Played'**
  String get recentlyPlayed;

  /// Quick access section title
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get quickAccess;

  /// Last read dashboard item
  ///
  /// In en, this message translates to:
  /// **'Last Read'**
  String get dashboardLastRead;

  /// Quran dashboard item
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get dashboardQuran;

  /// Duas dashboard item
  ///
  /// In en, this message translates to:
  /// **'Duas'**
  String get dashboardDuas;

  /// Hifz dashboard item
  ///
  /// In en, this message translates to:
  /// **'Hifz'**
  String get hifz;

  /// Apps dashboard item
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get apps;

  /// Donation dashboard item
  ///
  /// In en, this message translates to:
  /// **'Donation'**
  String get donation;

  /// Today's activities card title
  ///
  /// In en, this message translates to:
  /// **'Today\'s Activities'**
  String get todaysActivities;

  /// Today's activities card subtitle
  ///
  /// In en, this message translates to:
  /// **'Complete the daily activity checklist.'**
  String get dailyActivitiesSubtitle;

  /// Tasks progress label
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} Tasks'**
  String tasksProgress(int completed, int total);

  /// Go to checklist button text
  ///
  /// In en, this message translates to:
  /// **'Go to Checklist'**
  String get goToChecklist;

  /// Next prayer time indication
  ///
  /// In en, this message translates to:
  /// **'{time} remaining until {prayer}'**
  String prayerAwayFrom(String prayer, String time);

  /// Quran section title
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get quran;

  /// Button to continue reading Quran from last page
  ///
  /// In en, this message translates to:
  /// **'Continue Reading Quran'**
  String get continueReadingQuran;

  /// Title of the surah index sheet
  ///
  /// In en, this message translates to:
  /// **'Surah Index'**
  String get surahIndex;

  /// Surah count label in the index header
  ///
  /// In en, this message translates to:
  /// **'{count} Surahs'**
  String surahCountLabel(int count);

  /// Message shown when surah search returns no results
  ///
  /// In en, this message translates to:
  /// **'No surahs found'**
  String get noSurahsFound;

  /// Surah navigation progress indicator
  ///
  /// In en, this message translates to:
  /// **'Surah {current} / {total}'**
  String surahProgress(int current, int total);

  /// Label showing surah and ayah number
  ///
  /// In en, this message translates to:
  /// **'Surah {surah}, Ayah {ayah}'**
  String surahAyahLabel(int surah, int ayah);

  /// Ayah count with place of revelation
  ///
  /// In en, this message translates to:
  /// **'{count} Ayahs · {place}'**
  String ayahCountWithPlace(int count, String place);

  /// Sajda indicator label
  ///
  /// In en, this message translates to:
  /// **'Sajda'**
  String get sajda;

  /// Prefix for surah names
  ///
  /// In en, this message translates to:
  /// **'Surah'**
  String get surahPrefix;

  /// Pluralized ayah count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Ayah} other{{count} Ayahs}}'**
  String ayahCount(int count);

  /// Label for Quranic Juz/Part
  ///
  /// In en, this message translates to:
  /// **'Part'**
  String get juzPart;

  /// Label for Quranic Hizb
  ///
  /// In en, this message translates to:
  /// **'Hizb'**
  String get hizb;

  /// Message during Quran font download
  ///
  /// In en, this message translates to:
  /// **'Preparing High-Quality Quran Fonts...'**
  String get preparingFonts;

  /// Message during Quran rendering
  ///
  /// In en, this message translates to:
  /// **'Loading Quran...'**
  String get loadingQuran;

  /// Description of the Quran fonts download
  ///
  /// In en, this message translates to:
  /// **'This is a one-time download (~50MB) for the best reading experience.'**
  String get fontsDownloadDescription;

  /// Error message when Quran fonts fail to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load fonts'**
  String get fontsFailedToLoad;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

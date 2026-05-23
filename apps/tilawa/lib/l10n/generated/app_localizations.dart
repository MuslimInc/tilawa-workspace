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

  /// Screen reader label for opening a reciter from the list
  ///
  /// In en, this message translates to:
  /// **'Open {reciterName}'**
  String a11yOpenReciterDetails(String reciterName);

  /// Accessibility name for the favorites-only filter toggle
  ///
  /// In en, this message translates to:
  /// **'Show favorite reciters only'**
  String get a11yFavoriteRecitersOnlyFilter;

  /// Accessibility label for the Arabic letter scrollbar
  ///
  /// In en, this message translates to:
  /// **'Letter index'**
  String get a11yRecitersLetterIndex;

  /// Accessibility hint for the Arabic letter scrollbar
  ///
  /// In en, this message translates to:
  /// **'Drag up or down to jump to a letter'**
  String get a11yRecitersAlphabetScrollbarHint;

  /// Tooltip for enabling the reciters A–Z letter index
  ///
  /// In en, this message translates to:
  /// **'Show letter index'**
  String get showRecitersLetterIndex;

  /// Tooltip for hiding the reciters A–Z letter index
  ///
  /// In en, this message translates to:
  /// **'Hide letter index'**
  String get hideRecitersLetterIndex;

  /// Tooltip for the reciters header overflow menu
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get recitersMoreActions;

  /// Overflow menu item to show or hide the A–Z letter index
  ///
  /// In en, this message translates to:
  /// **'Letter index'**
  String get recitersLetterIndexMenuItem;

  /// Tooltip for clearing the reciters search field
  ///
  /// In en, this message translates to:
  /// **'Clear search text'**
  String get a11yClearRecitersSearch;

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

  /// Label above the queue source in the expanded player
  ///
  /// In en, this message translates to:
  /// **'Playing from'**
  String get playingFrom;

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

  /// Label for stopping audio playback
  ///
  /// In en, this message translates to:
  /// **'Stop playback'**
  String get stopPlayback;

  /// Confirmation message before stopping audio playback
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to stop playback?'**
  String get stopPlaybackConfirmMessage;

  /// Snackbar message when player is dismissed
  ///
  /// In en, this message translates to:
  /// **'Player closed'**
  String get playerDismissed;

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

  /// Clear all favorite reciters action label
  ///
  /// In en, this message translates to:
  /// **'Clear Favorites'**
  String get clearFavorites;

  /// Clear all favorite reciters confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all reciters from favorites?'**
  String get clearFavoritesConfirmation;

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

  /// Suffix on reciter list rows when more than one moshaf exists
  ///
  /// In en, this message translates to:
  /// **' · {count} more'**
  String reciterAdditionalMoshafCount(int count);

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

  /// Accessibility label for removing a reciter from favorites
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

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

  /// Gold accent preset name for primary color
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get colorGold;

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

  /// Server error message
  ///
  /// In en, this message translates to:
  /// **'Server error, please try again later'**
  String get serverError;

  /// Cache/Storage error message
  ///
  /// In en, this message translates to:
  /// **'Storage error'**
  String get cacheError;

  /// Audio playback error message
  ///
  /// In en, this message translates to:
  /// **'Audio playback error'**
  String get audioError;

  /// Validation error message
  ///
  /// In en, this message translates to:
  /// **'Invalid data provided'**
  String get validationError;

  /// Permission error message
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionError;

  /// Unexpected error message
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get unexpectedError;

  /// Persistence error message
  ///
  /// In en, this message translates to:
  /// **'Failed to save data'**
  String get persistenceError;

  /// UI error message
  ///
  /// In en, this message translates to:
  /// **'User interface error'**
  String get uiError;

  /// Unknown error message
  ///
  /// In en, this message translates to:
  /// **'Unknown error occurred'**
  String get unknownError;

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

  /// Tasbeeh category title in Athkar
  ///
  /// In en, this message translates to:
  /// **'Tasbeeh'**
  String get tasbeehCategory;

  /// Input label for creating custom dhikr
  ///
  /// In en, this message translates to:
  /// **'Dhikr'**
  String get tasbeehInputLabel;

  /// Hint for custom dhikr input
  ///
  /// In en, this message translates to:
  /// **'Write your dhikr, e.g. Subhan Allah'**
  String get tasbeehInputHint;

  /// Save custom dhikr button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get tasbeehSave;

  /// Instruction for tap-to-count interaction
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere to increment'**
  String get tasbeehTapToCount;

  /// Target count input label
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get tasbeehTargetLabel;

  /// Button label to apply target count
  ///
  /// In en, this message translates to:
  /// **'Set target'**
  String get tasbeehSetTarget;

  /// Title for add new Tasbeeh option
  ///
  /// In en, this message translates to:
  /// **'Add new Tasbeeh'**
  String get tasbeehAddNewOptionTitle;

  /// Subtitle for add new Tasbeeh option
  ///
  /// In en, this message translates to:
  /// **'Create your dhikr and target, then start counting'**
  String get tasbeehAddNewOptionSubtitle;

  /// Title for viewing saved Tasbeeh history
  ///
  /// In en, this message translates to:
  /// **'View saved Tasbeeh'**
  String get tasbeehViewHistoryOptionTitle;

  /// Subtitle for viewing saved Tasbeeh history
  ///
  /// In en, this message translates to:
  /// **'Choose one from your history and continue counting'**
  String get tasbeehViewHistoryOptionSubtitle;

  /// Button label to go to counting view
  ///
  /// In en, this message translates to:
  /// **'Start counting'**
  String get tasbeehGoToCounting;

  /// Button label to return to Tasbeeh options
  ///
  /// In en, this message translates to:
  /// **'Back to options'**
  String get tasbeehBackToOptions;

  /// Heading for selecting saved Tasbeeh
  ///
  /// In en, this message translates to:
  /// **'Choose saved Tasbeeh'**
  String get tasbeehChooseSavedDhikr;

  /// Message shown when Tasbeeh history is empty
  ///
  /// In en, this message translates to:
  /// **'No saved Tasbeeh yet'**
  String get tasbeehHistoryEmpty;

  /// Confirmation message before deleting a saved Tasbeeh item
  ///
  /// In en, this message translates to:
  /// **'Delete \"{tasbeehText}\" from your saved Tasbeeh history?'**
  String tasbeehDeleteConfirmationMessage(String tasbeehText);

  /// Label for removing saved tasbeeh item
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get tasbeehRemoveItem;

  /// Current target count label
  ///
  /// In en, this message translates to:
  /// **'Current target: {count}'**
  String tasbeehCurrentTarget(int count);

  /// Prompt shown when no dhikr is selected
  ///
  /// In en, this message translates to:
  /// **'Select or create a dhikr to start counting'**
  String get tasbeehSelectOrCreatePrompt;

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

  /// Confirmation message before resetting Athkar count for the current item
  ///
  /// In en, this message translates to:
  /// **'Reset the count for this dhikr? Your progress on it will be cleared.'**
  String get athkarResetConfirmationMessage;

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

  /// SnackBar message shown when Qibla compass sensor accuracy is poor
  ///
  /// In en, this message translates to:
  /// **'Compass accuracy is low. Move your phone in a figure-eight motion to calibrate it.'**
  String get qiblaCompassAccuracyPoor;

  /// Onboarding page 1 title (line break intentional)
  ///
  /// In en, this message translates to:
  /// **'Minutes with the Quran…\nChanges your whole day'**
  String get onboardingTitle1;

  /// Onboarding page 1 description
  ///
  /// In en, this message translates to:
  /// **'Find verses that fit what you\'re going through, and take quiet minutes to read or listen.'**
  String get onboardingDesc1;

  /// Onboarding page 2 title (line break intentional)
  ///
  /// In en, this message translates to:
  /// **'Many reciter voices\nListen your way'**
  String get onboardingTitle2;

  /// Onboarding page 2 description
  ///
  /// In en, this message translates to:
  /// **'Different reciters and riwayat — choose the voice and style that feels right.'**
  String get onboardingDesc2;

  /// Onboarding page 3 title (line break intentional)
  ///
  /// In en, this message translates to:
  /// **'Every verse and dhikr\nOngoing charity for Abu Hudhayfah'**
  String get onboardingTitle3;

  /// Onboarding page 3 description
  ///
  /// In en, this message translates to:
  /// **'Every Qur\'an listen and every dhikr you repeat is ongoing charity for our brother Abu Hudhayfah Ahmad Mahmud Toni — may God have mercy on him and forgive him.'**
  String get onboardingDesc3;

  /// TalkBack label for onboarding carousel page
  ///
  /// In en, this message translates to:
  /// **'Screen {current} of {total}'**
  String onboardingPageSemantics(int current, int total);

  /// Short caption under onboarding slide 2 device preview
  ///
  /// In en, this message translates to:
  /// **'Browse reciters with search and favorites'**
  String get onboardingVisualHint2;

  /// Start button text
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get startJourney;

  /// Sleep timer dialog title
  ///
  /// In en, this message translates to:
  /// **'Recitation Duration'**
  String get recitationDuration;

  /// Title of the background source selection dialog
  ///
  /// In en, this message translates to:
  /// **'Choose Background Source'**
  String get chooseBackgroundSource;

  /// Gallery option in background source selection
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// Camera option in background source selection
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// Option to reset player background to default
  ///
  /// In en, this message translates to:
  /// **'Reset to Default'**
  String get resetToDefault;

  /// Title of the volume adjustment dialog
  ///
  /// In en, this message translates to:
  /// **'Adjust volume'**
  String get adjustVolume;

  /// Title of the playback speed adjustment dialog
  ///
  /// In en, this message translates to:
  /// **'Playback speed'**
  String get playbackSpeed;

  /// Fallback text when reciter name is not available
  ///
  /// In en, this message translates to:
  /// **'Unknown Reciter'**
  String get unknownReciter;

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

  /// Toggle text next to notification status icons on prayer time rows
  ///
  /// In en, this message translates to:
  /// **'Show alert chip labels'**
  String get showPrayerTimesAlertChipLabels;

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

  /// Accessibility label while the prayer times screen content is loading
  ///
  /// In en, this message translates to:
  /// **'Loading prayer times...'**
  String get prayerTimesLoading;

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

  /// Short countdown caption when the hero already shows the prayer name
  ///
  /// In en, this message translates to:
  /// **'Time remaining'**
  String get prayerTimesTimeRemainingCaption;

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

  /// Share action title
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Option to share a page screenshot
  ///
  /// In en, this message translates to:
  /// **'Share Screenshot'**
  String get shareScreenshot;

  /// Option to share an audio clip of a recitation
  ///
  /// In en, this message translates to:
  /// **'Share Audio Clip'**
  String get shareAudioClip;

  /// Option to share ayah as text
  ///
  /// In en, this message translates to:
  /// **'Share as Text'**
  String get shareAsText;

  /// Option to share audio clip of a single verse
  ///
  /// In en, this message translates to:
  /// **'Share Verse Audio'**
  String get shareVerseAudioClip;

  /// Label for start ayah picker
  ///
  /// In en, this message translates to:
  /// **'From Ayah'**
  String get fromAyah;

  /// Label for end ayah picker
  ///
  /// In en, this message translates to:
  /// **'To Ayah'**
  String get toAyah;

  /// Button to generate audio clip and share
  ///
  /// In en, this message translates to:
  /// **'Generate & Share'**
  String get generateAndShare;

  /// Error when verse range exceeds maximum
  ///
  /// In en, this message translates to:
  /// **'Maximum {count} verses per clip.'**
  String maxVersesExceeded(int count);

  /// Inline reason shown when the user picks fromAyah > toAyah in the share composer
  ///
  /// In en, this message translates to:
  /// **'First ayah must be before or equal to the last.'**
  String get shareInvalidRangeOrder;

  /// Inline reason shown when the share composer range falls outside [1, maxAyah]
  ///
  /// In en, this message translates to:
  /// **'Selected range is outside this surah.'**
  String get shareInvalidRangeBounds;

  /// Status message while sharing
  ///
  /// In en, this message translates to:
  /// **'Sharing...'**
  String get sharing;

  /// Branding text on shared content
  ///
  /// In en, this message translates to:
  /// **'Shared via Tilawa'**
  String get sharedViaTilawa;

  /// Fallback message when reciter is not mapped
  ///
  /// In en, this message translates to:
  /// **'Verse audio not available for this reciter. Using default reciter.'**
  String get reciterNotAvailable;

  /// Button to share audio clip
  ///
  /// In en, this message translates to:
  /// **'Share Audio Clip'**
  String get shareAudio;

  /// Button to generate a reel
  ///
  /// In en, this message translates to:
  /// **'Generate Reel (Video)'**
  String get generateReel;

  /// Title for reel review section
  ///
  /// In en, this message translates to:
  /// **'Review Reel'**
  String get reviewReel;

  /// Button to share generated reel
  ///
  /// In en, this message translates to:
  /// **'Share Reel'**
  String get shareReel;

  /// Subtitle in the share options sheet
  ///
  /// In en, this message translates to:
  /// **'Choose a format that carries these verses beautifully.'**
  String get shareSheetSubtitle;

  /// Instruction label shown when a page has multiple surahs
  ///
  /// In en, this message translates to:
  /// **'Select Surah to share'**
  String get selectSurahToShare;

  /// Description for the screenshot share option
  ///
  /// In en, this message translates to:
  /// **'A clean Quran page capture ready to send.'**
  String get shareScreenshotDescription;

  /// Description for the audio clip share option
  ///
  /// In en, this message translates to:
  /// **'Create a recitation clip or reel with audio.'**
  String get shareAudioClipDescription;

  /// Subtitle in the audio clip and reel configuration sheet
  ///
  /// In en, this message translates to:
  /// **'Select a verse range and generate audio or a vertical reel.'**
  String get audioClipConfigSubtitle;

  /// Supportive text describing the verse limit for a clip
  ///
  /// In en, this message translates to:
  /// **'Up to {count} verses per clip.'**
  String shareVerseLimit(int count);

  /// Label above the live reel preview
  ///
  /// In en, this message translates to:
  /// **'Live Reel Preview'**
  String get liveReelPreview;

  /// Title for the full-screen share composer
  ///
  /// In en, this message translates to:
  /// **'Create Share'**
  String get createShare;

  /// Subtitle for the full-screen share composer
  ///
  /// In en, this message translates to:
  /// **'Build a polished Quran share with live preview and simple controls.'**
  String get shareComposerSubtitle;

  /// Title shown when the share asset is prepared
  ///
  /// In en, this message translates to:
  /// **'Ready to Share'**
  String get shareReadyTitle;

  /// Subtitle shown in the review step
  ///
  /// In en, this message translates to:
  /// **'Review the final result, then share it when it feels right.'**
  String get shareReviewSubtitle;

  /// Short label showing content is ready
  ///
  /// In en, this message translates to:
  /// **'Ready to Share'**
  String get readyToShare;

  /// Section title for share mode selection
  ///
  /// In en, this message translates to:
  /// **'Share Format'**
  String get shareMode;

  /// Screenshot share mode label
  ///
  /// In en, this message translates to:
  /// **'Screenshot'**
  String get shareModeScreenshot;

  /// Audio share mode label
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get shareModeAudio;

  /// Reel share mode label
  ///
  /// In en, this message translates to:
  /// **'Reel'**
  String get shareModeReel;

  /// Step indicator label for the configuration step
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get shareStepConfigure;

  /// Step indicator label for the generation step
  ///
  /// In en, this message translates to:
  /// **'Generating'**
  String get shareStepGenerating;

  /// Step indicator label for the review step
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get shareStepReview;

  /// Section title for screenshot layout selection
  ///
  /// In en, this message translates to:
  /// **'Visual Layout'**
  String get shareContentLayout;

  /// Option label for capturing the current reader page
  ///
  /// In en, this message translates to:
  /// **'Reader Page'**
  String get shareLayoutReaderPage;

  /// Option label for generating a stylized passage card
  ///
  /// In en, this message translates to:
  /// **'Passage Card'**
  String get shareLayoutPassageCard;

  /// Hint shown when the reader page screenshot option is selected
  ///
  /// In en, this message translates to:
  /// **'Reader Page uses the current Quran page exactly as shown in the reader.'**
  String get shareReaderPageHint;

  /// Section title for share duration presets
  ///
  /// In en, this message translates to:
  /// **'Clip Duration'**
  String get shareDuration;

  /// Label for automatic clip duration
  ///
  /// In en, this message translates to:
  /// **'Full Range'**
  String get shareDurationAuto;

  /// Label for short clip duration
  ///
  /// In en, this message translates to:
  /// **'30 sec'**
  String get shareDurationShort;

  /// Label for medium clip duration
  ///
  /// In en, this message translates to:
  /// **'60 sec'**
  String get shareDurationMedium;

  /// Label for long clip duration
  ///
  /// In en, this message translates to:
  /// **'90 sec'**
  String get shareDurationLong;

  /// Hint below duration presets
  ///
  /// In en, this message translates to:
  /// **'Duration presets keep the full-ayah flow when timing data is available.'**
  String get shareDurationHint;

  /// Primary action to prepare a screenshot for review
  ///
  /// In en, this message translates to:
  /// **'Prepare Screenshot'**
  String get prepareScreenshot;

  /// Primary action to prepare an audio clip for review
  ///
  /// In en, this message translates to:
  /// **'Prepare Audio Clip'**
  String get prepareAudioClip;

  /// Primary action to prepare a reel for review
  ///
  /// In en, this message translates to:
  /// **'Prepare Reel'**
  String get prepareReel;

  /// Status message while preparing a screenshot
  ///
  /// In en, this message translates to:
  /// **'Preparing screenshot...'**
  String get preparingScreenshot;

  /// Status message while preparing an audio clip
  ///
  /// In en, this message translates to:
  /// **'Preparing audio clip...'**
  String get preparingAudioClip;

  /// Status message while preparing a reel
  ///
  /// In en, this message translates to:
  /// **'Preparing reel...'**
  String get preparingReelStatus;

  /// Status message while generating the audio portion of a reel
  ///
  /// In en, this message translates to:
  /// **'Generating audio clip...'**
  String get generatingAudioClipStatus;

  /// Status message while capturing the Quran reader visuals for a reel
  ///
  /// In en, this message translates to:
  /// **'Capturing reader visuals...'**
  String get capturingReaderVisuals;

  /// Status message while combining reel visuals and audio
  ///
  /// In en, this message translates to:
  /// **'Combining visuals and audio into a reel...'**
  String get combiningReelMedia;

  /// Status message while preparing to trim a locally stored audio file
  ///
  /// In en, this message translates to:
  /// **'Preparing to trim local audio...'**
  String get preparingToTrimLocalAudio;

  /// Status message when the selected reciter cannot be trimmed locally and the app falls back to downloading verses
  ///
  /// In en, this message translates to:
  /// **'Reciter not supported for local trimming. Falling back to online download...'**
  String get reciterNotSupportedForLocalTrim;

  /// Status message while loading verse timing data
  ///
  /// In en, this message translates to:
  /// **'Fetching ayah timings...'**
  String get fetchingAyahTimings;

  /// Status message when no timing data is available and the app falls back to online download
  ///
  /// In en, this message translates to:
  /// **'No timings found. Falling back to online download...'**
  String get noTimingsFound;

  /// Status message when no timing data is available for the chosen verse range
  ///
  /// In en, this message translates to:
  /// **'No timings found for the selected range. Falling back to online download...'**
  String get noTimingsFoundForRange;

  /// Status message while trimming audio
  ///
  /// In en, this message translates to:
  /// **'Trimming audio...'**
  String get trimmingAudio;

  /// Error shown when a generated audio preview file is missing
  ///
  /// In en, this message translates to:
  /// **'Generated audio file was not found.'**
  String get generatedAudioFileNotFound;

  /// Error shown when a generated reel preview file is missing
  ///
  /// In en, this message translates to:
  /// **'Generated reel file was not found.'**
  String get generatedReelFileNotFound;

  /// Status message while downloading verse-by-verse audio
  ///
  /// In en, this message translates to:
  /// **'Downloading verse {currentVerse} of {totalVerses}...'**
  String downloadingVerseProgress(int currentVerse, int totalVerses);

  /// Status message while assembling the final audio clip
  ///
  /// In en, this message translates to:
  /// **'Assembling audio clip...'**
  String get assemblingAudioClip;

  /// Status message while preparing reel video encoding
  ///
  /// In en, this message translates to:
  /// **'Preparing video encoding...'**
  String get preparingVideoEncoding;

  /// Status message while encoding the final vertical reel video
  ///
  /// In en, this message translates to:
  /// **'Encoding vertical video (this may take a moment)...'**
  String get encodingVerticalVideo;

  /// Error message when reel generation fails for a general encoding reason
  ///
  /// In en, this message translates to:
  /// **'Failed to generate reel video. Please try again.'**
  String get reelGenerationFailed;

  /// Error message when captured screenshot frame format is invalid for reel encoding
  ///
  /// In en, this message translates to:
  /// **'Failed to process captured frame data for reel generation. Please retry.'**
  String get reelGenerationFailedInvalidFrame;

  /// Error message when reel generation starts without any screenshot frame
  ///
  /// In en, this message translates to:
  /// **'No captured frame was found for reel generation.'**
  String get reelGenerationFailedMissingScreenshot;

  /// Error message when encoding reports success but the output video file is unusable
  ///
  /// In en, this message translates to:
  /// **'Generated reel output is invalid and could not be opened. Please try again.'**
  String get reelGenerationFailedInvalidOutput;

  /// Shown in review screen when generated video preview initialization fails
  ///
  /// In en, this message translates to:
  /// **'Unable to load generated video preview.'**
  String get reelPreviewLoadFailed;

  /// Status message after the reel has been generated successfully
  ///
  /// In en, this message translates to:
  /// **'Reel generated!'**
  String get reelGenerated;

  /// Title for the final share review panel
  ///
  /// In en, this message translates to:
  /// **'Review Your Share'**
  String get shareReviewTitle;

  /// Review text for a prepared screenshot
  ///
  /// In en, this message translates to:
  /// **'Screenshot is ready to share.'**
  String get shareReviewScreenshot;

  /// Review text for a prepared audio clip
  ///
  /// In en, this message translates to:
  /// **'Audio clip is ready to share.'**
  String get shareReviewAudio;

  /// Review text for a prepared reel
  ///
  /// In en, this message translates to:
  /// **'Reel is ready to share.'**
  String get shareReviewReel;

  /// Label showing the selected duration preset in seconds
  ///
  /// In en, this message translates to:
  /// **'{seconds} sec max'**
  String shareDurationPresetLabel(int seconds);

  /// Button label to go back and edit the share
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Section title for prayer time notification settings
  ///
  /// In en, this message translates to:
  /// **'Prayer Notifications'**
  String get prayerNotifications;

  /// Action label to open prayer alert preferences
  ///
  /// In en, this message translates to:
  /// **'Manage Alerts'**
  String get manageAlerts;

  /// Global toggle label for enabling/disabling all prayer notifications
  ///
  /// In en, this message translates to:
  /// **'All Prayer Notifications'**
  String get prayerNotificationsEnabledAll;

  /// Toggle label for adhan sound playback on prayer notification
  ///
  /// In en, this message translates to:
  /// **'Play Adhan'**
  String get playAdhan;

  /// Label for the 0-minutes-before notification offset option
  ///
  /// In en, this message translates to:
  /// **'At prayer time'**
  String get atPrayerTime;

  /// Banner shown when the Android exact-alarm permission is not granted
  ///
  /// In en, this message translates to:
  /// **'Exact alarm permission required for reliable prayer reminders.'**
  String get exactAlarmPermissionRequired;

  /// Banner shown when the Android POST_NOTIFICATIONS permission is not granted
  ///
  /// In en, this message translates to:
  /// **'Notification permission required to receive prayer alerts.'**
  String get notificationPermissionRequired;

  /// Banner shown when the app is not whitelisted from Doze / battery optimization
  ///
  /// In en, this message translates to:
  /// **'Disable battery optimization to keep prayer reminders on time when the screen is off.'**
  String get batteryOptimizationExemptionRequired;

  /// Informational banner shown on aggressive OEM ROMs (Xiaomi/Oppo/Huawei/Vivo/etc.) where the autostart whitelist must be set manually
  ///
  /// In en, this message translates to:
  /// **'On this device, also enable Autostart for Tilawa in your phone\'s settings so reminders are not stopped in the background.'**
  String get oemAutostartHint;

  /// Body text for prayer time notifications
  ///
  /// In en, this message translates to:
  /// **'It is time for {prayerName}'**
  String prayerNotificationBody(String prayerName);

  /// Android notification channel name for default prayer reminders
  ///
  /// In en, this message translates to:
  /// **'Prayer Times'**
  String get prayerNotificationsChannelName;

  /// Android notification channel description for default prayer reminders
  ///
  /// In en, this message translates to:
  /// **'Reminders for the five daily prayer times'**
  String get prayerNotificationsChannelDescription;

  /// Android notification channel name for prayer reminders with adhan sound
  ///
  /// In en, this message translates to:
  /// **'Prayer Times (Adhan)'**
  String get prayerNotificationsAdhanChannelName;

  /// Android notification channel description for prayer reminders with adhan sound
  ///
  /// In en, this message translates to:
  /// **'Prayer time reminders that play the adhan sound'**
  String get prayerNotificationsAdhanChannelDescription;

  /// Android notification channel name for prayer reminders when adhan is handled natively
  ///
  /// In en, this message translates to:
  /// **'Prayer Times (Silent)'**
  String get prayerNotificationsSilentAdhanChannelName;

  /// Android notification channel description for prayer reminders when adhan is handled natively
  ///
  /// In en, this message translates to:
  /// **'Silent prayer time reminders when Adhan plays natively'**
  String get prayerNotificationsSilentAdhanChannelDescription;

  /// Text showing that Adhan audio is currently playing
  ///
  /// In en, this message translates to:
  /// **'Adhan is playing'**
  String get adhanIsPlaying;

  /// Button label to stop Adhan playback
  ///
  /// In en, this message translates to:
  /// **'Stop Adhan'**
  String get stopAdhan;

  /// Status text when a prayer notification is opened
  ///
  /// In en, this message translates to:
  /// **'Prayer notification received'**
  String get prayerNotificationReceived;

  /// Button label to navigate to the full prayer times screen
  ///
  /// In en, this message translates to:
  /// **'View All Prayer Times'**
  String get viewAllPrayerTimes;

  /// Label showing a prayer time
  ///
  /// In en, this message translates to:
  /// **'at {time}'**
  String prayerTimeAt(String time);

  /// Prayer alert mode label when notification and Adhan are disabled
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get prayerAlertModeOff;

  /// Prayer alert mode label when notification is enabled without Adhan
  ///
  /// In en, this message translates to:
  /// **'Notify only'**
  String get prayerAlertModeNotifyOnly;

  /// Prayer alert mode label when notification and Adhan are enabled
  ///
  /// In en, this message translates to:
  /// **'Adhan'**
  String get prayerAlertModeAdhan;

  /// Description for disabled prayer alert mode
  ///
  /// In en, this message translates to:
  /// **'No notification or Adhan for this prayer.'**
  String get prayerAlertModeOffDescription;

  /// Description for notification-only prayer alert mode
  ///
  /// In en, this message translates to:
  /// **'Show a prayer-time notification without Adhan.'**
  String get prayerAlertModeNotifyOnlyDescription;

  /// Description for Adhan prayer alert mode
  ///
  /// In en, this message translates to:
  /// **'Show a notification and play the Adhan.'**
  String get prayerAlertModeAdhanDescription;

  /// Label for notification status
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notificationStatus;

  /// Label for Adhan status
  ///
  /// In en, this message translates to:
  /// **'Adhan'**
  String get adhanStatus;

  /// Status text for received notification
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get received;

  /// Label for audio sound
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// Generic enabled status
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// Generic disabled status
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// Error message when notification data is missing
  ///
  /// In en, this message translates to:
  /// **'Missing notification payload.'**
  String get errorMissingNotificationPayload;

  /// Error message when notification data is corrupted or invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid notification payload.'**
  String get errorInvalidNotificationPayload;

  /// Label for the more-options overflow menu button
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// Support Tilawa screen and settings entry title
  ///
  /// In en, this message translates to:
  /// **'Support Tilawa'**
  String get supportTilawa;

  /// Support screen single-line intro under app bar
  ///
  /// In en, this message translates to:
  /// **'Your contribution helps keep Tilawa going.'**
  String get supportIntroLine;

  /// Legacy alias; prefer supportIntroLine
  ///
  /// In en, this message translates to:
  /// **'Your contribution helps keep Tilawa going.'**
  String get supportTilawaSubtitle;

  /// Legacy alias; unused on support screen
  ///
  /// In en, this message translates to:
  /// **'Your contribution helps keep Tilawa going.'**
  String get supportMissionBody;

  /// Collapsible impact section title on support screen
  ///
  /// In en, this message translates to:
  /// **'Why?'**
  String get supportImpactWhyTitle;

  /// Legacy impact section title
  ///
  /// In en, this message translates to:
  /// **'Where your contribution goes'**
  String get supportImpactTitle;

  /// Support impact bullet — Mushaf and audio
  ///
  /// In en, this message translates to:
  /// **'Mushaf and recitation audio'**
  String get supportImpactQuranHosting;

  /// Legacy alias; merged into supportImpactQuranHosting
  ///
  /// In en, this message translates to:
  /// **'Mushaf and recitation audio'**
  String get supportImpactReciterAudio;

  /// Support impact bullet
  ///
  /// In en, this message translates to:
  /// **'Prayer times and tools'**
  String get supportImpactPrayerTools;

  /// Support impact bullet
  ///
  /// In en, this message translates to:
  /// **'Operations and development'**
  String get supportImpactDevelopment;

  /// Legacy alias; unused on support screen
  ///
  /// In en, this message translates to:
  /// **'Operations and development'**
  String get supportImpactAdFree;

  /// Smallest one-time support tier label
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get supportTierSmall;

  /// Middle one-time support tier label
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get supportTierKind;

  /// Largest one-time support tier label
  ///
  /// In en, this message translates to:
  /// **'Generous'**
  String get supportTierGenerous;

  /// Primary support purchase CTA
  ///
  /// In en, this message translates to:
  /// **'Continue on Google Play'**
  String get supportContinueWithPlay;

  /// Support purchase confirmation sheet title
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get supportConfirmationTitle;

  /// Support purchase confirmation sheet body
  ///
  /// In en, this message translates to:
  /// **'Payment via Google Play. Tilawa does not store your card details.'**
  String get supportConfirmationBody;

  /// Support confirmation sheet confirm button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get supportConfirm;

  /// Support confirmation sheet cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get supportCancel;

  /// Support thank-you state title
  ///
  /// In en, this message translates to:
  /// **'Thank you'**
  String get supportThankYouTitle;

  /// Support thank-you state body
  ///
  /// In en, this message translates to:
  /// **'Your contribution went through. We appreciate your trust.'**
  String get supportThankYouBody;

  /// Support thank-you dismiss button
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get supportDone;

  /// Restore purchases action
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get supportRestorePurchases;

  /// Legacy restore helper; unused on support screen
  ///
  /// In en, this message translates to:
  /// **'If a payment did not finish, tap Restore.'**
  String get supportRestoreHint;

  /// Support trust line before charities link label
  ///
  /// In en, this message translates to:
  /// **'Payment via Google Play · Part of your contribution goes to Tilawa Tech Organization and charities ('**
  String get supportTrustLinePrefix;

  /// Tappable label for partner charities list URL
  ///
  /// In en, this message translates to:
  /// **'partner charities list'**
  String get supportCharitiesLinkLabel;

  /// Bottom sheet title listing partner charity links
  ///
  /// In en, this message translates to:
  /// **'Partner charities'**
  String get supportCharitiesSheetTitle;

  /// Partner charity — Dar Al-Arqam Quran center
  ///
  /// In en, this message translates to:
  /// **'Dar Al-Arqam Quran Center'**
  String get supportCharityDarAlArqam;

  /// Partner charity — Al-Islah Charitable Foundation
  ///
  /// In en, this message translates to:
  /// **'Al-Islah Charitable Foundation'**
  String get supportCharityIslaheg;

  /// Support trust line after charities link label
  ///
  /// In en, this message translates to:
  /// **')'**
  String get supportTrustLineSuffix;

  /// Full trust line for legacy use; UI uses prefix/link/suffix
  ///
  /// In en, this message translates to:
  /// **'Payment via Google Play · Part of your contribution goes to Tilawa Tech Organization and charities (partner charities list)'**
  String get supportTrustLine;

  /// Legacy alias; prefer supportTrustLinePrefix + link + suffix
  ///
  /// In en, this message translates to:
  /// **'Payment via Google Play · Part of your contribution goes to Tilawa Tech Organization and charities (partner charities list)'**
  String get supportPlayFooter;

  /// Legacy alias; prefer supportTrustLinePrefix + link + suffix
  ///
  /// In en, this message translates to:
  /// **'Payment via Google Play · Part of your contribution goes to Tilawa Tech Organization and charities (partner charities list)'**
  String get supportDisclaimer;

  /// Offline message on support screen
  ///
  /// In en, this message translates to:
  /// **'An internet connection is required.'**
  String get supportOfflineMessage;

  /// Billing unavailable error
  ///
  /// In en, this message translates to:
  /// **'Google Play payment is not available on this device.'**
  String get supportBillingUnavailable;

  /// Products query failed error
  ///
  /// In en, this message translates to:
  /// **'Options are unavailable right now. Try again later.'**
  String get supportProductsUnavailable;

  /// Pending purchase message
  ///
  /// In en, this message translates to:
  /// **'Processing in Google Play.'**
  String get supportPurchasePending;

  /// Verification failed message
  ///
  /// In en, this message translates to:
  /// **'Could not confirm yet. Try again later.'**
  String get supportPurchaseVerifyFailed;

  /// Restore found nothing message
  ///
  /// In en, this message translates to:
  /// **'No previous payment found for this account.'**
  String get supportRestoreNothingFound;

  /// Restore completed message
  ///
  /// In en, this message translates to:
  /// **'Restore complete.'**
  String get supportRestoreComplete;

  /// Prompt when no tier selected
  ///
  /// In en, this message translates to:
  /// **'Choose an amount'**
  String get supportSelectTier;

  /// Settings group title for support entry
  ///
  /// In en, this message translates to:
  /// **'Support Tilawa'**
  String get supportSettingsGroupTitle;

  /// Settings support tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get supportHelpKeepFree;

  /// Localized purchase billing unavailable failure
  ///
  /// In en, this message translates to:
  /// **'Payment is not available right now.'**
  String get purchaseBillingUnavailable;

  /// Localized purchase product not found failure
  ///
  /// In en, this message translates to:
  /// **'This option is not available.'**
  String get purchaseProductNotFound;

  /// Localized purchase verification failed failure
  ///
  /// In en, this message translates to:
  /// **'Could not confirm. Try again later.'**
  String get purchaseVerificationFailed;

  /// Localized purchase pending failure
  ///
  /// In en, this message translates to:
  /// **'Still processing.'**
  String get purchasePending;

  /// Localized purchase already owned failure
  ///
  /// In en, this message translates to:
  /// **'This contribution was already completed.'**
  String get purchaseAlreadyOwned;

  /// In-app review API unavailable (simulator, old OS, etc.)
  ///
  /// In en, this message translates to:
  /// **'Reviews are not available on this device right now.'**
  String get appReviewUnavailable;

  /// In-app review request failed
  ///
  /// In en, this message translates to:
  /// **'We could not open the review dialog. Please try again.'**
  String get appReviewRequestFailed;

  /// Store listing fallback failed
  ///
  /// In en, this message translates to:
  /// **'We could not open the app store. Please try again.'**
  String get appReviewStoreListingFailed;

  /// In-app review not supported (e.g. web)
  ///
  /// In en, this message translates to:
  /// **'Store reviews are not supported on this platform.'**
  String get appReviewPlatformUnsupported;
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

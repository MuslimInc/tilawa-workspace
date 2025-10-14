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

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Muzakri'**
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
  String downloadingSurah(String surahTitle, String reciterName);

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
  /// **'surahs'**
  String get surahs;
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

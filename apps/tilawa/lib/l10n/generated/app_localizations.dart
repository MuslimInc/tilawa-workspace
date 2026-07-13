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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
  /// **'MeMuslim'**
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

  /// Home dashboard title
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// Default Home greeting
  ///
  /// In en, this message translates to:
  /// **'Assalamu alaikum'**
  String get homeGreeting;

  /// Title for the daily inspiration section
  ///
  /// In en, this message translates to:
  /// **'Today\'s inspiration'**
  String get homeInspirationTitle;

  /// Subtitle for the daily inspiration section
  ///
  /// In en, this message translates to:
  /// **'An ayah and dua for your heart'**
  String get homeInspirationSubtitle;

  /// Home greeting with display name
  ///
  /// In en, this message translates to:
  /// **'Assalamu alaikum, {name}'**
  String homeGreetingName(String name);

  /// Accessibility label for the Home profile mark
  ///
  /// In en, this message translates to:
  /// **'User profile'**
  String get homeProfileLabel;

  /// Fallback Home location chip text when prayer location is not available
  ///
  /// In en, this message translates to:
  /// **'Set location'**
  String get homeLocationUnavailable;

  /// Talabat-style context label above the prayer location in the Home hero header
  ///
  /// In en, this message translates to:
  /// **'Praying in'**
  String get homeHeroLocationContext;

  /// Home next prayer fallback when no prayer time can be calculated
  ///
  /// In en, this message translates to:
  /// **'Set your location to see the next prayer time.'**
  String get homeNextPrayerUnavailable;

  /// Action to open prayer times from Home
  ///
  /// In en, this message translates to:
  /// **'Prayer times'**
  String get homePrayerTimesAction;

  /// Home countdown when the next salah adhan is due now (five daily prayers only)
  ///
  /// In en, this message translates to:
  /// **'It\'s prayer time'**
  String get homePrayerNow;

  /// Home countdown when sunrise (Shurooq) is due now
  ///
  /// In en, this message translates to:
  /// **'Sunrise time now'**
  String get homeSunriseNow;

  /// Home countdown when Duha time is due now
  ///
  /// In en, this message translates to:
  /// **'Duha time now'**
  String get homeDuhaNow;

  /// Home next-prayer countdown under one hour
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{In 1 minute} other{In {minutes} minutes}}'**
  String homePrayerInMinutes(int minutes);

  /// Home next-prayer countdown with hours and minutes
  ///
  /// In en, this message translates to:
  /// **'In {hours}h {minutes}m'**
  String homePrayerInHoursMinutes(int hours, int minutes);

  /// Home section title for secondary destinations that are not bottom-nav tabs
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get homeExploreTitle;

  /// Home feature category grid supporting line
  ///
  /// In en, this message translates to:
  /// **'Everyday tools at a glance'**
  String get homeExploreSubtitle;

  /// Home carousel subtitle for Smart Khatma promo card
  ///
  /// In en, this message translates to:
  /// **'Progress on your khatma'**
  String get homeKhatmaCarouselSubtitle;

  /// Home carousel subtitle for Support Tilawa promo card
  ///
  /// In en, this message translates to:
  /// **'Help keep Tilawa free for everyone'**
  String get homeSupportCarouselSubtitle;

  /// Home carousel subtitle for listening history card
  ///
  /// In en, this message translates to:
  /// **'Continue where you left off'**
  String get homeHistoryCarouselSubtitle;

  /// Home carousel subtitle for favorites card
  ///
  /// In en, this message translates to:
  /// **'Your saved recitations'**
  String get homeFavoritesCarouselSubtitle;

  /// Home carousel subtitle for downloads card
  ///
  /// In en, this message translates to:
  /// **'Listen offline'**
  String get homeDownloadsCarouselSubtitle;

  /// Home card title for Quran teaching sessions
  ///
  /// In en, this message translates to:
  /// **'Learn recitation'**
  String get homeSessionsTitle;

  /// Home card subtitle for Quran teaching sessions
  ///
  /// In en, this message translates to:
  /// **'One-on-one sessions with a certified hafiz'**
  String get homeSessionsSubtitle;

  /// Home dashboard layout toggle tooltip when grid is active
  ///
  /// In en, this message translates to:
  /// **'Show as list'**
  String get homeExploreShowAsList;

  /// Home dashboard layout toggle tooltip when list is active
  ///
  /// In en, this message translates to:
  /// **'Show as grid'**
  String get homeExploreShowAsGrid;

  /// Home hero message when dashboard data fails to load
  ///
  /// In en, this message translates to:
  /// **'Could not load prayer times. Check your connection and try again.'**
  String get homeDashboardLoadError;

  /// Home hero message when the initial dashboard load fails offline without cache
  ///
  /// In en, this message translates to:
  /// **'You\'re offline and we don\'t have saved prayer times yet. Reconnect and try again.'**
  String get homeDashboardOfflineError;

  /// Snack bar when Home pull-to-refresh fails due to no internet
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Showing your last saved data.'**
  String get homeRefreshOfflineMessage;

  /// Snack bar when Home pull-to-refresh fails for a non-network reason
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh. Your last saved data is still shown.'**
  String get homeRefreshFailedMessage;

  /// Read-only Home search field hint; opens Quran index
  ///
  /// In en, this message translates to:
  /// **'Search surahs, juz, or page'**
  String get homeSearchHint;

  /// Home horizontal carousel section title (travel-app popular row)
  ///
  /// In en, this message translates to:
  /// **'Featured for you'**
  String get homeFeaturedTitle;

  /// Home featured carousel section subtitle
  ///
  /// In en, this message translates to:
  /// **'More for your day'**
  String get homeFeaturedSubtitle;

  /// Home section title for daily actions
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeTodayTitle;

  /// Home section title for personalized resume content
  ///
  /// In en, this message translates to:
  /// **'Yours'**
  String get homeYoursTitle;

  /// Home continue listening row subtitle
  ///
  /// In en, this message translates to:
  /// **'{reciter} · {surah}'**
  String homeListeningResumeSubtitle(String reciter, String surah);

  /// Athkar compact card completed state
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get homeAthkarDone;

  /// Athkar compact card in-progress state
  ///
  /// In en, this message translates to:
  /// **'{count} remaining'**
  String homeAthkarRemaining(int count);

  /// Athkar compact card untouched state
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get homeAthkarNotStarted;

  /// Quran progress card streak label
  ///
  /// In en, this message translates to:
  /// **'Day {days} streak'**
  String homeQuranStreakDays(int days);

  /// Quran progress card daily goal label
  ///
  /// In en, this message translates to:
  /// **'{percent}% of today\'s goal'**
  String homeQuranGoalProgress(int percent);

  /// Daily ayah sheet bookmark action
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get homeDailyAyahBookmark;

  /// Daily ayah sheet share action
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get homeDailyAyahShare;

  /// Home Today section supporting line
  ///
  /// In en, this message translates to:
  /// **'Prayer, Quran, and dhikr for your day'**
  String get homeTodaySubtitle;

  /// Home section title for resuming Quran — mirrors Spotify Jump back in
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get homeContinueTitle;

  /// Home section title for pinned athkar rituals
  ///
  /// In en, this message translates to:
  /// **'Daily Practice'**
  String get homeDailyPracticeTitle;

  /// Home Daily Practice section supporting line
  ///
  /// In en, this message translates to:
  /// **'Your pinned adhkar and supplications'**
  String get homeDailyPracticeSubtitle;

  /// Home section title for the primary morning/evening athkar card
  ///
  /// In en, this message translates to:
  /// **'Daily habit'**
  String get homeDailyHabitTitle;

  /// Home daily habit section supporting line
  ///
  /// In en, this message translates to:
  /// **'Start or continue your routine'**
  String get homeDailyHabitSubtitle;

  /// Home subsection title for pinned athkar shortcuts
  ///
  /// In en, this message translates to:
  /// **'Quick athkar'**
  String get homeAthkarRitualsTitle;

  /// Home compact prayer schedule strip title
  ///
  /// In en, this message translates to:
  /// **'Today\'s prayer times'**
  String get homePrayerStripTitle;

  /// Home prayer strip link to Prayer tab
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get homePrayerStripViewAll;

  /// Home featured ritual card action hint
  ///
  /// In en, this message translates to:
  /// **'Tap to begin'**
  String get homeFeaturedRitualStart;

  /// Home Quran card title for first-time readers
  ///
  /// In en, this message translates to:
  /// **'Open the Mushaf'**
  String get homeStartQuranTitle;

  /// Home Quran card subtitle for first-time readers
  ///
  /// In en, this message translates to:
  /// **'Begin reading the Quran today'**
  String get homeStartQuranSubtitle;

  /// Home Today row title for opening the last-read Quran page
  ///
  /// In en, this message translates to:
  /// **'Continue Quran'**
  String get homeContinueQuranTitle;

  /// Home Today row subtitle for opening the last-read Quran page
  ///
  /// In en, this message translates to:
  /// **'Resume from your last read page'**
  String get homeContinueQuranSubtitle;

  /// Home Quran resume subtitle with surah and page
  ///
  /// In en, this message translates to:
  /// **'{surah} · page {page}'**
  String homeQuranResumeSurahPage(String surah, int page);

  /// Home Quran resume subtitle with page only
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String homeQuranResumePage(int page);

  /// Home Quran resume progress label
  ///
  /// In en, this message translates to:
  /// **'{percent}% of the Mushaf'**
  String homeQuranResumeProgress(int percent);

  /// Home contextual athkar banner prompt
  ///
  /// In en, this message translates to:
  /// **'A good moment for {name}'**
  String homeContextualAthkarPrompt(String name);

  /// Badge on time-relevant athkar shortcut
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get homeAthkarNowBadge;

  /// Label for the experimental feature badge, shown on features that are in testing or preview
  ///
  /// In en, this message translates to:
  /// **'Experimental'**
  String get experimentalBadgeLabel;

  /// Home quick action for Quran reader
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get homeQuickQuran;

  /// Home section title for the high-frequency 2x2 action grid
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get homeQuickActionsTitle;

  /// Home section title for the two primary daily action cards
  ///
  /// In en, this message translates to:
  /// **'Your daily worship'**
  String get homeMainActionsTitle;

  /// Home section title for the compact secondary tools row
  ///
  /// In en, this message translates to:
  /// **'Quick tools'**
  String get homeQuickToolsTitle;

  /// Title of the persistent Learn Quran entry card for interested students
  ///
  /// In en, this message translates to:
  /// **'Learn Quran'**
  String get homeLearningBrowseTitle;

  /// Subtitle of the persistent Learn Quran entry card for interested students
  ///
  /// In en, this message translates to:
  /// **'Choose your hafiz and book a live 1-on-1 session.'**
  String get homeLearningBrowseSubtitle;

  /// Call to action on the persistent Learn Quran entry card
  ///
  /// In en, this message translates to:
  /// **'Start learning'**
  String get homeLearningBrowseCta;

  /// Title of the tutoring interest card shown on home screen
  ///
  /// In en, this message translates to:
  /// **'Learn Quran with a Qualified Tutor?'**
  String get homeLearningInterestPromptTitle;

  /// Subtitle of the tutoring interest card shown on home screen
  ///
  /// In en, this message translates to:
  /// **'Master your recitation and Tajweed 1-on-1 with live feedback.'**
  String get homeLearningInterestPromptSubtitle;

  /// Button to accept tutoring interest
  ///
  /// In en, this message translates to:
  /// **'Yes, interested'**
  String get homeLearningInterestPromptYes;

  /// Button to dismiss tutoring interest
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get homeLearningInterestPromptNo;

  /// Title of next session card on home screen
  ///
  /// In en, this message translates to:
  /// **'Next Quran Session'**
  String get homeLearningNextSessionTitle;

  /// Countdown to next session on home screen
  ///
  /// In en, this message translates to:
  /// **'Starts in {minutes}m'**
  String homeLearningNextSessionStartsIn(int minutes);

  /// Indicator when next session is live
  ///
  /// In en, this message translates to:
  /// **'Live now'**
  String get homeLearningNextSessionLive;

  /// Title of pending booking card on home screen
  ///
  /// In en, this message translates to:
  /// **'Pending Tutor Booking'**
  String get homeLearningPendingBookingTitle;

  /// Status text for pending approval booking on home screen
  ///
  /// In en, this message translates to:
  /// **'Awaiting tutor approval'**
  String get homeLearningPendingBookingApproval;

  /// Status text for pending payment booking on home screen
  ///
  /// In en, this message translates to:
  /// **'Awaiting payment'**
  String get homeLearningPendingBookingPayment;

  /// Title of the revision card on home screen
  ///
  /// In en, this message translates to:
  /// **'Continue Learning'**
  String get homeLearningRevisionTitle;

  /// Settings tile title for experienced Quran teacher application
  ///
  /// In en, this message translates to:
  /// **'Apply as a Quran teacher'**
  String get settingsTeacherApplicationEntryTitle;

  /// Settings tile subtitle for teacher application entry
  ///
  /// In en, this message translates to:
  /// **'If you are a hafiz or have experience teaching the Quran, you can submit your application for review.'**
  String get settingsTeacherApplicationEntrySubtitle;

  /// CTA to open the external Google Form teacher application
  ///
  /// In en, this message translates to:
  /// **'Open application form'**
  String get teacherApplicationOpenFormCta;

  /// Title on teacher application bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Are you a hafiz or Quran teacher?'**
  String get teacherApplicationSheetTitle;

  /// Body copy on teacher application bottom sheet
  ///
  /// In en, this message translates to:
  /// **'We are now accepting applications from experienced hafiz and Quran teachers to participate in the Learn Quran feature inside the app. You can fill out the application form, and our team will review it before enabling any permissions.'**
  String get teacherApplicationSheetBody;

  /// Secondary dismiss action on teacher application bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get teacherApplicationLaterCta;

  /// Error when external teacher application form fails to open
  ///
  /// In en, this message translates to:
  /// **'Could not open the application form. Please try again.'**
  String get teacherApplicationFormOpenFailed;

  /// Home quick action tile label for opening the Mushaf reader
  ///
  /// In en, this message translates to:
  /// **'Mushaf'**
  String get homeQuickQuranReader;

  /// Subtitle for the Quran Reader primary action card
  ///
  /// In en, this message translates to:
  /// **'Read the Quran with reflection'**
  String get homeQuickQuranReaderSubtitle;

  /// Home quick action for Quran teaching sessions with a hafiz
  ///
  /// In en, this message translates to:
  /// **'Learn Quran with your hafiz'**
  String get homeLearnQuranWithTutor;

  /// Home quick action for reciters catalog
  ///
  /// In en, this message translates to:
  /// **'Reciters'**
  String get homeQuickReciters;

  /// Home More row subtitle for reciters
  ///
  /// In en, this message translates to:
  /// **'Listen to curated recitations'**
  String get homeQuickRecitersSubtitle;

  /// Home quick action for prayer times
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get homeQuickPrayer;

  /// Home quick action for qibla
  ///
  /// In en, this message translates to:
  /// **'Qibla'**
  String get homeQuickQibla;

  /// Home More row subtitle for qibla
  ///
  /// In en, this message translates to:
  /// **'Find the Qibla with ease'**
  String get homeQuickQiblaSubtitle;

  /// Home More row subtitle for settings
  ///
  /// In en, this message translates to:
  /// **'Theme, audio, and account'**
  String get homeQuickSettingsSubtitle;

  /// Home More row title for tasbeeh counter
  ///
  /// In en, this message translates to:
  /// **'Tasbih'**
  String get homeQuickTasbeeh;

  /// Home More row subtitle for tasbeeh counter
  ///
  /// In en, this message translates to:
  /// **'Dhikr at your fingertips'**
  String get homeQuickTasbeehSubtitle;

  /// Home quick action for athkar
  ///
  /// In en, this message translates to:
  /// **'Athkar'**
  String get homeQuickAthkar;

  /// Subtitle for the Athkar primary action card
  ///
  /// In en, this message translates to:
  /// **'Your daily athkar'**
  String get homeQuickAthkarSubtitle;

  /// Home quick action for settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeQuickSettings;

  /// Home section title for user-selected athkar shortcuts
  ///
  /// In en, this message translates to:
  /// **'Quick athkar'**
  String get homePinnedAthkarTitle;

  /// Action label for editing Home athkar shortcuts
  ///
  /// In en, this message translates to:
  /// **'Edit athkar shortcuts'**
  String get homePinnedAthkarEdit;

  /// CTA for choosing Home athkar shortcuts
  ///
  /// In en, this message translates to:
  /// **'Choose athkar'**
  String get homePinnedAthkarChoose;

  /// Empty state title when no athkar shortcuts are pinned
  ///
  /// In en, this message translates to:
  /// **'Choose your daily athkar'**
  String get homePinnedAthkarEmptyTitle;

  /// Empty state body for Home athkar shortcuts
  ///
  /// In en, this message translates to:
  /// **'Pin up to four categories for one-tap access from Home.'**
  String get homePinnedAthkarEmptyBody;

  /// Bottom sheet title for choosing Home athkar shortcuts
  ///
  /// In en, this message translates to:
  /// **'Choose quick athkar'**
  String get homePinnedAthkarPickerTitle;

  /// Selection count in the Home athkar shortcut picker
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} shortcuts selected'**
  String homePinnedAthkarPickerLimit(int count, int max);

  /// Tooltip for moving an athkar shortcut earlier
  ///
  /// In en, this message translates to:
  /// **'Move {name} up'**
  String homePinnedAthkarMoveUp(String name);

  /// Tooltip for moving an athkar shortcut later
  ///
  /// In en, this message translates to:
  /// **'Move {name} down'**
  String homePinnedAthkarMoveDown(String name);

  /// Home section title for daily ayah and dua
  ///
  /// In en, this message translates to:
  /// **'Daily inspiration'**
  String get homeDailyInspirationTitle;

  /// Home section subtitle under daily inspiration title
  ///
  /// In en, this message translates to:
  /// **'A verse and supplication for your day'**
  String get homeDailyInspirationSubtitle;

  /// Home daily ayah card label
  ///
  /// In en, this message translates to:
  /// **'Ayah of the day'**
  String get homeDailyAyahLabel;

  /// Home daily ayah body
  ///
  /// In en, this message translates to:
  /// **'And establish prayer and give zakah and bow with those who bow.'**
  String get homeDailyAyahBody;

  /// Home daily ayah reference
  ///
  /// In en, this message translates to:
  /// **'Quran 2:43'**
  String get homeDailyAyahReference;

  /// Home daily dua card label
  ///
  /// In en, this message translates to:
  /// **'Dua of the day'**
  String get homeDailyDuaLabel;

  /// Home daily dua body
  ///
  /// In en, this message translates to:
  /// **'O Allah, help me remember You, thank You, and worship You well.'**
  String get homeDailyDuaBody;

  /// Home daily dua reference
  ///
  /// In en, this message translates to:
  /// **'Abu Dawud'**
  String get homeDailyDuaReference;

  /// Home daily ayah body variant 1
  ///
  /// In en, this message translates to:
  /// **'So remember Me; I will remember you. And be grateful to Me and do not deny Me.'**
  String get homeDailyAyahBody1;

  /// Home daily ayah reference variant 1
  ///
  /// In en, this message translates to:
  /// **'Quran 2:152'**
  String get homeDailyAyahReference1;

  /// Home daily dua body variant 1
  ///
  /// In en, this message translates to:
  /// **'Our Lord, grant us good in this world and good in the Hereafter, and protect us from the Fire.'**
  String get homeDailyDuaBody1;

  /// Home daily dua reference variant 1
  ///
  /// In en, this message translates to:
  /// **'Quran 2:201'**
  String get homeDailyDuaReference1;

  /// Home daily ayah body variant 2
  ///
  /// In en, this message translates to:
  /// **'Indeed, prayer prohibits immorality and wrongdoing.'**
  String get homeDailyAyahBody2;

  /// Home daily ayah reference variant 2
  ///
  /// In en, this message translates to:
  /// **'Quran 29:45'**
  String get homeDailyAyahReference2;

  /// Home daily dua body variant 2
  ///
  /// In en, this message translates to:
  /// **'O Allah, I ask You for beneficial knowledge, wholesome provision, and accepted deeds.'**
  String get homeDailyDuaBody2;

  /// Home daily dua reference variant 2
  ///
  /// In en, this message translates to:
  /// **'Ibn Majah'**
  String get homeDailyDuaReference2;

  /// Title for the empty Smart Khatma card
  ///
  /// In en, this message translates to:
  /// **'Start a Khatma'**
  String get khatmaEmptyTitle;

  /// Subtitle for the empty Smart Khatma card
  ///
  /// In en, this message translates to:
  /// **'Choose a calm reading plan. We will adjust gently when life gets busy.'**
  String get khatmaEmptySubtitle;

  /// Duration preset label for Smart Khatma
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}}'**
  String khatmaDurationDays(int days);

  /// Title for active Smart Khatma dashboard card
  ///
  /// In en, this message translates to:
  /// **'Khatma Progress'**
  String get khatmaProgressTitle;

  /// Current day summary for Smart Khatma
  ///
  /// In en, this message translates to:
  /// **'Day {currentDay} of {totalDays}'**
  String khatmaProgressSubtitle(int currentDay, int totalDays);

  /// Progress metric label for Smart Khatma
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get khatmaProgressPercent;

  /// Today target metric label for Smart Khatma
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get khatmaTodayGoal;

  /// Remaining days metric label for Smart Khatma
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get khatmaRemaining;

  /// Short page count for Smart Khatma
  ///
  /// In en, this message translates to:
  /// **'{pages, plural, =1{1 page} other{{pages} pages}}'**
  String khatmaPagesShort(int pages);

  /// Short day count for Smart Khatma
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}}'**
  String khatmaDaysShort(int days);

  /// Calm Smart Khatma recovery message
  ///
  /// In en, this message translates to:
  /// **'We adjusted your plan gently for today.'**
  String get khatmaAdjustedPlan;

  /// Resume-page line for Smart Khatma
  ///
  /// In en, this message translates to:
  /// **'Continue from page {page}'**
  String khatmaContinueFromPage(int page);

  /// Remaining page metric label for Smart Khatma
  ///
  /// In en, this message translates to:
  /// **'Pages left'**
  String get khatmaRemainingPages;

  /// Action for keeping the current Khatma end date
  ///
  /// In en, this message translates to:
  /// **'Catch up today'**
  String get khatmaCatchUpAction;

  /// Action for extending the current Khatma plan
  ///
  /// In en, this message translates to:
  /// **'Extend plan'**
  String get khatmaExtendAction;

  /// Action for resetting the active Khatma plan
  ///
  /// In en, this message translates to:
  /// **'Reset plan'**
  String get khatmaResetAction;

  /// Confirmation dialog title for resetting Smart Khatma
  ///
  /// In en, this message translates to:
  /// **'Reset Khatma plan?'**
  String get khatmaResetTitle;

  /// Confirmation dialog message for resetting Smart Khatma
  ///
  /// In en, this message translates to:
  /// **'This clears your current Khatma plan. Your last-read Quran page and bookmarks stay saved.'**
  String get khatmaResetMessage;

  /// Continue reading action for Smart Khatma
  ///
  /// In en, this message translates to:
  /// **'Continue Reading'**
  String get khatmaContinueReading;

  /// Screen title for the Smart Khatma hub
  ///
  /// In en, this message translates to:
  /// **'Smart Khatma'**
  String get khatmaHubTitle;

  /// Home dashboard affordance to open the Smart Khatma hub
  ///
  /// In en, this message translates to:
  /// **'View plan'**
  String get khatmaHomeViewPlan;

  /// Subtitle for the reset-plan row on the Smart Khatma hub
  ///
  /// In en, this message translates to:
  /// **'Clear the current plan. Your bookmarks stay saved.'**
  String get khatmaHubResetSubtitle;

  /// No description provided for @khatmaCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Khatma complete'**
  String get khatmaCompletedTitle;

  /// No description provided for @khatmaProgressCompleteMetric.
  ///
  /// In en, this message translates to:
  /// **'100%'**
  String get khatmaProgressCompleteMetric;

  /// No description provided for @khatmaCompletedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'May Allah accept it. Begin another plan whenever you are ready.'**
  String get khatmaCompletedSubtitle;

  /// No description provided for @khatmaStartAnotherAction.
  ///
  /// In en, this message translates to:
  /// **'Start another Khatma'**
  String get khatmaStartAnotherAction;

  /// No description provided for @khatmaUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Your Khatma plan is temporarily unavailable. Try again.'**
  String get khatmaUnavailable;

  /// No description provided for @khatmaStartFromBeginning.
  ///
  /// In en, this message translates to:
  /// **'From the beginning'**
  String get khatmaStartFromBeginning;

  /// No description provided for @khatmaContinueCurrentPosition.
  ///
  /// In en, this message translates to:
  /// **'From my current Quran page'**
  String get khatmaContinueCurrentPosition;

  /// No description provided for @khatmaReviewPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Review your Khatma plan'**
  String get khatmaReviewPlanTitle;

  /// No description provided for @khatmaRangePages.
  ///
  /// In en, this message translates to:
  /// **'Pages {startPage}–{endPage}'**
  String khatmaRangePages(int startPage, int endPage);

  /// No description provided for @khatmaDailyPages.
  ///
  /// In en, this message translates to:
  /// **'{pages} pages each day'**
  String khatmaDailyPages(int pages);

  /// No description provided for @khatmaStartPage.
  ///
  /// In en, this message translates to:
  /// **'Starts at page {page}'**
  String khatmaStartPage(int page);

  /// No description provided for @khatmaTargetPage.
  ///
  /// In en, this message translates to:
  /// **'Finishes at page {page}'**
  String khatmaTargetPage(int page);

  /// No description provided for @khatmaExpectedCompletionDate.
  ///
  /// In en, this message translates to:
  /// **'Expected completion: {date}'**
  String khatmaExpectedCompletionDate(String date);

  /// No description provided for @khatmaConfirmPlanAction.
  ///
  /// In en, this message translates to:
  /// **'Start this Khatma'**
  String get khatmaConfirmPlanAction;

  /// No description provided for @khatmaStartTodayAction.
  ///
  /// In en, this message translates to:
  /// **'Start today’s Wird'**
  String get khatmaStartTodayAction;

  /// No description provided for @khatmaResumeTodayAction.
  ///
  /// In en, this message translates to:
  /// **'Resume today’s Wird'**
  String get khatmaResumeTodayAction;

  /// No description provided for @khatmaTodayCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Today’s Wird is complete'**
  String get khatmaTodayCompletedTitle;

  /// No description provided for @khatmaTodayCompletedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your next assignment will be ready tomorrow.'**
  String get khatmaTodayCompletedSubtitle;

  /// No description provided for @khatmaConfirmedAndRemaining.
  ///
  /// In en, this message translates to:
  /// **'{confirmed} confirmed · {remaining} remaining'**
  String khatmaConfirmedAndRemaining(int confirmed, int remaining);

  /// No description provided for @khatmaSaveProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Save your Khatma progress'**
  String get khatmaSaveProgressTitle;

  /// No description provided for @khatmaCompletedThroughPage.
  ///
  /// In en, this message translates to:
  /// **'I completed through page {page}'**
  String khatmaCompletedThroughPage(int page);

  /// No description provided for @khatmaProgressPageSelector.
  ///
  /// In en, this message translates to:
  /// **'Choose the last page you completed'**
  String get khatmaProgressPageSelector;

  /// No description provided for @khatmaCompleteTodayAction.
  ///
  /// In en, this message translates to:
  /// **'I completed today’s Wird'**
  String get khatmaCompleteTodayAction;

  /// No description provided for @khatmaSaveThroughPageAction.
  ///
  /// In en, this message translates to:
  /// **'Save through page {page}'**
  String khatmaSaveThroughPageAction(int page);

  /// No description provided for @khatmaExtendReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review plan extension'**
  String get khatmaExtendReviewTitle;

  /// No description provided for @khatmaExtendReviewMessage.
  ///
  /// In en, this message translates to:
  /// **'Daily pages: {oldPages} → {newPages}\nCompletion date: {oldDate} → {newDate}'**
  String khatmaExtendReviewMessage(
    int oldPages,
    int newPages,
    String oldDate,
    String newDate,
  );

  /// No description provided for @khatmaCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create Khatma'**
  String get khatmaCreateAction;

  /// No description provided for @khatmaBoundaryBySurah.
  ///
  /// In en, this message translates to:
  /// **'Surah range'**
  String get khatmaBoundaryBySurah;

  /// No description provided for @khatmaBoundaryByPage.
  ///
  /// In en, this message translates to:
  /// **'Page range'**
  String get khatmaBoundaryByPage;

  /// No description provided for @khatmaStartSurah.
  ///
  /// In en, this message translates to:
  /// **'Start Surah'**
  String get khatmaStartSurah;

  /// No description provided for @khatmaEndSurah.
  ///
  /// In en, this message translates to:
  /// **'End Surah'**
  String get khatmaEndSurah;

  /// No description provided for @khatmaStartPageInput.
  ///
  /// In en, this message translates to:
  /// **'Start page'**
  String get khatmaStartPageInput;

  /// No description provided for @khatmaEndPageInput.
  ///
  /// In en, this message translates to:
  /// **'End page'**
  String get khatmaEndPageInput;

  /// No description provided for @khatmaPageBoundsHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter a page from 1 to 604'**
  String get khatmaPageBoundsHelp;

  /// No description provided for @khatmaChooseDuration.
  ///
  /// In en, this message translates to:
  /// **'Choose a duration'**
  String get khatmaChooseDuration;

  /// No description provided for @khatmaTotalPages.
  ///
  /// In en, this message translates to:
  /// **'Total: {pages} pages'**
  String khatmaTotalPages(int pages);

  /// No description provided for @khatmaAssignedPages.
  ///
  /// In en, this message translates to:
  /// **'Assigned today: {pages}'**
  String khatmaAssignedPages(int pages);

  /// No description provided for @khatmaConfirmedPages.
  ///
  /// In en, this message translates to:
  /// **'Confirmed today: {pages}'**
  String khatmaConfirmedPages(int pages);

  /// No description provided for @khatmaRemainingTodayPages.
  ///
  /// In en, this message translates to:
  /// **'Remaining today: {pages}'**
  String khatmaRemainingTodayPages(int pages);

  /// No description provided for @khatmaSaveProgressAction.
  ///
  /// In en, this message translates to:
  /// **'Save progress'**
  String get khatmaSaveProgressAction;

  /// No description provided for @khatmaReturnToQuranAction.
  ///
  /// In en, this message translates to:
  /// **'Return to Quran'**
  String get khatmaReturnToQuranAction;

  /// No description provided for @khatmaStartAyah.
  ///
  /// In en, this message translates to:
  /// **'Start Ayah'**
  String get khatmaStartAyah;

  /// No description provided for @khatmaEndAyah.
  ///
  /// In en, this message translates to:
  /// **'End Ayah'**
  String get khatmaEndAyah;

  /// No description provided for @khatmaAyahNumber.
  ///
  /// In en, this message translates to:
  /// **'Ayah {number}'**
  String khatmaAyahNumber(int number);

  /// No description provided for @khatmaScheduleByDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get khatmaScheduleByDuration;

  /// No description provided for @khatmaScheduleByTargetDate.
  ///
  /// In en, this message translates to:
  /// **'Target date'**
  String get khatmaScheduleByTargetDate;

  /// No description provided for @khatmaChooseTargetDate.
  ///
  /// In en, this message translates to:
  /// **'Choose a completion date'**
  String get khatmaChooseTargetDate;

  /// No description provided for @khatmaPreviewPlanAction.
  ///
  /// In en, this message translates to:
  /// **'Preview plan'**
  String get khatmaPreviewPlanAction;

  /// No description provided for @khatmaEditPlanAction.
  ///
  /// In en, this message translates to:
  /// **'Edit plan'**
  String get khatmaEditPlanAction;

  /// No description provided for @khatmaEditPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Review plan changes'**
  String get khatmaEditPlanTitle;

  /// No description provided for @khatmaEditPlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust duration or completion date. Progress stays saved.'**
  String get khatmaEditPlanSubtitle;

  /// No description provided for @khatmaSavePlanChangesAction.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get khatmaSavePlanChangesAction;

  /// No description provided for @khatmaDeletePlanAction.
  ///
  /// In en, this message translates to:
  /// **'Delete plan'**
  String get khatmaDeletePlanAction;

  /// No description provided for @khatmaResetCorruptAction.
  ///
  /// In en, this message translates to:
  /// **'Reset Khatma'**
  String get khatmaResetCorruptAction;

  /// Title for the daily Quran engagement plan card
  ///
  /// In en, this message translates to:
  /// **'Today’s Plan'**
  String get todayPlanTitle;

  /// Calm motivation copy for an incomplete Today Plan
  ///
  /// In en, this message translates to:
  /// **'A small amount every day is easier to protect.'**
  String get todayPlanMotivationDefault;

  /// Calm completion copy for a completed Today Plan
  ///
  /// In en, this message translates to:
  /// **'Today is complete. Keep the rhythm gentle and steady.'**
  String get todayPlanMotivationComplete;

  /// Reading task title with page count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Read 1 page} other{Read {count} pages}}'**
  String todayPlanReadPages(int count);

  /// Reading task subtitle showing the last read Quran page
  ///
  /// In en, this message translates to:
  /// **'Continue from page {page}'**
  String todayPlanContinueFromPage(int page);

  /// Fallback reading task subtitle when no last page is known
  ///
  /// In en, this message translates to:
  /// **'Start with a short reading session'**
  String get todayPlanShortReadingSession;

  /// Listening task title with duration
  ///
  /// In en, this message translates to:
  /// **'Listen for {minutes} minutes'**
  String todayPlanListenMinutes(int minutes);

  /// Listening task title when listening history exists
  ///
  /// In en, this message translates to:
  /// **'Continue listening'**
  String get todayPlanContinueListening;

  /// Listening task subtitle with surah and reciter names
  ///
  /// In en, this message translates to:
  /// **'{surahName} · {reciterName}'**
  String todayPlanListeningSubtitle(String surahName, String reciterName);

  /// Fallback listening task subtitle
  ///
  /// In en, this message translates to:
  /// **'Choose a reciter and listen calmly'**
  String get todayPlanChooseReciter;

  /// Morning adhkar task title
  ///
  /// In en, this message translates to:
  /// **'Morning adhkar'**
  String get todayPlanMorningAdhkar;

  /// Morning adhkar task subtitle
  ///
  /// In en, this message translates to:
  /// **'A short remembrance before the day gets busy'**
  String get todayPlanMorningAdhkarSubtitle;

  /// Tasbeeh task title
  ///
  /// In en, this message translates to:
  /// **'Tasbeeh goal'**
  String get todayPlanTasbeehGoal;

  /// Today Plan progress summary
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} completed · {minutes} min left'**
  String todayPlanProgress(int completed, int total, int minutes);

  /// Continue CTA for Today Plan
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get todayPlanContinue;

  /// Compact streak day count
  ///
  /// In en, this message translates to:
  /// **'{days} d'**
  String todayPlanStreakDays(int days);

  /// Compact minute estimate
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String todayPlanMinutesShort(int minutes);

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

  /// Tooltip when the favorites-only filter is active
  ///
  /// In en, this message translates to:
  /// **'Show all reciters'**
  String get recitersShowAllReciters;

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

  /// Summary line above the reciters list
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reciter} other{{count} reciters}}'**
  String recitersResultCount(int count);

  /// Active filter chip when showing favorite reciters only
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get recitersFilterChipFavorites;

  /// Favorites filter pill with saved count
  ///
  /// In en, this message translates to:
  /// **'Favorites ({count})'**
  String recitersFilterPillFavoritesCount(int count);

  /// Toggle pill for the reciters letter index rail
  ///
  /// In en, this message translates to:
  /// **'A–Z'**
  String get recitersFilterPillAlphabet;

  /// Active filter chip for the selected alphabet letter
  ///
  /// In en, this message translates to:
  /// **'Starts with {letter}'**
  String recitersFilterChipLetter(String letter);

  /// Active filter chip showing the current search query
  ///
  /// In en, this message translates to:
  /// **'“{query}”'**
  String recitersFilterChipSearch(String query);

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
  /// **'Continue listening'**
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

  /// Hint on the collapsed queue sheet handle in the expanded player
  ///
  /// In en, this message translates to:
  /// **'Swipe up for queue'**
  String get playerQueueExpandHint;

  /// Screen reader label for the queue sheet drag handle in the expanded player
  ///
  /// In en, this message translates to:
  /// **'Show or hide queue. Drag up or tap to expand.'**
  String get playerQueueHandleSemanticLabel;

  /// Screen reader hint for the expanded now-playing sheet drag-to-minimize gesture
  ///
  /// In en, this message translates to:
  /// **'Now playing. Swipe down to minimize.'**
  String get playerExpandedSheetSemanticLabel;

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

  /// Accessibility label announced for skeleton loading regions
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

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

  /// Pinterest-style settings screen title
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get settingsYourAccount;

  /// Profile row subtitle on settings (catalog style)
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get settingsViewProfile;

  /// Profile subtitle showing when the user joined
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String settingsMemberSince(String date);

  /// Login section header on settings screen
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get settingsLoginSection;

  /// Support section header on settings screen
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsSupportSection;

  /// Settings tile to open release notes for the current version
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get whatsNewSettingsTile;

  /// Title for the what's new bottom sheet
  ///
  /// In en, this message translates to:
  /// **'What\'s new in {version}'**
  String whatsNewTitle(String version);

  /// Screen reader label for the what's new sheet
  ///
  /// In en, this message translates to:
  /// **'What\'s new in version {version}'**
  String whatsNewSemanticsLabel(String version);

  /// Primary action to dismiss the what's new sheet
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get whatsNewGotIt;

  /// Appearance section header on settings screen
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Playback and storage section header on settings screen
  ///
  /// In en, this message translates to:
  /// **'Playback & storage'**
  String get settingsPlaybackAndStorage;

  /// Reciters section header on settings screen
  ///
  /// In en, this message translates to:
  /// **'Reciters'**
  String get settingsRecitersSection;

  /// Light theme option label
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Dark theme option label
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// System theme option label
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Choose theme dialog title
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get chooseTheme;

  /// Single-word label for the Home tab in the phone bottom navigation bar
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get bottomNavHome;

  /// Legacy key; prefer bottomNavSearch for shell navigation
  ///
  /// In en, this message translates to:
  /// **'Reciters'**
  String get bottomNavReciters;

  /// Single-word label for the reciter search entry in bottom navigation
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get bottomNavSearch;

  /// Screen reader label for the reciters bottom-nav item when another tab is selected
  ///
  /// In en, this message translates to:
  /// **'Go to reciters'**
  String get a11yBottomNavRecitersTab;

  /// Screen reader label for the reciters bottom-nav item when the reciters tab is already active (re-tap focuses search)
  ///
  /// In en, this message translates to:
  /// **'Search reciters'**
  String get a11yBottomNavRecitersSearch;

  /// Summary line when showing filtered reciter search results
  ///
  /// In en, this message translates to:
  /// **'Results for “{query}”'**
  String recitersSearchResultsFor(String query);

  /// Empty state title when a reciter search returns no matches
  ///
  /// In en, this message translates to:
  /// **'No results for “{query}”'**
  String noRecitersForQuery(String query);

  /// Button to reset the reciter search field and show the full catalog
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get recitersClearSearch;

  /// Legacy shell label; prayer times opens from Home
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get bottomNavPrayer;

  /// Single-word label for the Qibla tab in the phone bottom navigation bar
  ///
  /// In en, this message translates to:
  /// **'Qibla'**
  String get bottomNavQibla;

  /// Single-word label for the Quran tab in the phone bottom navigation bar
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get bottomNavQuran;

  /// Single-word label for the dhikr tab in the phone bottom navigation bar (Behance lifestyle IA)
  ///
  /// In en, this message translates to:
  /// **'Dhikr'**
  String get bottomNavAthkar;

  /// Single-word label for the settings tab in the phone bottom navigation bar
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get bottomNavSettings;

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
  /// **'Welcome to MeMuslim'**
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

  /// Sign in with Google button text (Google Identity branding)
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
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

  /// Shown when the device has no Google accounts configured
  ///
  /// In en, this message translates to:
  /// **'No Google account found on this device. Please add a Google account in your device settings and try again.'**
  String get googleSignInNoAccountsOnDevice;

  /// Title when Google account picker fails to render on device
  ///
  /// In en, this message translates to:
  /// **'Google sign-in could not open'**
  String get googleSignInFallbackTitle;

  /// Help text when Google sign-in UI is unavailable
  ///
  /// In en, this message translates to:
  /// **'The Google account picker may be hidden on this device. Update Google Play Services, then try again. If it still fails, ask your developer to register this build\'s SHA-1 in Firebase.'**
  String get googleSignInFallbackBody;

  /// Opens Play Store to update Google Play Services
  ///
  /// In en, this message translates to:
  /// **'Update Google Play Services'**
  String get googleSignInUpdatePlayServices;

  /// Shown when Google sign-in exceeds the time limit
  ///
  /// In en, this message translates to:
  /// **'Sign-in timed out. Please try again.'**
  String get googleSignInTimeout;

  /// Shown when Google sign-in times out without showing UI on problematic devices
  ///
  /// In en, this message translates to:
  /// **'Sign-in timed out. If the account picker did not appear, go back and try again, or use the options below.'**
  String get googleSignInTimeoutUiHidden;

  /// Shown when Google sign-in returns a different account than expected
  ///
  /// In en, this message translates to:
  /// **'This Google account does not match the signed-in account. Please try again.'**
  String get googleSignInUserMismatch;

  /// Shown when the user dismisses the Google account picker during sign-in
  ///
  /// In en, this message translates to:
  /// **'Sign-in cancelled.'**
  String get googleSignInCancelled;

  /// Network error message
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection'**
  String get networkError;

  /// Message shown when a server-dependent action is blocked while offline
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please reconnect and try again.'**
  String get serverActionOfflineMessage;

  /// Fallback shown for unmapped auth errors so raw exception text never reaches users
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authErrorGenericMessage;

  /// Subtitle on email login screen
  ///
  /// In en, this message translates to:
  /// **'Sign in with your email and password'**
  String get signInWithEmailDescription;

  /// Subtitle on registration screen
  ///
  /// In en, this message translates to:
  /// **'Create an account with email and password'**
  String get createAccountDescription;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// Email sign-in button and navigation label
  ///
  /// In en, this message translates to:
  /// **'Sign in with email'**
  String get signInWithEmail;

  /// Registration button and navigation label
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// Registration wizard step progress label
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}: {title}'**
  String registrationStepProgress(int current, int total, String title);

  /// Registration step 1 title
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get registrationStepAccountTitle;

  /// Registration step 1 subtitle
  ///
  /// In en, this message translates to:
  /// **'Choose your email and password'**
  String get registrationStepAccountDescription;

  /// Registration step 2 title
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get registrationStepPersonalTitle;

  /// Registration step 2 subtitle
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself'**
  String get registrationStepPersonalDescription;

  /// Registration step 3 title
  ///
  /// In en, this message translates to:
  /// **'Quran learning'**
  String get registrationStepLearningTitle;

  /// Registration step 3 subtitle
  ///
  /// In en, this message translates to:
  /// **'What would you like to learn?'**
  String get registrationStepLearningDescription;

  /// Registration step 5 title
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get registrationStepReviewTitle;

  /// Registration step 5 subtitle
  ///
  /// In en, this message translates to:
  /// **'Review your details, then create your account'**
  String get registrationStepReviewDescription;

  /// Preferred language field on registration
  ///
  /// In en, this message translates to:
  /// **'Preferred app language'**
  String get registrationPreferredLanguageLabel;

  /// Validation when display name missing
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get registrationDisplayNameRequired;

  /// Validation when gender missing
  ///
  /// In en, this message translates to:
  /// **'Select your gender'**
  String get registrationGenderRequired;

  /// Validation when DOB missing
  ///
  /// In en, this message translates to:
  /// **'Select your date of birth'**
  String get registrationDateOfBirthRequired;

  /// Validation when country missing
  ///
  /// In en, this message translates to:
  /// **'Select your country'**
  String get registrationCountryRequired;

  /// Validation when city missing
  ///
  /// In en, this message translates to:
  /// **'Select your city'**
  String get registrationCityRequired;

  /// Validation when language missing
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language'**
  String get registrationPreferredLanguageRequired;

  /// Validation when learning goals missing
  ///
  /// In en, this message translates to:
  /// **'Select at least one learning goal'**
  String get registrationLearningGoalsRequired;

  /// Shown when Firebase auth succeeds but Firestore profile write fails
  ///
  /// In en, this message translates to:
  /// **'Account created but saving your profile failed. Tap retry or complete your profile after sign-in.'**
  String get registrationProfilePersistenceFailed;

  /// Retry button after profile persistence failure
  ///
  /// In en, this message translates to:
  /// **'Retry saving profile'**
  String get registrationRetryProfileSave;

  /// Forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// Forgot password screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we will send a reset link'**
  String get forgotPasswordDescription;

  /// Forgot password submit button
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// Divider label between auth methods on login screen
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// Link from register to login
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// Link from login to register
  ///
  /// In en, this message translates to:
  /// **'No account yet? Create one'**
  String get noAccountYet;

  /// Email validation error
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get authInvalidEmail;

  /// Password length validation error
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get authWeakPassword;

  /// Confirm password mismatch error
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordsDoNotMatch;

  /// Login user-not-found error
  ///
  /// In en, this message translates to:
  /// **'No account found for this email'**
  String get authUserNotFound;

  /// Login wrong-password error
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get authWrongPassword;

  /// Registration email-already-in-use error
  ///
  /// In en, this message translates to:
  /// **'An account already exists with this email. Sign in instead.'**
  String get authEmailAlreadyInUse;

  /// Registration when Google account exists for email
  ///
  /// In en, this message translates to:
  /// **'This email is registered with Google. Sign in with Google instead.'**
  String get authEmailAlreadyInUseWithGoogle;

  /// Provider conflict generic message
  ///
  /// In en, this message translates to:
  /// **'This email uses a different sign-in method. Use the original method.'**
  String get authAccountExistsWithDifferentCredential;

  /// Google sign-in when email/password account exists
  ///
  /// In en, this message translates to:
  /// **'This email is registered with a password. Sign in with email instead.'**
  String get authAccountExistsUseEmailPassword;

  /// Firebase rate limit error
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait and try again.'**
  String get authTooManyRequests;

  /// Email provider disabled in Firebase
  ///
  /// In en, this message translates to:
  /// **'Email sign-in is not enabled. Contact support.'**
  String get authOperationNotAllowed;

  /// Disabled Firebase user
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled. Contact support.'**
  String get authUserDisabled;

  /// Invalid credential on login
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get authInvalidCredential;

  /// Password reset email success message
  ///
  /// In en, this message translates to:
  /// **'If an account exists, a reset link was sent to your email.'**
  String get authResetEmailSent;

  /// Shown when redirecting new registrants to profile completion
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to book Quran sessions'**
  String get completeProfilePrompt;

  /// Toast shown when device free storage is likely below the estimated download size
  ///
  /// In en, this message translates to:
  /// **'Available storage may not be enough for this download. Free up space if downloads fail.'**
  String get downloadLowStorageWarning;

  /// Error toast when Download All is blocked because device storage is too low
  ///
  /// In en, this message translates to:
  /// **'Not enough storage space to download all surahs. Free up space and try again.'**
  String get downloadLowStorageBlocked;

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

  /// Primary color preset — Pinterest-inspired brand red
  ///
  /// In en, this message translates to:
  /// **'Coral'**
  String get colorCoral;

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

  /// TripGlide charcoal primary preset name
  ///
  /// In en, this message translates to:
  /// **'Charcoal'**
  String get colorInk;

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

  /// Delete account action in settings
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// Confirmation message before deleting the app account
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your MeMuslim account and synced profile data. Purchases verified with Google Play may be kept in anonymized records for fraud prevention. This cannot be undone.'**
  String get deleteAccountConfirmation;

  /// Generic error when account deletion fails
  ///
  /// In en, this message translates to:
  /// **'Unable to delete your account. Please try again.'**
  String get deleteAccountFailed;

  /// Error when a Firebase admin user tries self-service account deletion
  ///
  /// In en, this message translates to:
  /// **'Admin accounts must be deleted from the admin panel.'**
  String get deleteAccountAdminMustUseAdminPanel;

  /// Error when account deletion is blocked by a non-zero wallet balance
  ///
  /// In en, this message translates to:
  /// **'Your wallet balance must be zero before deleting your account. Please refund or use your balance first.'**
  String get deleteAccountWalletNotEmpty;

  /// Error when account deletion is blocked by active student bookings
  ///
  /// In en, this message translates to:
  /// **'You have active bookings as a student. Please cancel or complete them before deleting your account.'**
  String get deleteAccountActiveBookingsStudent;

  /// Error when account deletion is blocked by active teacher bookings
  ///
  /// In en, this message translates to:
  /// **'You have active bookings as a teacher. Please cancel or complete them before deleting your account.'**
  String get deleteAccountActiveBookingsTeacher;

  /// Error when the user already has a pending account deletion request
  ///
  /// In en, this message translates to:
  /// **'Account deletion is already pending.'**
  String get deleteAccountAlreadyPending;

  /// Error when the account deletion callable is unavailable or not deployed
  ///
  /// In en, this message translates to:
  /// **'Account deletion is temporarily unavailable. Please update the app or try again later.'**
  String get deleteAccountServiceUnavailable;

  /// Error when delete account is requested without an active session
  ///
  /// In en, this message translates to:
  /// **'You must be signed in to delete your account.'**
  String get deleteAccountNotSignedIn;

  /// Loading message shown while account deletion is in progress
  ///
  /// In en, this message translates to:
  /// **'Deleting your account...'**
  String get deleteAccountInProgress;

  /// Privacy policy link label
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// Link to the web account-deletion page required by Google Play
  ///
  /// In en, this message translates to:
  /// **'Request account deletion on the web'**
  String get requestAccountDeletionWeb;

  /// Legal links section header on settings screen
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get settingsLegalSection;

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

  /// Toast when AudioService.init fails during app startup on Android
  ///
  /// In en, this message translates to:
  /// **'Background audio could not start. Playback may be unavailable until you restart the app.'**
  String get audioServiceInitFailed;

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

  /// Settings title for showing the reciters alphabet index rail
  ///
  /// In en, this message translates to:
  /// **'Show Alphabet Index'**
  String get showRecitersAlphabetIndex;

  /// Settings subtitle for showing the reciters alphabet index rail
  ///
  /// In en, this message translates to:
  /// **'Display the A-Z shortcut rail while browsing reciters'**
  String get showRecitersAlphabetIndexSubtitle;

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

  /// Placeholder hint for target count input
  ///
  /// In en, this message translates to:
  /// **'e.g. 33'**
  String get tasbeehTargetHint;

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

  /// Title for ephemeral tap-to-count without saving
  ///
  /// In en, this message translates to:
  /// **'Quick count'**
  String get tasbeehQuickCountTitle;

  /// Subtitle for ephemeral quick count entry
  ///
  /// In en, this message translates to:
  /// **'Count without saving — tap to begin'**
  String get tasbeehQuickCountSubtitle;

  /// Progress label for saved dhikr list items
  ///
  /// In en, this message translates to:
  /// **'{current} / {target}'**
  String tasbeehProgressLabel(int current, int target);

  /// Accessibility label for switching saved dhikr to list layout
  ///
  /// In en, this message translates to:
  /// **'Show as list'**
  String get tasbeehShowAsList;

  /// Accessibility label for switching saved dhikr to grid layout
  ///
  /// In en, this message translates to:
  /// **'Show as grid'**
  String get tasbeehShowAsGrid;

  /// Title for clear-all saved tasbeeh confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Clear all saved Tasbeeh?'**
  String get tasbeehClearAllTitle;

  /// Body for clear-all saved tasbeeh confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'This removes all {count} saved dhikr and their reminders. This cannot be undone.'**
  String tasbeehClearAllMessage(int count);

  /// Title for per-dhikr reminder bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get tasbeehReminderSheetTitle;

  /// Switch label for enabling a daily tasbeeh reminder
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get tasbeehReminderEnabledLabel;

  /// Subtitle for daily tasbeeh reminder switch
  ///
  /// In en, this message translates to:
  /// **'Get a local notification at your chosen time'**
  String get tasbeehReminderEnabledSubtitle;

  /// Button label showing selected reminder time
  ///
  /// In en, this message translates to:
  /// **'Reminder time: {time}'**
  String tasbeehReminderPickTime(String time);

  /// App bar action to open reminder settings while counting
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get tasbeehReminderAction;

  /// Body text for daily tasbeeh reminder local notifications
  ///
  /// In en, this message translates to:
  /// **'Time for your dhikr'**
  String get tasbeehReminderNotificationBody;

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

  /// Centered uppercase title on the Qibla compass screen (Behance reference)
  ///
  /// In en, this message translates to:
  /// **'QIBLA FINDER'**
  String get qiblaFinderTitle;

  /// Subtitle below the Qibla bearing readout (geographic degrees from north)
  ///
  /// In en, this message translates to:
  /// **'Qibla bearing from north'**
  String get qiblaDeviceAngleLabel;

  /// Instruction when the user should rotate left to align with Qibla
  ///
  /// In en, this message translates to:
  /// **'Rotate the phone {degrees}° to the left'**
  String qiblaRotatePhoneLeft(int degrees);

  /// Instruction when the user should rotate right to align with Qibla
  ///
  /// In en, this message translates to:
  /// **'Rotate the phone {degrees}° to the right'**
  String qiblaRotatePhoneRight(int degrees);

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

  /// Attribution line for the bundled Quran translation shown in reader settings
  ///
  /// In en, this message translates to:
  /// **'Translation: {translationName} ({sourceName})'**
  String quranTranslationAttribution(String translationName, String sourceName);

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

  /// Mushaf feature title
  ///
  /// In en, this message translates to:
  /// **'Mushaf'**
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

  /// Centered uppercase title on the Quran hub screen (Behance reference)
  ///
  /// In en, this message translates to:
  /// **'QURAN'**
  String get quranHubTitle;

  /// Section heading above Surah/Juz/Page pills on the Quran hub
  ///
  /// In en, this message translates to:
  /// **'Al Quran'**
  String get quranCatalogSectionTitle;

  /// Opens the page-based Mushaf reader from the surah detail screen
  ///
  /// In en, this message translates to:
  /// **'Open Mushaf'**
  String get quranOpenMushaf;

  /// Switch Quran reader from Mushaf pages to the Behance-style ayah list
  ///
  /// In en, this message translates to:
  /// **'Ayah list view'**
  String get quranSwitchToAyahList;

  /// Switch Quran reader from ayah list back to Mushaf pages
  ///
  /// In en, this message translates to:
  /// **'Mushaf view'**
  String get quranSwitchToMushaf;

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

  /// Title for the Hijri month calendar bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Islamic calendar'**
  String get hijriCalendarTitle;

  /// Accessibility label for tapping the home hero Hijri date
  ///
  /// In en, this message translates to:
  /// **'Open Islamic calendar'**
  String get hijriCalendarOpenLabel;

  /// Navigate to the previous Hijri month in the calendar sheet
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get hijriCalendarPreviousMonth;

  /// Navigate to the next Hijri month in the calendar sheet
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get hijriCalendarNextMonth;

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
  /// **'Shared via MeMuslim'**
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

  /// Label for the first adhan sound option
  ///
  /// In en, this message translates to:
  /// **'Sound 1'**
  String get adhanSound1;

  /// Label for the second adhan sound option
  ///
  /// In en, this message translates to:
  /// **'Sound 2'**
  String get adhanSound2;

  /// Label for the third adhan sound option
  ///
  /// In en, this message translates to:
  /// **'Sound 3'**
  String get adhanSound3;

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
  /// **'On this device, also enable Autostart for MeMuslim in your phone\'s settings so reminders are not stopped in the background.'**
  String get oemAutostartHint;

  /// Title for location permission setup screen
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get prayerAlertsPermissionLocationTitle;

  /// Body for location permission setup screen
  ///
  /// In en, this message translates to:
  /// **'Allow location access so prayer times are calculated for where you are. Times update automatically when you travel.'**
  String get prayerAlertsPermissionLocationBody;

  /// Title for prayer alerts notification permission setup screen
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get prayerAlertsPermissionNotificationsTitle;

  /// Body for prayer alerts notification permission setup screen
  ///
  /// In en, this message translates to:
  /// **'To make sure you never miss a prayer time, allow notifications. You will be reminded when each prayer begins.'**
  String get prayerAlertsPermissionNotificationsBody;

  /// Title for exact alarm permission setup screen
  ///
  /// In en, this message translates to:
  /// **'Alarms & reminders'**
  String get prayerAlertsPermissionExactAlarmTitle;

  /// Body for exact alarm permission setup screen
  ///
  /// In en, this message translates to:
  /// **'Allow Alarms & reminders so Adhan and prayer alerts play on time, even when the phone is idle or the screen is off.'**
  String get prayerAlertsPermissionExactAlarmBody;

  /// Title for battery optimization exemption setup screen
  ///
  /// In en, this message translates to:
  /// **'Battery optimization'**
  String get prayerAlertsPermissionBatteryTitle;

  /// Body for battery optimization setup screen
  ///
  /// In en, this message translates to:
  /// **'Exclude MeMuslim from battery optimization so prayer reminders are not delayed overnight.'**
  String get prayerAlertsPermissionBatteryBody;

  /// Title for OEM autostart guidance step
  ///
  /// In en, this message translates to:
  /// **'Background access'**
  String get prayerAlertsPermissionOemAutostartTitle;

  /// Body for OEM autostart guidance step
  ///
  /// In en, this message translates to:
  /// **'On this device, enable Autostart for MeMuslim in your phone settings so reminders are not stopped in the background.'**
  String get prayerAlertsPermissionOemAutostartBody;

  /// Primary action on prayer alerts permission setup screens
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get prayerAlertsPermissionAllow;

  /// Skip action on prayer alerts permission setup screens
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get prayerAlertsPermissionSkip;

  /// Continue action on informational permission setup step
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get prayerAlertsPermissionContinue;

  /// Summary in prayer notification settings when permissions are missing
  ///
  /// In en, this message translates to:
  /// **'Some permissions are needed for reliable prayer alerts and Adhan.'**
  String get prayerAlertsPermissionSetupRequired;

  /// Opens full-screen prayer alerts permission flow from settings sheet
  ///
  /// In en, this message translates to:
  /// **'Set up permissions'**
  String get prayerAlertsPermissionSetupAction;

  /// Body text for prayer time notifications
  ///
  /// In en, this message translates to:
  /// **'It is time for {prayerName}'**
  String prayerNotificationBody(String prayerName);

  /// Title for prayer notifications when the user's location is known
  ///
  /// In en, this message translates to:
  /// **'{prayerName} · {locationName}'**
  String prayerNotificationTitleWithLocation(
    String prayerName,
    String locationName,
  );

  /// Body for prayer notifications when the user's location is known
  ///
  /// In en, this message translates to:
  /// **'It is time for {prayerName} in {locationName}'**
  String prayerNotificationBodyWithLocation(
    String prayerName,
    String locationName,
  );

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
  /// **'Adhan is playing…'**
  String get adhanIsPlaying;

  /// Native adhan foreground notification body when location is known
  ///
  /// In en, this message translates to:
  /// **'Adhan is playing for {locationName}'**
  String adhanPlayingNotificationBodyWithLocation(String locationName);

  /// Button label to stop Adhan playback
  ///
  /// In en, this message translates to:
  /// **'Stop Adhan'**
  String get stopAdhan;

  /// Dialog body shown when the user tries to leave the prayer notification screen while the adhan is still playing
  ///
  /// In en, this message translates to:
  /// **'Would you like to stop the adhan before leaving?'**
  String get adhanStillPlayingMessage;

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
  /// **'More'**
  String get moreOptions;

  /// Subtitle for the More section on the home dashboard
  ///
  /// In en, this message translates to:
  /// **'Your library and more options'**
  String get homeMoreOptionsSubtitle;

  /// Support Tilawa screen and settings entry title
  ///
  /// In en, this message translates to:
  /// **'Support MeMuslim'**
  String get supportTilawa;

  /// Settings row to open the in-app review dialog
  ///
  /// In en, this message translates to:
  /// **'Rate MeMuslim'**
  String get rateTilawa;

  /// Optional subtitle under the rate Tilawa settings row
  ///
  /// In en, this message translates to:
  /// **'Share your feedback on the app store.'**
  String get rateTilawaSubtitle;

  /// Settings row that opens the Sentry bug report form
  ///
  /// In en, this message translates to:
  /// **'Report a bug'**
  String get reportBugSettingsTileTitle;

  /// Subtitle under the report-a-bug settings row
  ///
  /// In en, this message translates to:
  /// **'Tell us what went wrong so we can fix it.'**
  String get reportBugSettingsTileSubtitle;

  /// App bar title for the Sentry feedback form
  ///
  /// In en, this message translates to:
  /// **'Report a bug'**
  String get reportBugTitle;

  /// Heading inside the Sentry feedback form
  ///
  /// In en, this message translates to:
  /// **'Report a bug'**
  String get reportBugFormTitle;

  /// Label for the bug description field in Sentry feedback
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get reportBugMessageLabel;

  /// Placeholder for the bug description field in Sentry feedback
  ///
  /// In en, this message translates to:
  /// **'What happened? What did you expect?'**
  String get reportBugMessagePlaceholder;

  /// Label for the name field in Sentry feedback
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get reportBugNameLabel;

  /// Placeholder for the name field in Sentry feedback
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get reportBugNamePlaceholder;

  /// Label for the email field in Sentry feedback
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get reportBugEmailLabel;

  /// Placeholder for the email field in Sentry feedback
  ///
  /// In en, this message translates to:
  /// **'your.email@example.com'**
  String get reportBugEmailPlaceholder;

  /// Submit button on the Sentry feedback form
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get reportBugSubmitButton;

  /// Cancel button on the Sentry feedback form
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get reportBugCancelButton;

  /// Success message after submitting Sentry feedback
  ///
  /// In en, this message translates to:
  /// **'Thank you for your report.'**
  String get reportBugSuccessMessage;

  /// Suffix on required Sentry feedback field labels
  ///
  /// In en, this message translates to:
  /// **' (required)'**
  String get reportBugRequiredLabel;

  /// Validation error on empty required Sentry feedback fields
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get reportBugValidationError;

  /// Button to capture a screenshot for Sentry feedback
  ///
  /// In en, this message translates to:
  /// **'Attach screenshot'**
  String get reportBugCaptureScreenshot;

  /// Button to remove an attached Sentry feedback screenshot
  ///
  /// In en, this message translates to:
  /// **'Remove screenshot'**
  String get reportBugRemoveScreenshot;

  /// Accessibility label for opening a full-screen Sentry feedback screenshot preview
  ///
  /// In en, this message translates to:
  /// **'Preview screenshot'**
  String get reportBugPreviewScreenshot;

  /// Title for the full-screen Sentry feedback screenshot preview
  ///
  /// In en, this message translates to:
  /// **'Screenshot'**
  String get reportBugScreenshotPreviewTitle;

  /// Button to navigate elsewhere before capturing a bug-report screenshot
  ///
  /// In en, this message translates to:
  /// **'Attach from another screen'**
  String get reportBugCaptureScreenshotFromAnotherScreen;

  /// Hint shown while navigating to capture a bug-report screenshot
  ///
  /// In en, this message translates to:
  /// **'Go to the screen you want, then tap Capture.'**
  String get reportBugScreenshotCaptureHint;

  /// Button to capture the visible screen during navigate-then-capture
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get reportBugScreenshotCaptureNow;

  /// Button to cancel navigate-then-capture and return to the bug form
  ///
  /// In en, this message translates to:
  /// **'Back to report'**
  String get reportBugScreenshotCaptureCancel;

  /// Shown when navigate-then-capture or attach fails to produce a screenshot
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t capture a screenshot. You can still send your report.'**
  String get reportBugScreenshotCaptureFailed;

  /// Settings row to share the app with others
  ///
  /// In en, this message translates to:
  /// **'Share MeMuslim'**
  String get shareTilawa;

  /// Text shared from settings to recommend Tilawa to others
  ///
  /// In en, this message translates to:
  /// **'Check out {appName}:\n{storeUrl}'**
  String shareTilawaMessage(String appName, String storeUrl);

  /// Error shown when sharing Tilawa from settings fails
  ///
  /// In en, this message translates to:
  /// **'We could not open the share sheet. Please try again.'**
  String get shareTilawaFailed;

  /// Support screen single-line intro under app bar
  ///
  /// In en, this message translates to:
  /// **'Your contribution helps keep MeMuslim going.'**
  String get supportIntroLine;

  /// Legacy alias; prefer supportIntroLine
  ///
  /// In en, this message translates to:
  /// **'Your contribution helps keep MeMuslim going.'**
  String get supportTilawaSubtitle;

  /// Legacy alias; unused on support screen
  ///
  /// In en, this message translates to:
  /// **'Your contribution helps keep MeMuslim going.'**
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
  /// **'Payment via Google Play. MeMuslim does not store your card details.'**
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
  /// **'Support MeMuslim'**
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

  /// Support purchase blocked by missing/invalid App Check in debug or profile builds
  ///
  /// In en, this message translates to:
  /// **'Support confirmation was blocked because App Check is not set up for this build. In Firebase Console, open App Check, register a debug token for this device, then try again.'**
  String get purchaseAppCheckFailedDebug;

  /// Support purchase blocked by App Check in release builds
  ///
  /// In en, this message translates to:
  /// **'We could not confirm your support because this device could not be verified. Update the app and try again later.'**
  String get purchaseAppCheckFailedRelease;

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

  /// Screen-reader label announced while the splash loading screen is visible
  ///
  /// In en, this message translates to:
  /// **'MeMuslim, loading'**
  String get a11ySplashLoading;

  /// Toast shown when startup times out and the app navigates to home in a degraded state
  ///
  /// In en, this message translates to:
  /// **'Some content may take a moment to load'**
  String get splashSlowLoadingNotice;

  /// Button that advances to the next step in a product tour
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tourActionNext;

  /// Button that closes the last step of a product tour
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tourActionFinish;

  /// Button that dismisses a product tour without finishing it
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tourActionSkip;

  /// Screen-reader label announcing tour progress
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String tourStepSemantics(int current, int total);

  /// Title for the tour step highlighting the reciter search field
  ///
  /// In en, this message translates to:
  /// **'Find a reciter'**
  String get tourRecitersSearchTitle;

  /// Body text for the tour step highlighting the reciter search field
  ///
  /// In en, this message translates to:
  /// **'Search by name to quickly jump to any reciter.'**
  String get tourRecitersSearchDescription;

  /// Title for the tour step highlighting the favorites filter
  ///
  /// In en, this message translates to:
  /// **'Save your favorites'**
  String get tourRecitersFavoritesTitle;

  /// Body text for the tour step highlighting the favorites filter
  ///
  /// In en, this message translates to:
  /// **'Tap the heart to keep the reciters you love within reach.'**
  String get tourRecitersFavoritesDescription;

  /// Title for the tour step that prompts opening a reciter from the list
  ///
  /// In en, this message translates to:
  /// **'Open a reciter'**
  String get tourRecitersOpenReciterTitle;

  /// Body text for the tour step that prompts opening a reciter from the list
  ///
  /// In en, this message translates to:
  /// **'Tap a reciter to browse their recitations and start listening.'**
  String get tourRecitersOpenReciterDescription;

  /// Title for the tour step highlighting the currently playing surah row
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get tourReciterPlaybackPlayingTitle;

  /// Body text for the tour step highlighting the currently playing surah row
  ///
  /// In en, this message translates to:
  /// **'The highlighted surah is playing now. Tap any surah to switch.'**
  String get tourReciterPlaybackPlayingDescription;

  /// Title for the tour step highlighting the mini player bar
  ///
  /// In en, this message translates to:
  /// **'Mini player'**
  String get tourReciterPlaybackMiniPlayerTitle;

  /// Body text for the tour step highlighting the mini player bar
  ///
  /// In en, this message translates to:
  /// **'Control playback from here while you keep browsing.'**
  String get tourReciterPlaybackMiniPlayerDescription;

  /// Debug-only settings tile that clears completed product tours
  ///
  /// In en, this message translates to:
  /// **'Reset product tours'**
  String get tourDebugResetTitle;

  /// Confirmation shown after the debug reset clears tour progress
  ///
  /// In en, this message translates to:
  /// **'Product tours reset'**
  String get tourDebugResetDone;

  /// Debug-only settings tile that schedules a manual Adhan test
  ///
  /// In en, this message translates to:
  /// **'Test Adhan in 10 seconds'**
  String get adhanDebugTestTitle;

  /// Supporting text for the debug-only Adhan test settings tile
  ///
  /// In en, this message translates to:
  /// **'Requests notification permission, then schedules the native Adhan alarm.'**
  String get adhanDebugTestSubtitle;

  /// Confirmation shown after scheduling the debug Adhan test
  ///
  /// In en, this message translates to:
  /// **'Adhan test scheduled for 10 seconds from now'**
  String get adhanDebugScheduled;

  /// Warning shown when the debug Adhan test used native inexact alarm fallback because exact alarm permission is unavailable
  ///
  /// In en, this message translates to:
  /// **'Native Adhan test scheduled with inexact timing. Enable Alarms & reminders for exact timing.'**
  String get adhanDebugNativeInexactScheduled;

  /// Warning shown when the debug Adhan test used local-notification fallback because native exact alarm scheduling was unavailable
  ///
  /// In en, this message translates to:
  /// **'Fallback Adhan test scheduled. Enable Alarms & reminders for native playback.'**
  String get adhanDebugFallbackScheduled;

  /// Error shown when notification permission is missing for the debug Adhan test
  ///
  /// In en, this message translates to:
  /// **'Notification permission is required before scheduling the Adhan test'**
  String get adhanDebugPermissionMissing;

  /// Error shown when the debug Adhan test cannot be scheduled
  ///
  /// In en, this message translates to:
  /// **'Could not schedule Adhan test'**
  String get adhanDebugFailed;

  /// Developer settings entry and screen title for notification routing tests
  ///
  /// In en, this message translates to:
  /// **'Notification Debug Lab'**
  String get notificationDebugLabTitle;

  /// No description provided for @notificationDebugSectionLocal.
  ///
  /// In en, this message translates to:
  /// **'Local notification tests'**
  String get notificationDebugSectionLocal;

  /// No description provided for @notificationDebugSectionLaunch.
  ///
  /// In en, this message translates to:
  /// **'Launch simulation'**
  String get notificationDebugSectionLaunch;

  /// No description provided for @notificationDebugSectionDedup.
  ///
  /// In en, this message translates to:
  /// **'Dedup state inspector'**
  String get notificationDebugSectionDedup;

  /// No description provided for @notificationDebugSectionChecklist.
  ///
  /// In en, this message translates to:
  /// **'Manual validation checklist'**
  String get notificationDebugSectionChecklist;

  /// No description provided for @notificationDebugSectionLogs.
  ///
  /// In en, this message translates to:
  /// **'Debug logs'**
  String get notificationDebugSectionLogs;

  /// No description provided for @notificationDebugActionId.
  ///
  /// In en, this message translates to:
  /// **'Notification id'**
  String get notificationDebugActionId;

  /// No description provided for @notificationDebugActionPayload.
  ///
  /// In en, this message translates to:
  /// **'Payload'**
  String get notificationDebugActionPayload;

  /// No description provided for @notificationDebugActionRoute.
  ///
  /// In en, this message translates to:
  /// **'Expected route'**
  String get notificationDebugActionRoute;

  /// No description provided for @notificationDebugActionBehavior.
  ///
  /// In en, this message translates to:
  /// **'Expected behavior'**
  String get notificationDebugActionBehavior;

  /// No description provided for @notificationDebugActionMechanism.
  ///
  /// In en, this message translates to:
  /// **'Mechanism'**
  String get notificationDebugActionMechanism;

  /// No description provided for @notificationDebugRefreshState.
  ///
  /// In en, this message translates to:
  /// **'Refresh state'**
  String get notificationDebugRefreshState;

  /// No description provided for @notificationDebugClearDedup.
  ///
  /// In en, this message translates to:
  /// **'Clear notification dedup'**
  String get notificationDebugClearDedup;

  /// No description provided for @notificationDebugClearAthkarDedup.
  ///
  /// In en, this message translates to:
  /// **'Clear Athkar warm dedup'**
  String get notificationDebugClearAthkarDedup;

  /// No description provided for @notificationDebugClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all debug state'**
  String get notificationDebugClearAll;

  /// No description provided for @notificationDebugClearLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear logs'**
  String get notificationDebugClearLogs;

  /// No description provided for @notificationDebugConfirmSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule another debug notification?'**
  String get notificationDebugConfirmSchedule;

  /// No description provided for @notificationDebugMechanismReal.
  ///
  /// In en, this message translates to:
  /// **'Real local notification'**
  String get notificationDebugMechanismReal;

  /// No description provided for @notificationDebugMechanismDispatcher.
  ///
  /// In en, this message translates to:
  /// **'Dispatcher simulation'**
  String get notificationDebugMechanismDispatcher;

  /// No description provided for @notificationDebugMechanismBootstrap.
  ///
  /// In en, this message translates to:
  /// **'Bootstrap launch probe'**
  String get notificationDebugMechanismBootstrap;

  /// No description provided for @notificationDebugMechanismDedup.
  ///
  /// In en, this message translates to:
  /// **'Dedup persist only'**
  String get notificationDebugMechanismDedup;

  /// No description provided for @notificationDebugMechanismClearPid.
  ///
  /// In en, this message translates to:
  /// **'Clear pid scope'**
  String get notificationDebugMechanismClearPid;

  /// No description provided for @notificationDebugBehaviorScheduleAthkar.
  ///
  /// In en, this message translates to:
  /// **'Shows a debug Athkar notification after a short delay'**
  String get notificationDebugBehaviorScheduleAthkar;

  /// No description provided for @notificationDebugBehaviorShowNow.
  ///
  /// In en, this message translates to:
  /// **'Posts a debug notification immediately'**
  String get notificationDebugBehaviorShowNow;

  /// No description provided for @notificationDebugBehaviorNativePayloadOnly.
  ///
  /// In en, this message translates to:
  /// **'Simulates native prayer tap with payload only (no id)'**
  String get notificationDebugBehaviorNativePayloadOnly;

  /// No description provided for @notificationDebugBehaviorInvalidPayload.
  ///
  /// In en, this message translates to:
  /// **'Should not navigate to Athkar'**
  String get notificationDebugBehaviorInvalidPayload;

  /// No description provided for @notificationDebugBehaviorEmptyPayload.
  ///
  /// In en, this message translates to:
  /// **'Should not navigate (empty payload)'**
  String get notificationDebugBehaviorEmptyPayload;

  /// No description provided for @notificationDebugBehaviorPayloadOnlyNoId.
  ///
  /// In en, this message translates to:
  /// **'Routes via payload signature only'**
  String get notificationDebugBehaviorPayloadOnlyNoId;

  /// No description provided for @notificationDebugBehaviorDedupSameSig.
  ///
  /// In en, this message translates to:
  /// **'First tap navigates; same pid + signature replays suppressed'**
  String get notificationDebugBehaviorDedupSameSig;

  /// No description provided for @notificationDebugBehaviorFreshDifferentPayload.
  ///
  /// In en, this message translates to:
  /// **'Treated as fresh when payload signature changes'**
  String get notificationDebugBehaviorFreshDifferentPayload;

  /// No description provided for @notificationDebugBehaviorSharedPayloadSig.
  ///
  /// In en, this message translates to:
  /// **'Same payload signature dedups even if id differs'**
  String get notificationDebugBehaviorSharedPayloadSig;

  /// No description provided for @notificationDebugBehaviorSimulateTap.
  ///
  /// In en, this message translates to:
  /// **'Routes through production dispatcher / bootstrap paths'**
  String get notificationDebugBehaviorSimulateTap;

  /// No description provided for @notificationDebugBehaviorInvalidLaunch.
  ///
  /// In en, this message translates to:
  /// **'Invalid payload must not set Athkar cold-start route'**
  String get notificationDebugBehaviorInvalidLaunch;

  /// No description provided for @notificationDebugBehaviorMarkProcessed.
  ///
  /// In en, this message translates to:
  /// **'Persists dedup without navigation'**
  String get notificationDebugBehaviorMarkProcessed;

  /// No description provided for @notificationDebugBehaviorClearPidScope.
  ///
  /// In en, this message translates to:
  /// **'Clears pid key to simulate fresh-process dedup scope'**
  String get notificationDebugBehaviorClearPidScope;

  /// No description provided for @notificationDebugFieldCurrentPid.
  ///
  /// In en, this message translates to:
  /// **'Current process id'**
  String get notificationDebugFieldCurrentPid;

  /// No description provided for @notificationDebugFieldStoredPid.
  ///
  /// In en, this message translates to:
  /// **'Stored pid (_last_notif_pid)'**
  String get notificationDebugFieldStoredPid;

  /// No description provided for @notificationDebugFieldStoredId.
  ///
  /// In en, this message translates to:
  /// **'Stored id (_last_notif_id)'**
  String get notificationDebugFieldStoredId;

  /// No description provided for @notificationDebugFieldStoredSig.
  ///
  /// In en, this message translates to:
  /// **'Stored signature (_last_notif_payload_sig)'**
  String get notificationDebugFieldStoredSig;

  /// No description provided for @notificationDebugFieldLastProcessedId.
  ///
  /// In en, this message translates to:
  /// **'AppRouter.lastProcessedNotificationId'**
  String get notificationDebugFieldLastProcessedId;

  /// No description provided for @notificationDebugFieldPendingRoute.
  ///
  /// In en, this message translates to:
  /// **'pendingColdStartLocation'**
  String get notificationDebugFieldPendingRoute;

  /// No description provided for @notificationDebugFieldPendingExtra.
  ///
  /// In en, this message translates to:
  /// **'pendingColdStartExtra'**
  String get notificationDebugFieldPendingExtra;

  /// No description provided for @notificationDebugFieldAthkarPayload.
  ///
  /// In en, this message translates to:
  /// **'last_handled_notification_payload'**
  String get notificationDebugFieldAthkarPayload;

  /// No description provided for @notificationDebugFieldAthkarTimestamp.
  ///
  /// In en, this message translates to:
  /// **'last_handled_notification_timestamp'**
  String get notificationDebugFieldAthkarTimestamp;

  /// No description provided for @notificationDebugFieldPreviewSig.
  ///
  /// In en, this message translates to:
  /// **'Preview signature'**
  String get notificationDebugFieldPreviewSig;

  /// No description provided for @notificationDebugFieldProcessedPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview is processed'**
  String get notificationDebugFieldProcessedPreview;

  /// No description provided for @notificationDebugChecklistAthkarTitle.
  ///
  /// In en, this message translates to:
  /// **'A. Athkar notification'**
  String get notificationDebugChecklistAthkarTitle;

  /// No description provided for @notificationDebugChecklistAthkarTap.
  ///
  /// In en, this message translates to:
  /// **'Tap Athkar notification → opens Athkar once'**
  String get notificationDebugChecklistAthkarTap;

  /// No description provided for @notificationDebugChecklistAthkarRestart.
  ///
  /// In en, this message translates to:
  /// **'Hot restart → must not open Athkar again'**
  String get notificationDebugChecklistAthkarRestart;

  /// No description provided for @notificationDebugChecklistPrayerTitle.
  ///
  /// In en, this message translates to:
  /// **'B. Prayer payload-only notification'**
  String get notificationDebugChecklistPrayerTitle;

  /// No description provided for @notificationDebugChecklistPrayerTap.
  ///
  /// In en, this message translates to:
  /// **'Tap Prayer notification → opens prayer route once'**
  String get notificationDebugChecklistPrayerTap;

  /// No description provided for @notificationDebugChecklistPrayerRestart.
  ///
  /// In en, this message translates to:
  /// **'Hot restart → must not replay'**
  String get notificationDebugChecklistPrayerRestart;

  /// No description provided for @notificationDebugChecklistInvalidTitle.
  ///
  /// In en, this message translates to:
  /// **'C. Invalid payload'**
  String get notificationDebugChecklistInvalidTitle;

  /// No description provided for @notificationDebugChecklistInvalidBody.
  ///
  /// In en, this message translates to:
  /// **'Invalid payload → must not fallback to Athkar'**
  String get notificationDebugChecklistInvalidBody;

  /// No description provided for @notificationDebugChecklistSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'D. Settings payload'**
  String get notificationDebugChecklistSettingsTitle;

  /// No description provided for @notificationDebugChecklistSettingsBody.
  ///
  /// In en, this message translates to:
  /// **'Settings payload → opens Settings, not Athkar'**
  String get notificationDebugChecklistSettingsBody;

  /// No description provided for @notificationDebugChecklistSameSigTitle.
  ///
  /// In en, this message translates to:
  /// **'E. Same id + same payload'**
  String get notificationDebugChecklistSameSigTitle;

  /// No description provided for @notificationDebugChecklistSameSigTap.
  ///
  /// In en, this message translates to:
  /// **'First tap → navigate once'**
  String get notificationDebugChecklistSameSigTap;

  /// No description provided for @notificationDebugChecklistSameSigRestart.
  ///
  /// In en, this message translates to:
  /// **'Hot restart / same process → suppressed'**
  String get notificationDebugChecklistSameSigRestart;

  /// No description provided for @notificationDebugChecklistDiffPayloadTitle.
  ///
  /// In en, this message translates to:
  /// **'F. Same id + different payload'**
  String get notificationDebugChecklistDiffPayloadTitle;

  /// No description provided for @notificationDebugChecklistDiffPayloadBody.
  ///
  /// In en, this message translates to:
  /// **'Treated as fresh launch'**
  String get notificationDebugChecklistDiffPayloadBody;

  /// No description provided for @notificationDebugChecklistDiffIdTitle.
  ///
  /// In en, this message translates to:
  /// **'G. Different id + same payload'**
  String get notificationDebugChecklistDiffIdTitle;

  /// No description provided for @notificationDebugChecklistDiffIdBody.
  ///
  /// In en, this message translates to:
  /// **'Payload signature wins → second tap suppressed in same pid'**
  String get notificationDebugChecklistDiffIdBody;

  /// No description provided for @notificationDebugChecklistKillTitle.
  ///
  /// In en, this message translates to:
  /// **'H. Full process kill'**
  String get notificationDebugChecklistKillTitle;

  /// No description provided for @notificationDebugChecklistKillSteps.
  ///
  /// In en, this message translates to:
  /// **'Kill app from recents → tap fresh notification → cold start navigation should work'**
  String get notificationDebugChecklistKillSteps;

  /// No description provided for @notificationDebugLogsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No debug events yet'**
  String get notificationDebugLogsEmpty;

  /// Snackbar message when a flexible in-app update finished downloading
  ///
  /// In en, this message translates to:
  /// **'Update downloaded. Restart when you are ready to install it.'**
  String get inAppUpdateFlexibleRestartMessage;

  /// Snackbar message when an optional app update is available
  ///
  /// In en, this message translates to:
  /// **'A new version of MeMuslim is available.'**
  String get inAppUpdateOptionalMessage;

  /// Snackbar message when a forced update must go through the Play Store
  ///
  /// In en, this message translates to:
  /// **'An update is required to continue using MeMuslim.'**
  String get inAppUpdateRequiredMessage;

  /// Snackbar action to install a downloaded flexible update
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get inAppUpdateRestartAction;

  /// Snackbar action to open the Play Store for an optional update
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get inAppUpdateUpdateAction;

  /// Title for the recitation practice panel
  ///
  /// In en, this message translates to:
  /// **'Practice {surah}:{ayah}'**
  String recitationPracticeTitle(int surah, int ayah);

  /// Starts microphone listening for recitation practice
  ///
  /// In en, this message translates to:
  /// **'Start reciting'**
  String get recitationPracticeStart;

  /// Stops microphone listening for recitation practice
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get recitationPracticeStop;

  /// Score label after comparing recitation
  ///
  /// In en, this message translates to:
  /// **'{percent}% match'**
  String recitationPracticeScore(int percent);

  /// Moves practice to the next ayah on the page
  ///
  /// In en, this message translates to:
  /// **'Next ayah'**
  String get recitationPracticeNextAyah;

  /// Tooltip for the Mushaf recitation practice button
  ///
  /// In en, this message translates to:
  /// **'Practice recitation'**
  String get recitationPracticeTooltip;

  /// Progress through ayahs on the current page during a session
  ///
  /// In en, this message translates to:
  /// **'Ayah {current} of {total}'**
  String recitationPracticeSessionProgress(int current, int total);

  /// Shown while the microphone is active during a session
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get recitationPracticeListening;

  /// Stops the hands-free recitation session
  ///
  /// In en, this message translates to:
  /// **'End session'**
  String get recitationPracticeEndSession;

  /// Shown when all ayahs on the page have been practiced
  ///
  /// In en, this message translates to:
  /// **'Page complete'**
  String get recitationPracticeSessionComplete;

  /// Summary of passed ayahs after a session
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} passed'**
  String recitationPracticeCompletedCount(int count, int total);

  /// Title when another device took over the active session
  ///
  /// In en, this message translates to:
  /// **'Signed out on another device'**
  String get authSignedInElsewhereTitle;

  /// Body when another device took over the active session
  ///
  /// In en, this message translates to:
  /// **'You were signed out because this account was used on another device.'**
  String get authSignedInElsewhereBody;

  /// Primary action after session revoked on this device
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get authSignedInElsewhereAction;

  /// Shown when Firebase auth succeeds but active-device registration fails
  ///
  /// In en, this message translates to:
  /// **'Sign-in could not be completed. Check your connection and try again.'**
  String get authDeviceRegistrationFailed;

  /// Sign-in device registration blocked by App Check in debug or profile builds
  ///
  /// In en, this message translates to:
  /// **'Sign-in was blocked because App Check is not set up for this build. In Firebase Console, open App Check, register a debug token for this device, then try again.'**
  String get authAppCheckFailedDebug;

  /// Sign-in device registration blocked by App Check in release builds
  ///
  /// In en, this message translates to:
  /// **'Sign-in could not be completed because this device could not be verified. Update the app and try again later.'**
  String get authAppCheckFailedRelease;

  /// Non-blocking banner shown while re-verifying the session after a transient auth/App Check hiccup
  ///
  /// In en, this message translates to:
  /// **'Verifying your session…'**
  String get authSessionVerifying;

  /// Manage Devices screen title
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get manageDevicesTitle;

  /// Manage Devices screen subtitle
  ///
  /// In en, this message translates to:
  /// **'You\'re signed in on these devices. Sign out any you don\'t recognize.'**
  String get manageDevicesSubtitle;

  /// Badge on the current device row
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get manageDevicesThisDevice;

  /// Badge on a revoked device row
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get manageDevicesSignedOutBadge;

  /// Per-device sign out action
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get manageDevicesSignOutDevice;

  /// Bottom action to sign out every other device
  ///
  /// In en, this message translates to:
  /// **'Sign out all other devices'**
  String get manageDevicesSignOutOthers;

  /// Confirm dialog body for sign out others
  ///
  /// In en, this message translates to:
  /// **'Sign out of every device except this one? You\'ll stay signed in here.'**
  String get manageDevicesSignOutOthersConfirm;

  /// Empty state when only the current device is present
  ///
  /// In en, this message translates to:
  /// **'No other devices are signed in.'**
  String get manageDevicesEmpty;

  /// Error state for the devices list
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your devices.'**
  String get manageDevicesError;

  /// Toast when a device sign-out write fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign out that device. Please try again.'**
  String get manageDevicesSignOutFailed;

  /// Relative last-active line on a device row
  ///
  /// In en, this message translates to:
  /// **'Last active {when}'**
  String manageDevicesLastActive(String when);

  /// Message shown on a device that was remotely signed out
  ///
  /// In en, this message translates to:
  /// **'This device was signed out.'**
  String get manageDevicesSignedOutMessage;

  /// Settings entry that opens Manage Devices
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get settingsManageDevicesTile;

  /// Settings group title for security/session options
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSecuritySection;

  /// Title of the Daily Wird home-screen widget
  ///
  /// In en, this message translates to:
  /// **'Today\'s Wird'**
  String get wirdWidgetTitle;

  /// Daily Wird widget copy when no plan exists
  ///
  /// In en, this message translates to:
  /// **'Start a calm Quran reading plan'**
  String get wirdWidgetNoPlanSubtitle;

  /// Daily Wird widget progress summary using preformatted numbers
  ///
  /// In en, this message translates to:
  /// **'{completed} of {assigned} pages completed · {remaining} remaining'**
  String wirdWidgetProgressSubtitle(
    String completed,
    String assigned,
    String remaining,
  );

  /// Daily Wird widget copy when today's target is complete
  ///
  /// In en, this message translates to:
  /// **'Today\'s Wird is complete'**
  String get wirdWidgetDayCompletedSubtitle;

  /// Daily Wird widget copy when the entire plan is complete
  ///
  /// In en, this message translates to:
  /// **'Khatma complete'**
  String get wirdWidgetPlanCompletedSubtitle;

  /// Badge on Settings profile when the signed-in user has the Firebase admin custom claim
  ///
  /// In en, this message translates to:
  /// **'Admin User'**
  String get settingsAdminUserBadge;
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

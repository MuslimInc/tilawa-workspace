import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'quran_image_localizations_ar.dart';
import 'quran_image_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of QuranImageLocalizations
/// returned by `QuranImageLocalizations.of(context)`.
///
/// Applications need to include `QuranImageLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/quran_image_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: QuranImageLocalizations.localizationsDelegates,
///   supportedLocales: QuranImageLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the QuranImageLocalizations.supportedLocales
/// property.
abstract class QuranImageLocalizations {
  QuranImageLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static QuranImageLocalizations of(BuildContext context) {
    return Localizations.of<QuranImageLocalizations>(
      context,
      QuranImageLocalizations,
    )!;
  }

  static const LocalizationsDelegate<QuranImageLocalizations> delegate =
      _QuranImageLocalizationsDelegate();

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

  /// No description provided for @preparingQuran.
  ///
  /// In en, this message translates to:
  /// **'Preparing the Quran for you…'**
  String get preparingQuran;

  /// No description provided for @quranReady.
  ///
  /// In en, this message translates to:
  /// **'The Quran is ready.'**
  String get quranReady;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again.'**
  String get networkError;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AlQuran'**
  String get appTitle;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @surahIndex.
  ///
  /// In en, this message translates to:
  /// **'Surah index'**
  String get surahIndex;

  /// No description provided for @juz.
  ///
  /// In en, this message translates to:
  /// **'Juz {number}'**
  String juz(int number);

  /// No description provided for @hizb.
  ///
  /// In en, this message translates to:
  /// **'Hizb {number}'**
  String hizb(int number);

  /// No description provided for @page.
  ///
  /// In en, this message translates to:
  /// **'Page {number}'**
  String page(String number);

  /// No description provided for @pageIndicator.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String pageIndicator(String current, String total);
}

class _QuranImageLocalizationsDelegate
    extends LocalizationsDelegate<QuranImageLocalizations> {
  const _QuranImageLocalizationsDelegate();

  @override
  Future<QuranImageLocalizations> load(Locale locale) {
    return SynchronousFuture<QuranImageLocalizations>(
      lookupQuranImageLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_QuranImageLocalizationsDelegate old) => false;
}

QuranImageLocalizations lookupQuranImageLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return QuranImageLocalizationsAr();
    case 'en':
      return QuranImageLocalizationsEn();
  }

  throw FlutterError(
    'QuranImageLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

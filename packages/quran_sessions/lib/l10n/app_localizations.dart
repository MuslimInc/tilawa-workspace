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
/// import 'l10n/app_localizations.dart';
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

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please try again.'**
  String get errorTimeout;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Please sign in again.'**
  String get errorSessionExpired;

  /// No description provided for @errorForbidden.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to perform this action.'**
  String get errorForbidden;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'A server error occurred. Please try again later.'**
  String get errorServer;

  /// No description provided for @unauthorized.
  ///
  /// In en, this message translates to:
  /// **'You are not authorized to perform this action.'**
  String get unauthorized;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'{resource} not found.'**
  String notFound(Object resource);

  /// No description provided for @validationError.
  ///
  /// In en, this message translates to:
  /// **'Validation error: {field} ({code}).'**
  String validationError(Object code, Object field);

  /// No description provided for @slotUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This slot is no longer available. Please choose another.'**
  String get slotUnavailable;

  /// No description provided for @bookingConflict.
  ///
  /// In en, this message translates to:
  /// **'You have another session at the same time.'**
  String get bookingConflict;

  /// No description provided for @profileIncompletePrefix.
  ///
  /// In en, this message translates to:
  /// **'Your profile is incomplete.'**
  String get profileIncompletePrefix;

  /// No description provided for @profileIncompleteFields.
  ///
  /// In en, this message translates to:
  /// **'Required information: {fields}.'**
  String profileIncompleteFields(Object fields);

  /// No description provided for @gender_male.
  ///
  /// In en, this message translates to:
  /// **'male'**
  String get gender_male;

  /// No description provided for @gender_female.
  ///
  /// In en, this message translates to:
  /// **'female'**
  String get gender_female;

  /// No description provided for @gender_male_students.
  ///
  /// In en, this message translates to:
  /// **'males'**
  String get gender_male_students;

  /// No description provided for @gender_female_students.
  ///
  /// In en, this message translates to:
  /// **'females'**
  String get gender_female_students;

  /// No description provided for @ageNotAllowedChild.
  ///
  /// In en, this message translates to:
  /// **'This teacher does not accept child students.'**
  String get ageNotAllowedChild;

  /// No description provided for @ageNotAllowedOther.
  ///
  /// In en, this message translates to:
  /// **'Your age group is not accepted by this teacher.'**
  String get ageNotAllowedOther;

  /// No description provided for @teacherNotVerified.
  ///
  /// In en, this message translates to:
  /// **'This teacher is not verified yet and cannot be booked.'**
  String get teacherNotVerified;

  /// No description provided for @accountBlockedWithReason.
  ///
  /// In en, this message translates to:
  /// **'Your account is suspended because: {reason}.'**
  String accountBlockedWithReason(Object reason);

  /// No description provided for @accountBlocked.
  ///
  /// In en, this message translates to:
  /// **'Your account is suspended. Please contact support.'**
  String get accountBlocked;

  /// No description provided for @guardianApprovalRequired.
  ///
  /// In en, this message translates to:
  /// **'Booking for this student requires guardian approval first.'**
  String get guardianApprovalRequired;

  /// No description provided for @policyViolation.
  ///
  /// In en, this message translates to:
  /// **'Booking rejected due to policy \"{policy}\": {detail}.'**
  String policyViolation(Object detail, Object policy);

  /// No description provided for @marketNotEnabledWithCity.
  ///
  /// In en, this message translates to:
  /// **'Sessions are not available in your city right now. Try another city.'**
  String get marketNotEnabledWithCity;

  /// No description provided for @marketNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Sessions are not available in your country right now.'**
  String get marketNotEnabled;

  /// No description provided for @teacherNotInMarket.
  ///
  /// In en, this message translates to:
  /// **'This teacher is not available in your area. Please choose another.'**
  String get teacherNotInMarket;

  /// No description provided for @teacherApplicationNotFound.
  ///
  /// In en, this message translates to:
  /// **'No teacher application was found.'**
  String get teacherApplicationNotFound;

  /// No description provided for @teacherApplicationAlreadyPending.
  ///
  /// In en, this message translates to:
  /// **'You already have a teacher application under review.'**
  String get teacherApplicationAlreadyPending;

  /// No description provided for @teacherApplicationRejected.
  ///
  /// In en, this message translates to:
  /// **'Your application was rejected. You may reapply after the cooldown.'**
  String get teacherApplicationRejected;

  /// No description provided for @teacherApplicationSuspended.
  ///
  /// In en, this message translates to:
  /// **'Your teacher application is temporarily suspended.'**
  String get teacherApplicationSuspended;

  /// No description provided for @teacherApplicationRevoked.
  ///
  /// In en, this message translates to:
  /// **'Your teacher application has been revoked.'**
  String get teacherApplicationRevoked;

  /// No description provided for @teacherPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'A phone number is required to complete the teacher application.'**
  String get teacherPhoneRequired;

  /// No description provided for @invalidTeacherPhone.
  ///
  /// In en, this message translates to:
  /// **'The phone number is invalid. Please enter a proper international number.'**
  String get invalidTeacherPhone;

  /// No description provided for @phoneCountryMismatch.
  ///
  /// In en, this message translates to:
  /// **'The phone number does not match the selected country.'**
  String get phoneCountryMismatch;

  /// No description provided for @invalidPhoneForSelectedCountry.
  ///
  /// In en, this message translates to:
  /// **'The phone number violates the selected country\'s rules.'**
  String get invalidPhoneForSelectedCountry;

  /// No description provided for @teacherApplicationIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Teacher application incomplete: {reason}'**
  String teacherApplicationIncomplete(Object reason);

  /// No description provided for @reapplicationTooSoon.
  ///
  /// In en, this message translates to:
  /// **'You cannot reapply before {date}.'**
  String reapplicationTooSoon(Object date);

  /// No description provided for @teacherProfileNotApproved.
  ///
  /// In en, this message translates to:
  /// **'The teacher profile is not approved yet.'**
  String get teacherProfileNotApproved;

  /// No description provided for @teacherProfileNotActive.
  ///
  /// In en, this message translates to:
  /// **'The teacher profile is not active.'**
  String get teacherProfileNotActive;

  /// No description provided for @paymentDeclined.
  ///
  /// In en, this message translates to:
  /// **'Payment was declined. Please use another method.'**
  String get paymentDeclined;

  /// No description provided for @paymentCancelled.
  ///
  /// In en, this message translates to:
  /// **'Payment was cancelled.'**
  String get paymentCancelled;

  /// No description provided for @paymentProviderFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to process payment. Please try again.'**
  String get paymentProviderFailure;

  /// No description provided for @cacheFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to read local data.'**
  String get cacheFailure;

  /// No description provided for @unknownFailure.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get unknownFailure;
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

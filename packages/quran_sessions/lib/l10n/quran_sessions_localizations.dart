import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'quran_sessions_localizations_ar.dart';
import 'quran_sessions_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of QuranSessionsLocalizations
/// returned by `QuranSessionsLocalizations.of(context)`.
///
/// Applications need to include `QuranSessionsLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/quran_sessions_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: QuranSessionsLocalizations.localizationsDelegates,
///   supportedLocales: QuranSessionsLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the QuranSessionsLocalizations.supportedLocales
/// property.
abstract class QuranSessionsLocalizations {
  QuranSessionsLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static QuranSessionsLocalizations of(BuildContext context) {
    return Localizations.of<QuranSessionsLocalizations>(
      context,
      QuranSessionsLocalizations,
    )!;
  }

  static const LocalizationsDelegate<QuranSessionsLocalizations> delegate =
      _QuranSessionsLocalizationsDelegate();

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

  /// No description provided for @marketCatalogEmpty.
  ///
  /// In en, this message translates to:
  /// **'Country and city options are not available yet. Please try again later or contact support.'**
  String get marketCatalogEmpty;

  /// No description provided for @teacherNotInMarket.
  ///
  /// In en, this message translates to:
  /// **'This teacher is not available in your area. Please choose another.'**
  String get teacherNotInMarket;

  /// No description provided for @dateOfBirthRequired.
  ///
  /// In en, this message translates to:
  /// **'Date of birth is required.'**
  String get dateOfBirthRequired;

  /// No description provided for @futureDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth cannot be in the future.'**
  String get futureDateOfBirth;

  /// No description provided for @dateOfBirthTooRecent.
  ///
  /// In en, this message translates to:
  /// **'Your age is not eligible for this feature yet.'**
  String get dateOfBirthTooRecent;

  /// No description provided for @invalidDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth is not valid. Please enter a valid date.'**
  String get invalidDateOfBirth;

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

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @profileCompletionTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete profile'**
  String get profileCompletionTitle;

  /// No description provided for @profileCompletionSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your profile was saved successfully.'**
  String get profileCompletionSavedSuccess;

  /// No description provided for @profileCompletionSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving your details…'**
  String get profileCompletionSaving;

  /// No description provided for @profileCompletionHeadline.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself'**
  String get profileCompletionHeadline;

  /// No description provided for @profileCompletionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We need this information to match you with the right teacher and show correct pricing for your region.'**
  String get profileCompletionSubtitle;

  /// No description provided for @profileFieldGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get profileFieldGender;

  /// No description provided for @profileFieldDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get profileFieldDateOfBirth;

  /// No description provided for @profileFieldCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get profileFieldCountry;

  /// No description provided for @profileFieldCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get profileFieldCity;

  /// No description provided for @profileFieldDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get profileFieldDisplayName;

  /// No description provided for @profileCompletionSaveAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Save and continue'**
  String get profileCompletionSaveAndContinue;

  /// No description provided for @profileCompletionSelectDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Select date of birth'**
  String get profileCompletionSelectDateOfBirth;

  /// No description provided for @profileCompletionSelectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select country'**
  String get profileCompletionSelectCountry;

  /// No description provided for @profileCompletionSelectCity.
  ///
  /// In en, this message translates to:
  /// **'Select city'**
  String get profileCompletionSelectCity;

  /// No description provided for @profileCompletionSelectCountryFirst.
  ///
  /// In en, this message translates to:
  /// **'Select country first'**
  String get profileCompletionSelectCountryFirst;

  /// No description provided for @profileCompletionLoadingCities.
  ///
  /// In en, this message translates to:
  /// **'Loading cities…'**
  String get profileCompletionLoadingCities;

  /// No description provided for @profileGenderRequired.
  ///
  /// In en, this message translates to:
  /// **'Gender is required.'**
  String get profileGenderRequired;

  /// No description provided for @profileCountryRequired.
  ///
  /// In en, this message translates to:
  /// **'Country is required.'**
  String get profileCountryRequired;

  /// No description provided for @profileCityRequired.
  ///
  /// In en, this message translates to:
  /// **'City is required.'**
  String get profileCityRequired;

  /// No description provided for @quranSessionsHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Learn Quran recitation'**
  String get quranSessionsHomeTitle;

  /// No description provided for @mySessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'My sessions'**
  String get mySessionsTitle;

  /// No description provided for @noTeachersAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'No teachers available yet'**
  String get noTeachersAvailableYet;

  /// No description provided for @seeAllTeachers.
  ///
  /// In en, this message translates to:
  /// **'See all teachers →'**
  String get seeAllTeachers;

  /// No description provided for @becomeTeacherCardTitle.
  ///
  /// In en, this message translates to:
  /// **'I want to become a teacher'**
  String get becomeTeacherCardTitle;

  /// No description provided for @becomeTeacherCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join MeMuslim\'s certified teachers'**
  String get becomeTeacherCardSubtitle;

  /// No description provided for @teacherListTitle.
  ///
  /// In en, this message translates to:
  /// **'Find a teacher'**
  String get teacherListTitle;

  /// No description provided for @noTeachersForSpecialization.
  ///
  /// In en, this message translates to:
  /// **'No teachers found for \"{specialization}\"'**
  String noTeachersForSpecialization(String specialization);

  /// No description provided for @noTeachersAvailableRightNow.
  ///
  /// In en, this message translates to:
  /// **'No teachers available right now'**
  String get noTeachersAvailableRightNow;

  /// No description provided for @bookSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Book a session'**
  String get bookSessionTitle;

  /// No description provided for @bookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed!'**
  String get bookingConfirmed;

  /// No description provided for @checkingEligibility.
  ///
  /// In en, this message translates to:
  /// **'Checking your eligibility…'**
  String get checkingEligibility;

  /// No description provided for @confirmingBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirming booking…'**
  String get confirmingBooking;

  /// No description provided for @selectSlot.
  ///
  /// In en, this message translates to:
  /// **'Choose a time'**
  String get selectSlot;

  /// No description provided for @sessionType.
  ///
  /// In en, this message translates to:
  /// **'Session type'**
  String get sessionType;

  /// No description provided for @confirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm booking'**
  String get confirmBooking;

  /// No description provided for @callTypeExternalMeeting.
  ///
  /// In en, this message translates to:
  /// **'External link'**
  String get callTypeExternalMeeting;

  /// No description provided for @callTypeVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get callTypeVoice;

  /// No description provided for @callTypeVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get callTypeVideo;

  /// No description provided for @sessionModeVoiceBetaNote.
  ///
  /// In en, this message translates to:
  /// **'Free Beta: voice uses a placeholder join until in-app RTC ships.'**
  String get sessionModeVoiceBetaNote;

  /// No description provided for @sessionModeVideoBetaNote.
  ///
  /// In en, this message translates to:
  /// **'Free Beta: video uses a placeholder join until in-app RTC ships.'**
  String get sessionModeVideoBetaNote;

  /// No description provided for @sessionModeVoiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Voice sessions are not available yet. Choose external link.'**
  String get sessionModeVoiceDisabled;

  /// No description provided for @sessionModeVideoDisabled.
  ///
  /// In en, this message translates to:
  /// **'Video sessions are not available yet. Choose external link.'**
  String get sessionModeVideoDisabled;

  /// No description provided for @sessionModeExternalDisabled.
  ///
  /// In en, this message translates to:
  /// **'Your teacher has not added a meeting link yet. Choose voice or video.'**
  String get sessionModeExternalDisabled;

  /// No description provided for @meetingLinkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This teacher has not set up a meeting link for external sessions. Choose voice or video, or try again later.'**
  String get meetingLinkUnavailable;

  /// No description provided for @callProviderUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This session cannot be joined from the app right now.'**
  String get callProviderUnavailable;

  /// No description provided for @rtcPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone or camera access is required to join this session. Enable {permission} in Settings and try again.'**
  String rtcPermissionDenied(String permission);

  /// No description provided for @rtcCallJoinFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the voice or video call. Try again in a moment.'**
  String get rtcCallJoinFailed;

  /// No description provided for @webrtcSignalingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'In-app WebRTC calls are not available yet. Choose voice with Agora or an external meeting link.'**
  String get webrtcSignalingUnavailable;

  /// No description provided for @inAppCallShellTitle.
  ///
  /// In en, this message translates to:
  /// **'Session call'**
  String get inAppCallShellTitle;

  /// No description provided for @inAppCallShellBody.
  ///
  /// In en, this message translates to:
  /// **'You are connected to this session\'s call room. End the call when your lesson finishes.'**
  String get inAppCallShellBody;

  /// No description provided for @inAppCallShellEndCall.
  ///
  /// In en, this message translates to:
  /// **'Leave call'**
  String get inAppCallShellEndCall;

  /// No description provided for @inAppCallShellMute.
  ///
  /// In en, this message translates to:
  /// **'Mute microphone'**
  String get inAppCallShellMute;

  /// No description provided for @inAppCallShellUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute microphone'**
  String get inAppCallShellUnmute;

  /// No description provided for @inAppCallShellConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get inAppCallShellConnecting;

  /// No description provided for @inAppCallShellConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get inAppCallShellConnected;

  /// No description provided for @inAppCallShellWaitingForParticipant.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the other participant'**
  String get inAppCallShellWaitingForParticipant;

  /// No description provided for @inAppCallShellMockBetaBody.
  ///
  /// In en, this message translates to:
  /// **'Beta preview — no live audio or video. Book a new session with Agora enabled to try a real call.'**
  String get inAppCallShellMockBetaBody;

  /// No description provided for @externalMeetingJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join outside MeMuslim?'**
  String get externalMeetingJoinTitle;

  /// No description provided for @externalMeetingJoinBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll briefly leave MeMuslim to join your session in Google Meet, Zoom, or your browser. Come back here anytime — your session details stay open.'**
  String get externalMeetingJoinBody;

  /// No description provided for @externalMeetingJoinOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get externalMeetingJoinOpen;

  /// No description provided for @externalMeetingJoinCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy URL'**
  String get externalMeetingJoinCopy;

  /// No description provided for @externalMeetingJoinLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get externalMeetingJoinLinkCopied;

  /// No description provided for @externalMeetingJoinAgain.
  ///
  /// In en, this message translates to:
  /// **'Open meeting again'**
  String get externalMeetingJoinAgain;

  /// No description provided for @externalMeetingLaunchFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the meeting link. Try again or copy the link.'**
  String get externalMeetingLaunchFailed;

  /// No description provided for @externalMeetingLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Meeting link copied. Paste it in your browser to join.'**
  String get externalMeetingLinkCopied;

  /// No description provided for @groupBookingNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Group sessions are not available in Free Beta.'**
  String get groupBookingNotSupported;

  /// No description provided for @unsupportedSessionMode.
  ///
  /// In en, this message translates to:
  /// **'This session type is not supported.'**
  String get unsupportedSessionMode;

  /// No description provided for @reviewSubmittedThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you — your review was submitted!'**
  String get reviewSubmittedThanks;

  /// No description provided for @upcomingSessionsSection.
  ///
  /// In en, this message translates to:
  /// **'Upcoming ({count})'**
  String upcomingSessionsSection(int count);

  /// No description provided for @noUpcomingSessions.
  ///
  /// In en, this message translates to:
  /// **'No upcoming sessions'**
  String get noUpcomingSessions;

  /// No description provided for @pastSessionsSection.
  ///
  /// In en, this message translates to:
  /// **'Past ({count})'**
  String pastSessionsSection(int count);

  /// No description provided for @noPastSessions.
  ///
  /// In en, this message translates to:
  /// **'No past sessions'**
  String get noPastSessions;

  /// No description provided for @cancelSessionDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel session?'**
  String get cancelSessionDialogTitle;

  /// No description provided for @cancelSessionDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get cancelSessionDialogMessage;

  /// No description provided for @keepSession.
  ///
  /// In en, this message translates to:
  /// **'Keep session'**
  String get keepSession;

  /// No description provided for @cancelSessionAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel session'**
  String get cancelSessionAction;

  /// No description provided for @cancelReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason for cancellation'**
  String get cancelReasonLabel;

  /// No description provided for @cancelReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us why you need to cancel (required)'**
  String get cancelReasonHint;

  /// No description provided for @cancelReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter at least 3 characters.'**
  String get cancelReasonRequired;

  /// No description provided for @cancelPolicyBlockedNotice.
  ///
  /// In en, this message translates to:
  /// **'Cancellation is not allowed this close to the session start time.'**
  String get cancelPolicyBlockedNotice;

  /// No description provided for @cancelPolicyFree.
  ///
  /// In en, this message translates to:
  /// **'This is a free session. No refund applies.'**
  String get cancelPolicyFree;

  /// No description provided for @cancelPolicyFullRefund.
  ///
  /// In en, this message translates to:
  /// **'You will receive a full refund if you cancel now.'**
  String get cancelPolicyFullRefund;

  /// No description provided for @cancelPolicyPartialRefund.
  ///
  /// In en, this message translates to:
  /// **'A partial refund may apply based on our cancellation policy.'**
  String get cancelPolicyPartialRefund;

  /// No description provided for @cancelPolicyNoRefund.
  ///
  /// In en, this message translates to:
  /// **'No refund applies for cancellations at this time.'**
  String get cancelPolicyNoRefund;

  /// No description provided for @rescheduleSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Reschedule session'**
  String get rescheduleSessionTitle;

  /// No description provided for @rescheduleReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason for rescheduling'**
  String get rescheduleReasonLabel;

  /// No description provided for @rescheduleReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Briefly explain why you need a new time'**
  String get rescheduleReasonHint;

  /// No description provided for @rescheduleSubmitAction.
  ///
  /// In en, this message translates to:
  /// **'Request reschedule'**
  String get rescheduleSubmitAction;

  /// No description provided for @rescheduleRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Reschedule request sent. Waiting for confirmation.'**
  String get rescheduleRequestSubmitted;

  /// No description provided for @rescheduleAwaitingCounterparty.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the other participant to confirm your new time.'**
  String get rescheduleAwaitingCounterparty;

  /// No description provided for @reschedulePendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Reschedule request'**
  String get reschedulePendingTitle;

  /// No description provided for @reschedulePendingProposedTime.
  ///
  /// In en, this message translates to:
  /// **'Proposed time: {dateTime}'**
  String reschedulePendingProposedTime(String dateTime);

  /// No description provided for @reschedulePendingReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String reschedulePendingReason(String reason);

  /// No description provided for @rescheduleAcceptAction.
  ///
  /// In en, this message translates to:
  /// **'Accept new time'**
  String get rescheduleAcceptAction;

  /// No description provided for @rescheduleRejectAction.
  ///
  /// In en, this message translates to:
  /// **'Keep current time'**
  String get rescheduleRejectAction;

  /// No description provided for @rescheduleAcceptedToast.
  ///
  /// In en, this message translates to:
  /// **'Reschedule accepted. Session time updated.'**
  String get rescheduleAcceptedToast;

  /// No description provided for @rescheduleRejectedToast.
  ///
  /// In en, this message translates to:
  /// **'Reschedule declined. Original time kept.'**
  String get rescheduleRejectedToast;

  /// No description provided for @rescheduleAction.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get rescheduleAction;

  /// No description provided for @sessionDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Session details'**
  String get sessionDetailTitle;

  /// No description provided for @sessionTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity timeline'**
  String get sessionTimelineTitle;

  /// No description provided for @sessionTimelineEmpty.
  ///
  /// In en, this message translates to:
  /// **'No activity recorded yet.'**
  String get sessionTimelineEmpty;

  /// No description provided for @sessionTimelineLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the activity timeline. Check your connection and try again.'**
  String get sessionTimelineLoadFailed;

  /// No description provided for @sessionPendingRescheduleLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the pending reschedule request. Try again in a moment.'**
  String get sessionPendingRescheduleLoadFailed;

  /// No description provided for @sessionLockedAtBookingNote.
  ///
  /// In en, this message translates to:
  /// **'Call type ({callType}) and provider ({callProvider}) were set when you booked. To change them, cancel and rebook or contact support.'**
  String sessionLockedAtBookingNote(String callType, String callProvider);

  /// No description provided for @callProviderExternal.
  ///
  /// In en, this message translates to:
  /// **'External link'**
  String get callProviderExternal;

  /// No description provided for @callProviderMock.
  ///
  /// In en, this message translates to:
  /// **'In-app (preview)'**
  String get callProviderMock;

  /// No description provided for @callProviderAgora.
  ///
  /// In en, this message translates to:
  /// **'In-app (Agora)'**
  String get callProviderAgora;

  /// No description provided for @callProviderWebrtc.
  ///
  /// In en, this message translates to:
  /// **'In-app (WebRTC)'**
  String get callProviderWebrtc;

  /// No description provided for @sessionStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String sessionStatusLabel(String status);

  /// No description provided for @sessionStartsAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Starts: {when}'**
  String sessionStartsAtLabel(String when);

  /// No description provided for @viewSessionDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewSessionDetails;

  /// No description provided for @noSessionsYet.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet'**
  String get noSessionsYet;

  /// No description provided for @bookFirstSessionHint.
  ///
  /// In en, this message translates to:
  /// **'Book your first session with one of our certified teachers'**
  String get bookFirstSessionHint;

  /// No description provided for @teacherProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Teacher profile'**
  String get teacherProfileTitle;

  /// No description provided for @teacherRatingReviews.
  ///
  /// In en, this message translates to:
  /// **'{rating} · {count} reviews'**
  String teacherRatingReviews(String rating, int count);

  /// No description provided for @availableSlots.
  ///
  /// In en, this message translates to:
  /// **'Available slots'**
  String get availableSlots;

  /// No description provided for @reviewsSection.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviewsSection;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYet;

  /// No description provided for @bookSessionAction.
  ///
  /// In en, this message translates to:
  /// **'Book a session'**
  String get bookSessionAction;

  /// No description provided for @sessionStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get sessionStatusScheduled;

  /// No description provided for @sessionStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get sessionStatusInProgress;

  /// No description provided for @sessionStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get sessionStatusCompleted;

  /// No description provided for @sessionStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get sessionStatusCancelled;

  /// No description provided for @sessionStatusNoShow.
  ///
  /// In en, this message translates to:
  /// **'No-show'**
  String get sessionStatusNoShow;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @joinSession.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinSession;

  /// No description provided for @noSlotsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No slots available'**
  String get noSlotsAvailable;

  /// No description provided for @noSlotsAvailableThisDay.
  ///
  /// In en, this message translates to:
  /// **'No slots available on this day'**
  String get noSlotsAvailableThisDay;

  /// No description provided for @teacherDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Teacher dashboard'**
  String get teacherDashboardTitle;

  /// No description provided for @noSessionsOrSlotsYet.
  ///
  /// In en, this message translates to:
  /// **'No sessions or slots yet'**
  String get noSessionsOrSlotsYet;

  /// No description provided for @addAvailableSlot.
  ///
  /// In en, this message translates to:
  /// **'Add available slot'**
  String get addAvailableSlot;

  /// No description provided for @openSlotsSection.
  ///
  /// In en, this message translates to:
  /// **'Open slots ({count})'**
  String openSlotsSection(int count);

  /// No description provided for @addSlot.
  ///
  /// In en, this message translates to:
  /// **'Add slot'**
  String get addSlot;

  /// No description provided for @noOpenSlots.
  ///
  /// In en, this message translates to:
  /// **'No open slots'**
  String get noOpenSlots;

  /// No description provided for @slotBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get slotBooked;

  /// No description provided for @slotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get slotAvailable;

  /// No description provided for @editSlot.
  ///
  /// In en, this message translates to:
  /// **'Edit slot'**
  String get editSlot;

  /// No description provided for @deleteSlot.
  ///
  /// In en, this message translates to:
  /// **'Block this time'**
  String get deleteSlot;

  /// No description provided for @deleteSlotConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Block this time?'**
  String get deleteSlotConfirmTitle;

  /// No description provided for @deleteSlotConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Students will no longer be able to book this time. Tap Undo on the snackbar to restore it.'**
  String get deleteSlotConfirmMessage;

  /// No description provided for @deleteSlotConfirm.
  ///
  /// In en, this message translates to:
  /// **'Block time'**
  String get deleteSlotConfirm;

  /// No description provided for @deleteSlotSuccess.
  ///
  /// In en, this message translates to:
  /// **'Time blocked'**
  String get deleteSlotSuccess;

  /// No description provided for @deleteSlotUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get deleteSlotUndo;

  /// No description provided for @deleteSlotRemovedSnackBar.
  ///
  /// In en, this message translates to:
  /// **'Blocked {time}'**
  String deleteSlotRemovedSnackBar(String time);

  /// No description provided for @deleteSlotRemovedSnackBarWithPending.
  ///
  /// In en, this message translates to:
  /// **'Blocked {time} ({count} pending)'**
  String deleteSlotRemovedSnackBarWithPending(String time, int count);

  /// No description provided for @deleteSlotRefreshDiscarded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pending block was discarded — slots restored} other{{count} pending blocks were discarded — slots restored}}'**
  String deleteSlotRefreshDiscarded(int count);

  /// No description provided for @addNewSlot.
  ///
  /// In en, this message translates to:
  /// **'Add new slot'**
  String get addNewSlot;

  /// No description provided for @slotDate.
  ///
  /// In en, this message translates to:
  /// **'Slot date'**
  String get slotDate;

  /// No description provided for @slotTime.
  ///
  /// In en, this message translates to:
  /// **'Slot time'**
  String get slotTime;

  /// No description provided for @addSlotButton.
  ///
  /// In en, this message translates to:
  /// **'Add slot'**
  String get addSlotButton;

  /// No description provided for @availabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly availability'**
  String get availabilityTitle;

  /// No description provided for @availabilityRecurringBanner.
  ///
  /// In en, this message translates to:
  /// **'This is your recurring weekly availability. It is used to generate bookable times for future days.'**
  String get availabilityRecurringBanner;

  /// No description provided for @bookableTimesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Bookable times — next 14 days'**
  String get bookableTimesSectionTitle;

  /// No description provided for @bookableTimesSectionSubtext.
  ///
  /// In en, this message translates to:
  /// **'Generated from your weekly availability, minus exceptions and bookings.'**
  String get bookableTimesSectionSubtext;

  /// No description provided for @bookableTimesThisWeekSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get bookableTimesThisWeekSectionTitle;

  /// No description provided for @bookableTimesNextWeekSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get bookableTimesNextWeekSectionTitle;

  /// No description provided for @bookableTimesWeekScopedTitle.
  ///
  /// In en, this message translates to:
  /// **'Bookable times'**
  String get bookableTimesWeekScopedTitle;

  /// No description provided for @bookableTimesSelectedDayCaption.
  ///
  /// In en, this message translates to:
  /// **'Showing times for {dayLabel}'**
  String bookableTimesSelectedDayCaption(String dayLabel);

  /// No description provided for @bookableTimesEmptyThisWeek.
  ///
  /// In en, this message translates to:
  /// **'No bookable times this week.'**
  String get bookableTimesEmptyThisWeek;

  /// No description provided for @bookableTimesEmptyNextWeek.
  ///
  /// In en, this message translates to:
  /// **'No bookable times next week.'**
  String get bookableTimesEmptyNextWeek;

  /// No description provided for @bookableTimesEmptyThisWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'No bookable times this week'**
  String get bookableTimesEmptyThisWeekTitle;

  /// No description provided for @bookableTimesEmptyThisWeekSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open days in your weekly template become slots here. Adjust your hours or check exceptions if you expected times.'**
  String get bookableTimesEmptyThisWeekSubtitle;

  /// No description provided for @bookableTimesEmptyNextWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'No bookable times next week'**
  String get bookableTimesEmptyNextWeekTitle;

  /// No description provided for @bookableTimesEmptyNextWeekSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Next week is built from your recurring weekly availability. Review your template to add or change days.'**
  String get bookableTimesEmptyNextWeekSubtitle;

  /// No description provided for @bookableTimesEmptyHorizonTitle.
  ///
  /// In en, this message translates to:
  /// **'No bookable times in the next 14 days'**
  String get bookableTimesEmptyHorizonTitle;

  /// No description provided for @bookableTimesEmptyHorizonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your recurring weekly availability and open days will appear here automatically.'**
  String get bookableTimesEmptyHorizonSubtitle;

  /// No description provided for @upcomingSessionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No upcoming sessions'**
  String get upcomingSessionsEmptyTitle;

  /// No description provided for @upcomingSessionsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Confirmed bookings will appear here when students reserve a time with you.'**
  String get upcomingSessionsEmptySubtitle;

  /// No description provided for @fridayReviewBannerMessage.
  ///
  /// In en, this message translates to:
  /// **'Review next week\'s availability. Students book from your weekly template.'**
  String get fridayReviewBannerMessage;

  /// No description provided for @fridayReviewBannerAction.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get fridayReviewBannerAction;

  /// No description provided for @fridayReviewBannerDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get fridayReviewBannerDismiss;

  /// No description provided for @editWeeklyTemplate.
  ///
  /// In en, this message translates to:
  /// **'Edit weekly template'**
  String get editWeeklyTemplate;

  /// No description provided for @availabilityTabHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get availabilityTabHours;

  /// No description provided for @availabilityTabOverrides.
  ///
  /// In en, this message translates to:
  /// **'Overrides'**
  String get availabilityTabOverrides;

  /// No description provided for @availabilityUseSameHours.
  ///
  /// In en, this message translates to:
  /// **'Use same hours for all days'**
  String get availabilityUseSameHours;

  /// No description provided for @availabilityTimezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get availabilityTimezone;

  /// No description provided for @availabilitySessionLength.
  ///
  /// In en, this message translates to:
  /// **'Session length'**
  String get availabilitySessionLength;

  /// No description provided for @availabilityDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String availabilityDurationMinutes(int count);

  /// No description provided for @availabilityHoursRow.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get availabilityHoursRow;

  /// No description provided for @availabilityDayClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get availabilityDayClosed;

  /// No description provided for @availabilityAddRange.
  ///
  /// In en, this message translates to:
  /// **'Add range'**
  String get availabilityAddRange;

  /// No description provided for @availabilityEditRange.
  ///
  /// In en, this message translates to:
  /// **'Edit range'**
  String get availabilityEditRange;

  /// No description provided for @availabilityRemoveRange.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get availabilityRemoveRange;

  /// No description provided for @availabilitySave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get availabilitySave;

  /// No description provided for @availabilitySavedToast.
  ///
  /// In en, this message translates to:
  /// **'Schedule saved'**
  String get availabilitySavedToast;

  /// No description provided for @availabilityOverrideRemovedToast.
  ///
  /// In en, this message translates to:
  /// **'Date override removed'**
  String get availabilityOverrideRemovedToast;

  /// No description provided for @availabilityOverrideAddedToast.
  ///
  /// In en, this message translates to:
  /// **'Date override added'**
  String get availabilityOverrideAddedToast;

  /// No description provided for @availabilityDeleteVacationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete vacation?'**
  String get availabilityDeleteVacationTitle;

  /// No description provided for @availabilityDeleteVacationMessage.
  ///
  /// In en, this message translates to:
  /// **'These dates will become available for students to book again.'**
  String get availabilityDeleteVacationMessage;

  /// No description provided for @availabilityDeleteVacationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete vacation'**
  String get availabilityDeleteVacationConfirm;

  /// No description provided for @availabilityVacationOverlapError.
  ///
  /// In en, this message translates to:
  /// **'These dates overlap an existing vacation. Adjust the range or remove the existing vacation first.'**
  String get availabilityVacationOverlapError;

  /// No description provided for @availabilityUnsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get availabilityUnsavedChanges;

  /// No description provided for @availabilityLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your schedule'**
  String get availabilityLoadError;

  /// No description provided for @availabilityStartTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get availabilityStartTime;

  /// No description provided for @availabilityEndTime.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get availabilityEndTime;

  /// No description provided for @availabilityUseTheseTimes.
  ///
  /// In en, this message translates to:
  /// **'Use these times'**
  String get availabilityUseTheseTimes;

  /// No description provided for @availabilityRangeInvalid.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time'**
  String get availabilityRangeInvalid;

  /// No description provided for @availabilityRangeOverlap.
  ///
  /// In en, this message translates to:
  /// **'This range overlaps another'**
  String get availabilityRangeOverlap;

  /// No description provided for @availabilityNoOpenDaysError.
  ///
  /// In en, this message translates to:
  /// **'Select at least one day with working hours'**
  String get availabilityNoOpenDaysError;

  /// No description provided for @availabilityOverridesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No date overrides yet'**
  String get availabilityOverridesEmpty;

  /// No description provided for @availabilityOverridesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Block a day off or add special hours for a specific date.'**
  String get availabilityOverridesEmptyHint;

  /// No description provided for @availabilityAddOverride.
  ///
  /// In en, this message translates to:
  /// **'Add date override'**
  String get availabilityAddOverride;

  /// No description provided for @availabilityOverrideUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable (day off)'**
  String get availabilityOverrideUnavailable;

  /// No description provided for @availabilityOverrideCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom hours'**
  String get availabilityOverrideCustom;

  /// No description provided for @availabilityOverrideDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get availabilityOverrideDate;

  /// No description provided for @availabilityOverrideStartDate.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get availabilityOverrideStartDate;

  /// No description provided for @availabilityOverrideEndDate.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get availabilityOverrideEndDate;

  /// No description provided for @availabilityOverrideEndDateInvalid.
  ///
  /// In en, this message translates to:
  /// **'End date must be on or after start date'**
  String get availabilityOverrideEndDateInvalid;

  /// No description provided for @availabilitySetupHeadline.
  ///
  /// In en, this message translates to:
  /// **'Set your hours once and students can book automatically'**
  String get availabilitySetupHeadline;

  /// No description provided for @availabilitySetupCta.
  ///
  /// In en, this message translates to:
  /// **'Set up weekly schedule'**
  String get availabilitySetupCta;

  /// No description provided for @availabilitySetupBenefitRecurring.
  ///
  /// In en, this message translates to:
  /// **'No manual repetition'**
  String get availabilitySetupBenefitRecurring;

  /// No description provided for @availabilitySetupBenefitTimezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone-aware'**
  String get availabilitySetupBenefitTimezone;

  /// No description provided for @availabilitySetupBenefitSelfBooking.
  ///
  /// In en, this message translates to:
  /// **'Students book themselves'**
  String get availabilitySetupBenefitSelfBooking;

  /// No description provided for @availabilityTimezonePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose timezone'**
  String get availabilityTimezonePickerTitle;

  /// No description provided for @availabilityDiscardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get availabilityDiscardChanges;

  /// No description provided for @availabilityDiscardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get availabilityDiscardConfirm;

  /// No description provided for @availabilityKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get availabilityKeepEditing;

  /// No description provided for @weekdaySaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get weekdaySaturday;

  /// No description provided for @weekdaySunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get weekdaySunday;

  /// No description provided for @weekdayMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get weekdayMonday;

  /// No description provided for @weekdayTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get weekdayTuesday;

  /// No description provided for @weekdayWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get weekdayWednesday;

  /// No description provided for @weekdayThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get weekdayThursday;

  /// No description provided for @weekdayFriday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get weekdayFriday;

  /// No description provided for @teacherApplicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Teacher application'**
  String get teacherApplicationTitle;

  /// No description provided for @submittingApplication.
  ///
  /// In en, this message translates to:
  /// **'Submitting application…'**
  String get submittingApplication;

  /// No description provided for @becomeTeacherOnTilawa.
  ///
  /// In en, this message translates to:
  /// **'Become a teacher on MeMuslim'**
  String get becomeTeacherOnTilawa;

  /// No description provided for @becomeTeacherApplicationIntro.
  ///
  /// In en, this message translates to:
  /// **'Join our certified teachers and help students on their Quran journey.'**
  String get becomeTeacherApplicationIntro;

  /// No description provided for @startApplication.
  ///
  /// In en, this message translates to:
  /// **'Start application'**
  String get startApplication;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @phoneNumberRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'Required for identity verification. Visible to admin only.'**
  String get phoneNumberRequiredHint;

  /// No description provided for @preferredContactMethod.
  ///
  /// In en, this message translates to:
  /// **'Preferred contact method'**
  String get preferredContactMethod;

  /// No description provided for @teachingLanguages.
  ///
  /// In en, this message translates to:
  /// **'Teaching languages'**
  String get teachingLanguages;

  /// No description provided for @teachingLanguagesSelect.
  ///
  /// In en, this message translates to:
  /// **'Teaching languages * (select one or more)'**
  String get teachingLanguagesSelect;

  /// No description provided for @specializations.
  ///
  /// In en, this message translates to:
  /// **'Specializations'**
  String get specializations;

  /// No description provided for @specializationsSelect.
  ///
  /// In en, this message translates to:
  /// **'Specializations * (select one or more)'**
  String get specializationsSelect;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @bioSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Bio *'**
  String get bioSectionTitle;

  /// No description provided for @bioHint.
  ///
  /// In en, this message translates to:
  /// **'Tell students about your experience, qualifications, and teaching style…'**
  String get bioHint;

  /// No description provided for @submitApplicationForReview.
  ///
  /// In en, this message translates to:
  /// **'Submit application for review'**
  String get submitApplicationForReview;

  /// No description provided for @countryCode.
  ///
  /// In en, this message translates to:
  /// **'Country code'**
  String get countryCode;

  /// No description provided for @contactWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get contactWhatsapp;

  /// No description provided for @contactPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get contactPhone;

  /// No description provided for @contactEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get contactEmail;

  /// No description provided for @teachingLanguage_ar.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get teachingLanguage_ar;

  /// No description provided for @teachingLanguage_en.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get teachingLanguage_en;

  /// No description provided for @teachingLanguage_ur.
  ///
  /// In en, this message translates to:
  /// **'Urdu'**
  String get teachingLanguage_ur;

  /// No description provided for @teachingLanguage_fr.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get teachingLanguage_fr;

  /// No description provided for @teachingLanguage_tr.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get teachingLanguage_tr;

  /// No description provided for @teachingLanguage_ms.
  ///
  /// In en, this message translates to:
  /// **'Malay'**
  String get teachingLanguage_ms;

  /// No description provided for @specialization_tajweed.
  ///
  /// In en, this message translates to:
  /// **'Tajweed'**
  String get specialization_tajweed;

  /// No description provided for @specialization_recitation.
  ///
  /// In en, this message translates to:
  /// **'Recitation'**
  String get specialization_recitation;

  /// No description provided for @specialization_hifz.
  ///
  /// In en, this message translates to:
  /// **'Memorisation'**
  String get specialization_hifz;

  /// No description provided for @specialization_review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get specialization_review;

  /// No description provided for @specialization_children.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get specialization_children;

  /// No description provided for @specialization_qaida.
  ///
  /// In en, this message translates to:
  /// **'Qaida'**
  String get specialization_qaida;

  /// No description provided for @specialization_tafsir.
  ///
  /// In en, this message translates to:
  /// **'Tafsir'**
  String get specialization_tafsir;

  /// No description provided for @specialization_arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get specialization_arabic;

  /// No description provided for @applicationStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Application status'**
  String get applicationStatusTitle;

  /// No description provided for @unknownStatus.
  ///
  /// In en, this message translates to:
  /// **'Unknown status'**
  String get unknownStatus;

  /// No description provided for @applicationStatusPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Your application is under review'**
  String get applicationStatusPendingTitle;

  /// No description provided for @applicationStatusPendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The MeMuslim team is reviewing your application. We will contact you soon.'**
  String get applicationStatusPendingSubtitle;

  /// No description provided for @applicationStatusApprovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! Approved'**
  String get applicationStatusApprovedTitle;

  /// No description provided for @applicationStatusApprovedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You are now a certified teacher on MeMuslim.'**
  String get applicationStatusApprovedSubtitle;

  /// No description provided for @applicationStatusApprovedContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get applicationStatusApprovedContinue;

  /// No description provided for @applicationStatusRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Application not approved'**
  String get applicationStatusRejectedTitle;

  /// No description provided for @applicationStatusRejectedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You may reapply after reviewing the team\'s feedback.'**
  String get applicationStatusRejectedSubtitle;

  /// No description provided for @applicationStatusSuspendedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account temporarily suspended'**
  String get applicationStatusSuspendedTitle;

  /// No description provided for @applicationStatusSuspendedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Contact support to ask about the suspension.'**
  String get applicationStatusSuspendedSubtitle;

  /// No description provided for @applicationStatusRevokedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account revoked'**
  String get applicationStatusRevokedTitle;

  /// No description provided for @applicationStatusRevokedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You cannot apply again. Contact support for more information.'**
  String get applicationStatusRevokedSubtitle;

  /// No description provided for @submittedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submittedAtLabel;

  /// No description provided for @reviewedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get reviewedAtLabel;

  /// No description provided for @reasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reasonLabel;

  /// No description provided for @labelWithColon.
  ///
  /// In en, this message translates to:
  /// **'{label}:'**
  String labelWithColon(String label);

  /// No description provided for @debugModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Development mode'**
  String get debugModeTitle;

  /// No description provided for @debugApprovalDescription.
  ///
  /// In en, this message translates to:
  /// **'This button is for internal testing only and does not appear in production. It simulates admin approval without an admin interface.'**
  String get debugApprovalDescription;

  /// No description provided for @simulateAdminApproval.
  ///
  /// In en, this message translates to:
  /// **'Simulate admin approval'**
  String get simulateAdminApproval;

  /// No description provided for @priceFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get priceFree;

  /// No description provided for @pricePerSession.
  ///
  /// In en, this message translates to:
  /// **'{amount} / session'**
  String pricePerSession(String amount);

  /// No description provided for @teachingOnMemuslimTitle.
  ///
  /// In en, this message translates to:
  /// **'Teaching on MeMuslim'**
  String get teachingOnMemuslimTitle;

  /// No description provided for @teachingOnMemuslimApply.
  ///
  /// In en, this message translates to:
  /// **'Apply as a teacher'**
  String get teachingOnMemuslimApply;

  /// No description provided for @teachingOnMemuslimContinueDraft.
  ///
  /// In en, this message translates to:
  /// **'Continue registration'**
  String get teachingOnMemuslimContinueDraft;

  /// No description provided for @teachingOnMemuslimViewStatus.
  ///
  /// In en, this message translates to:
  /// **'View application status'**
  String get teachingOnMemuslimViewStatus;

  /// No description provided for @teachingOnMemuslimTeacherDashboard.
  ///
  /// In en, this message translates to:
  /// **'Teacher dashboard'**
  String get teachingOnMemuslimTeacherDashboard;

  /// No description provided for @teachingOnMemuslimOpenDashboard.
  ///
  /// In en, this message translates to:
  /// **'Open teacher dashboard'**
  String get teachingOnMemuslimOpenDashboard;

  /// No description provided for @teachingOnMemuslimManageScheduleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your schedule and sessions from here.'**
  String get teachingOnMemuslimManageScheduleSubtitle;

  /// No description provided for @teachingOnMemuslimReapplySubtitle.
  ///
  /// In en, this message translates to:
  /// **'View details or reapply when allowed.'**
  String get teachingOnMemuslimReapplySubtitle;

  /// No description provided for @verifiedTeacherBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified Teacher'**
  String get verifiedTeacherBadge;

  /// No description provided for @teacherCapabilityStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get teacherCapabilityStatusDraft;

  /// No description provided for @teacherCapabilityStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get teacherCapabilityStatusPending;

  /// No description provided for @teacherCapabilityStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get teacherCapabilityStatusRejected;

  /// No description provided for @teacherCapabilityStatusSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get teacherCapabilityStatusSuspended;

  /// No description provided for @teacherCapabilityStatusRevoked.
  ///
  /// In en, this message translates to:
  /// **'Accreditation revoked'**
  String get teacherCapabilityStatusRevoked;

  /// No description provided for @teachingOnMemuslimNotAppliedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Apply to join our verified teacher community after team review.'**
  String get teachingOnMemuslimNotAppliedSubtitle;

  /// No description provided for @teachingOnMemuslimPendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your application is under review. We will contact you soon.'**
  String get teachingOnMemuslimPendingSubtitle;

  /// No description provided for @teachingOnMemuslimApprovedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your application was approved. Manage sessions from the teacher dashboard.'**
  String get teachingOnMemuslimApprovedSubtitle;

  /// No description provided for @teachingOnMemuslimRejectedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your application was not approved. View details and reapply when allowed.'**
  String get teachingOnMemuslimRejectedSubtitle;

  /// No description provided for @teachingOnMemuslimSuspendedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your teacher account is temporarily suspended. Contact support.'**
  String get teachingOnMemuslimSuspendedSubtitle;

  /// No description provided for @teachingOnMemuslimRevokedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your teacher account was revoked. Contact support for details.'**
  String get teachingOnMemuslimRevokedSubtitle;

  /// No description provided for @sessionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No teachers in your area yet'**
  String get sessionsEmptyTitle;

  /// No description provided for @sessionsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'We are adding verified teachers gradually. Register interest to get notified.'**
  String get sessionsEmptySubtitle;

  /// No description provided for @sessionsEmptyNotifyMe.
  ///
  /// In en, this message translates to:
  /// **'Notify me when available'**
  String get sessionsEmptyNotifyMe;

  /// No description provided for @sessionsEmptyChangeCity.
  ///
  /// In en, this message translates to:
  /// **'Change city'**
  String get sessionsEmptyChangeCity;

  /// No description provided for @sessionsEmptyInterestedTeaching.
  ///
  /// In en, this message translates to:
  /// **'Interested in teaching Quran?'**
  String get sessionsEmptyInterestedTeaching;

  /// No description provided for @sessionsEmptyJoinAsTeacher.
  ///
  /// In en, this message translates to:
  /// **'Join as a teacher'**
  String get sessionsEmptyJoinAsTeacher;

  /// No description provided for @notifyInterestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'We will notify you when teachers are available in your area.'**
  String get notifyInterestSubmitted;

  /// No description provided for @teacherApplicationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Teacher applications are not available right now.'**
  String get teacherApplicationDisabled;

  /// No description provided for @bookingDisabledNoSupply.
  ///
  /// In en, this message translates to:
  /// **'Booking is unavailable until verified teachers exist in your area.'**
  String get bookingDisabledNoSupply;

  /// No description provided for @completeTeacherProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete teacher profile'**
  String get completeTeacherProfileTitle;

  /// No description provided for @completeTeacherProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add the public details students see before opening your dashboard.'**
  String get completeTeacherProfileSubtitle;

  /// No description provided for @completeTeacherProfileFirstMessage.
  ///
  /// In en, this message translates to:
  /// **'Complete your teacher profile before opening the dashboard.'**
  String get completeTeacherProfileFirstMessage;

  /// No description provided for @teacherDashboard.
  ///
  /// In en, this message translates to:
  /// **'Teacher dashboard'**
  String get teacherDashboard;

  /// No description provided for @openTeacherDashboard.
  ///
  /// In en, this message translates to:
  /// **'Open teacher dashboard'**
  String get openTeacherDashboard;

  /// No description provided for @completeTeacherProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete teacher profile'**
  String get completeTeacherProfile;

  /// No description provided for @teacherPublicNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full teacher name'**
  String get teacherPublicNameLabel;

  /// No description provided for @teacherPublicNameHelper.
  ///
  /// In en, this message translates to:
  /// **'Your real full name as students see it in the marketplace. It may differ from your account name.'**
  String get teacherPublicNameHelper;

  /// No description provided for @teacherExternalMeetingUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'External meeting link'**
  String get teacherExternalMeetingUrlLabel;

  /// No description provided for @teacherExternalMeetingUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://meet.google.com/your-room'**
  String get teacherExternalMeetingUrlHint;

  /// No description provided for @teacherExternalMeetingUrlHelper.
  ///
  /// In en, this message translates to:
  /// **'Students who book external sessions join via this HTTPS link (Google Meet, Zoom, Microsoft Teams).'**
  String get teacherExternalMeetingUrlHelper;

  /// No description provided for @teacherExternalMeetingUrlSaved.
  ///
  /// In en, this message translates to:
  /// **'Meeting link saved'**
  String get teacherExternalMeetingUrlSaved;

  /// No description provided for @teacherExternalMeetingUrlSave.
  ///
  /// In en, this message translates to:
  /// **'Save meeting link'**
  String get teacherExternalMeetingUrlSave;

  /// No description provided for @teacherExternalMeetingUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid HTTPS meeting link (Google Meet, Zoom, or Teams).'**
  String get teacherExternalMeetingUrlInvalid;

  /// No description provided for @teacherOffersExternalSessions.
  ///
  /// In en, this message translates to:
  /// **'External sessions available'**
  String get teacherOffersExternalSessions;

  /// No description provided for @sessionMeetingLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Meeting link'**
  String get sessionMeetingLinkLabel;

  /// No description provided for @teacherPublicNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full teacher name is required.'**
  String get teacherPublicNameRequired;

  /// No description provided for @teacherPublicNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid full name (at least 3 characters, or two words).'**
  String get teacherPublicNameInvalid;

  /// No description provided for @teacherPublicNamePlaceholderNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Choose your real full name — generic placeholders like \"Quran Teacher\" are not allowed.'**
  String get teacherPublicNamePlaceholderNotAllowed;

  /// No description provided for @teacherProfileHiddenUntilComplete.
  ///
  /// In en, this message translates to:
  /// **'Your profile stays hidden from students until all required public fields are complete.'**
  String get teacherProfileHiddenUntilComplete;

  /// No description provided for @publicTeacherName.
  ///
  /// In en, this message translates to:
  /// **'Full teacher name'**
  String get publicTeacherName;

  /// No description provided for @visibleToStudents.
  ///
  /// In en, this message translates to:
  /// **'Your full name shown to students'**
  String get visibleToStudents;

  /// No description provided for @realNameRequiredForTeachers.
  ///
  /// In en, this message translates to:
  /// **'Teachers must use a real public name that students can recognize.'**
  String get realNameRequiredForTeachers;

  /// No description provided for @teachingLanguagesRequired.
  ///
  /// In en, this message translates to:
  /// **'Select at least one teaching language.'**
  String get teachingLanguagesRequired;

  /// No description provided for @specializationsRequired.
  ///
  /// In en, this message translates to:
  /// **'Select at least one specialization.'**
  String get specializationsRequired;

  /// No description provided for @bioRequired.
  ///
  /// In en, this message translates to:
  /// **'Bio is required.'**
  String get bioRequired;

  /// No description provided for @teacherProfileUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Teacher profile unavailable'**
  String get teacherProfileUnavailableTitle;

  /// No description provided for @teacherProfileUnavailableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This teacher has not finished their public profile yet.'**
  String get teacherProfileUnavailableSubtitle;

  /// No description provided for @verifiedTeacher.
  ///
  /// In en, this message translates to:
  /// **'Verified teacher'**
  String get verifiedTeacher;

  /// No description provided for @quranTeacherFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Quran Teacher'**
  String get quranTeacherFallbackName;

  /// No description provided for @teacherProfileIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Your teacher profile is missing required public fields.'**
  String get teacherProfileIncomplete;

  /// No description provided for @teacherProfileIncompleteAction.
  ///
  /// In en, this message translates to:
  /// **'Complete profile'**
  String get teacherProfileIncompleteAction;

  /// No description provided for @manageYourAvailabilityAndSessions.
  ///
  /// In en, this message translates to:
  /// **'Manage your schedule and sessions from here.'**
  String get manageYourAvailabilityAndSessions;

  /// No description provided for @noAvailabilityYet.
  ///
  /// In en, this message translates to:
  /// **'No availability published yet.'**
  String get noAvailabilityYet;

  /// No description provided for @reportConcernAction.
  ///
  /// In en, this message translates to:
  /// **'Report a concern'**
  String get reportConcernAction;

  /// No description provided for @reportConcernTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a safety concern'**
  String get reportConcernTitle;

  /// No description provided for @reportConcernSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us what happened. Our team reviews reports promptly.'**
  String get reportConcernSubtitle;

  /// No description provided for @reportConcernCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get reportConcernCategory;

  /// No description provided for @reportConcernDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get reportConcernDescriptionLabel;

  /// No description provided for @reportConcernDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what happened (at least 20 characters)'**
  String get reportConcernDescriptionHint;

  /// No description provided for @reportConcernDescriptionTooShort.
  ///
  /// In en, this message translates to:
  /// **'Please provide at least 20 characters.'**
  String get reportConcernDescriptionTooShort;

  /// No description provided for @reportConcernCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get reportConcernCancel;

  /// No description provided for @reportConcernSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get reportConcernSubmit;

  /// No description provided for @reportConcernSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Your report was submitted. Our team will review it.'**
  String get reportConcernSubmitted;

  /// No description provided for @openDisputeAction.
  ///
  /// In en, this message translates to:
  /// **'Open a dispute'**
  String get openDisputeAction;

  /// No description provided for @openDisputeTitle.
  ///
  /// In en, this message translates to:
  /// **'Open a dispute'**
  String get openDisputeTitle;

  /// No description provided for @openDisputeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us what went wrong. Our team will review your case.'**
  String get openDisputeSubtitle;

  /// No description provided for @openDisputeReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get openDisputeReasonLabel;

  /// No description provided for @openDisputeReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue (at least 3 characters)'**
  String get openDisputeReasonHint;

  /// No description provided for @openDisputeReasonTooShort.
  ///
  /// In en, this message translates to:
  /// **'Please provide at least 3 characters.'**
  String get openDisputeReasonTooShort;

  /// No description provided for @openDisputeCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get openDisputeCancel;

  /// No description provided for @openDisputeSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit dispute'**
  String get openDisputeSubmit;

  /// No description provided for @openDisputeSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Your dispute was submitted. Our team will review it.'**
  String get openDisputeSubmitted;

  /// No description provided for @reportCategorySafetyConcern.
  ///
  /// In en, this message translates to:
  /// **'Safety concern'**
  String get reportCategorySafetyConcern;

  /// No description provided for @reportCategoryAbuseOrHarassment.
  ///
  /// In en, this message translates to:
  /// **'Abuse or harassment'**
  String get reportCategoryAbuseOrHarassment;

  /// No description provided for @reportCategoryInappropriateContent.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get reportCategoryInappropriateContent;

  /// No description provided for @reportCategoryChildSafety.
  ///
  /// In en, this message translates to:
  /// **'Child safety'**
  String get reportCategoryChildSafety;

  /// No description provided for @reportCategoryFraudOrScam.
  ///
  /// In en, this message translates to:
  /// **'Fraud or scam'**
  String get reportCategoryFraudOrScam;

  /// No description provided for @reportCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportCategoryOther;

  /// No description provided for @walletTitle.
  ///
  /// In en, this message translates to:
  /// **'My wallet'**
  String get walletTitle;

  /// No description provided for @walletAvailableBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Available balance'**
  String get walletAvailableBalanceLabel;

  /// No description provided for @walletHeldBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'On hold: {amount}'**
  String walletHeldBalanceLabel(String amount);

  /// No description provided for @walletTransactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction history'**
  String get walletTransactionsTitle;

  /// No description provided for @walletEmptyState.
  ///
  /// In en, this message translates to:
  /// **'Credits appear when refunds are processed.'**
  String get walletEmptyState;

  /// No description provided for @walletFrozenMessage.
  ///
  /// In en, this message translates to:
  /// **'Wallet temporarily unavailable — contact support.'**
  String get walletFrozenMessage;

  /// No description provided for @walletTransactionTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'{type}'**
  String walletTransactionTypeLabel(String type);

  /// No description provided for @walletTransactionTypeRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get walletTransactionTypeRefund;

  /// No description provided for @walletTransactionTypeCompensation.
  ///
  /// In en, this message translates to:
  /// **'Compensation'**
  String get walletTransactionTypeCompensation;

  /// No description provided for @walletTransactionTypeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin credit'**
  String get walletTransactionTypeAdmin;

  /// No description provided for @walletTransactionTypePromo.
  ///
  /// In en, this message translates to:
  /// **'Promotional credit'**
  String get walletTransactionTypePromo;

  /// No description provided for @walletTransactionTypeBooking.
  ///
  /// In en, this message translates to:
  /// **'Session payment'**
  String get walletTransactionTypeBooking;

  /// No description provided for @walletTransactionTypeHold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get walletTransactionTypeHold;

  /// No description provided for @walletTransactionTypeHoldRelease.
  ///
  /// In en, this message translates to:
  /// **'Hold released'**
  String get walletTransactionTypeHoldRelease;

  /// No description provided for @walletTransactionTypeReversal.
  ///
  /// In en, this message translates to:
  /// **'Reversal'**
  String get walletTransactionTypeReversal;

  /// No description provided for @walletTransactionTypeExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expired credit'**
  String get walletTransactionTypeExpiry;

  /// No description provided for @walletEntryAction.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get walletEntryAction;

  /// No description provided for @paymentCheckoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm payment'**
  String get paymentCheckoutTitle;

  /// No description provided for @paymentCheckoutAmount.
  ///
  /// In en, this message translates to:
  /// **'Total: {amount}'**
  String paymentCheckoutAmount(String amount);

  /// No description provided for @paymentCheckoutAmountPending.
  ///
  /// In en, this message translates to:
  /// **'Session price (sandbox)'**
  String get paymentCheckoutAmountPending;

  /// No description provided for @paymentCheckoutRefundToWalletNotice.
  ///
  /// In en, this message translates to:
  /// **'If you cancel or we approve a refund, the amount is added to your Tilawa wallet as credit. Wallet credit is not automatically returned to your card.'**
  String get paymentCheckoutRefundToWalletNotice;

  /// No description provided for @paymentCheckoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm payment (sandbox)'**
  String get paymentCheckoutConfirm;
}

class _QuranSessionsLocalizationsDelegate
    extends LocalizationsDelegate<QuranSessionsLocalizations> {
  const _QuranSessionsLocalizationsDelegate();

  @override
  Future<QuranSessionsLocalizations> load(Locale locale) {
    return SynchronousFuture<QuranSessionsLocalizations>(
      lookupQuranSessionsLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_QuranSessionsLocalizationsDelegate old) => false;
}

QuranSessionsLocalizations lookupQuranSessionsLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return QuranSessionsLocalizationsAr();
    case 'en':
      return QuranSessionsLocalizationsEn();
  }

  throw FlutterError(
    'QuranSessionsLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'quran_sessions_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class QuranSessionsLocalizationsEn extends QuranSessionsLocalizations {
  QuranSessionsLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get errorNetwork => 'No internet connection.';

  @override
  String get errorTimeout => 'Request timed out. Please try again.';

  @override
  String get errorSessionExpired =>
      'Your session expired. Please sign in again.';

  @override
  String get errorForbidden =>
      'You do not have permission to perform this action.';

  @override
  String get errorServer => 'A server error occurred. Please try again later.';

  @override
  String get unauthorized => 'You are not authorized to perform this action.';

  @override
  String notFound(Object resource) {
    return '$resource not found.';
  }

  @override
  String validationError(Object code, Object field) {
    return 'Validation error: $field ($code).';
  }

  @override
  String get slotUnavailable =>
      'This slot is no longer available. Please choose another.';

  @override
  String get bookingConflict => 'You have another session at the same time.';

  @override
  String get profileIncompletePrefix => 'Your profile is incomplete.';

  @override
  String profileIncompleteFields(Object fields) {
    return 'Required information: $fields.';
  }

  @override
  String get gender_male => 'male';

  @override
  String get gender_female => 'female';

  @override
  String get gender_male_students => 'males';

  @override
  String get gender_female_students => 'females';

  @override
  String get ageNotAllowedChild =>
      'This teacher does not accept child students.';

  @override
  String get ageNotAllowedOther =>
      'Your age group is not accepted by this teacher.';

  @override
  String get teacherNotVerified =>
      'This teacher is not verified yet and cannot be booked.';

  @override
  String accountBlockedWithReason(Object reason) {
    return 'Your account is suspended because: $reason.';
  }

  @override
  String get accountBlocked =>
      'Your account is suspended. Please contact support.';

  @override
  String get guardianApprovalRequired =>
      'Booking for this student requires guardian approval first.';

  @override
  String policyViolation(Object detail, Object policy) {
    return 'Booking rejected due to policy \"$policy\": $detail.';
  }

  @override
  String get marketNotEnabledWithCity =>
      'Sessions are not available in your city right now. Try another city.';

  @override
  String get marketNotEnabled =>
      'Sessions are not available in your country right now.';

  @override
  String get marketCatalogEmpty =>
      'Country and city options are not available yet. Please try again later or contact support.';

  @override
  String get teacherNotInMarket =>
      'This teacher is not available in your area. Please choose another.';

  @override
  String get dateOfBirthRequired => 'Date of birth is required.';

  @override
  String get futureDateOfBirth => 'Date of birth cannot be in the future.';

  @override
  String get dateOfBirthTooRecent =>
      'Your age is not eligible for this feature yet.';

  @override
  String get invalidDateOfBirth =>
      'Date of birth is not valid. Please enter a valid date.';

  @override
  String get teacherApplicationNotFound => 'No teacher application was found.';

  @override
  String get teacherApplicationAlreadyPending =>
      'You already have a teacher application under review.';

  @override
  String get teacherApplicationRejected =>
      'Your application was rejected. You may reapply after the cooldown.';

  @override
  String get teacherApplicationSuspended =>
      'Your teacher application is temporarily suspended.';

  @override
  String get teacherApplicationRevoked =>
      'Your teacher application has been revoked.';

  @override
  String get teacherPhoneRequired =>
      'A phone number is required to complete the teacher application.';

  @override
  String get invalidTeacherPhone =>
      'The phone number is invalid. Please enter a proper international number.';

  @override
  String get phoneCountryMismatch =>
      'The phone number does not match the selected country.';

  @override
  String get invalidPhoneForSelectedCountry =>
      'The phone number violates the selected country\'s rules.';

  @override
  String teacherApplicationIncomplete(Object reason) {
    return 'Teacher application incomplete: $reason';
  }

  @override
  String reapplicationTooSoon(Object date) {
    return 'You cannot reapply before $date.';
  }

  @override
  String get teacherProfileNotApproved =>
      'The teacher profile is not approved yet.';

  @override
  String get teacherProfileNotActive => 'The teacher profile is not active.';

  @override
  String get paymentDeclined =>
      'Payment was declined. Please use another method.';

  @override
  String get paymentCancelled => 'Payment was cancelled.';

  @override
  String get paymentProviderFailure =>
      'Failed to process payment. Please try again.';

  @override
  String get cacheFailure => 'Failed to read local data.';

  @override
  String get unknownFailure => 'An unexpected error occurred.';

  @override
  String get retry => 'Retry';

  @override
  String get profileCompletionTitle => 'Complete profile';

  @override
  String get profileCompletionSavedSuccess =>
      'Your profile was saved successfully.';

  @override
  String get profileCompletionSaving => 'Saving your details…';

  @override
  String get profileCompletionHeadline => 'Tell us about yourself';

  @override
  String get profileCompletionSubtitle =>
      'We need this information to match you with the right teacher and show correct pricing for your region.';

  @override
  String get profileFieldGender => 'Gender';

  @override
  String get profileFieldDateOfBirth => 'Date of birth';

  @override
  String get profileFieldCountry => 'Country';

  @override
  String get profileFieldCity => 'City';

  @override
  String get profileFieldDisplayName => 'Full name';

  @override
  String get profileCompletionSaveAndContinue => 'Save and continue';

  @override
  String get profileCompletionSelectDateOfBirth => 'Select date of birth';

  @override
  String get profileCompletionSelectCountry => 'Select country';

  @override
  String get profileCompletionSelectCity => 'Select city';

  @override
  String get profileCompletionSelectCountryFirst => 'Select country first';

  @override
  String get profileCompletionLoadingCities => 'Loading cities…';

  @override
  String get profileGenderRequired => 'Gender is required.';

  @override
  String get profileCountryRequired => 'Country is required.';

  @override
  String get profileCityRequired => 'City is required.';

  @override
  String get quranSessionsHomeTitle => 'Learn Quran recitation';

  @override
  String get mySessionsTitle => 'My sessions';

  @override
  String get noTeachersAvailableYet => 'No teachers available yet';

  @override
  String get seeAllTeachers => 'See all teachers →';

  @override
  String get becomeTeacherCardTitle => 'I want to become a teacher';

  @override
  String get becomeTeacherCardSubtitle => 'Join MeMuslim\'s certified teachers';

  @override
  String get teacherListTitle => 'Find a teacher';

  @override
  String noTeachersForSpecialization(String specialization) {
    return 'No teachers found for \"$specialization\"';
  }

  @override
  String get noTeachersAvailableRightNow => 'No teachers available right now';

  @override
  String get bookSessionTitle => 'Book a session';

  @override
  String get bookingConfirmed => 'Booking confirmed!';

  @override
  String get checkingEligibility => 'Checking your eligibility…';

  @override
  String get confirmingBooking => 'Confirming booking…';

  @override
  String get selectSlot => 'Choose a time';

  @override
  String get sessionType => 'Session type';

  @override
  String get confirmBooking => 'Confirm booking';

  @override
  String get callTypeExternalMeeting => 'External link';

  @override
  String get callTypeVoice => 'Voice';

  @override
  String get callTypeVideo => 'Video';

  @override
  String get sessionModeVoiceBetaNote =>
      'Free Beta: voice uses a placeholder join until in-app RTC ships.';

  @override
  String get sessionModeVideoBetaNote =>
      'Free Beta: video uses a placeholder join until in-app RTC ships.';

  @override
  String get sessionModeVoiceDisabled =>
      'Voice sessions are not available yet. Choose external link.';

  @override
  String get sessionModeVideoDisabled =>
      'Video sessions are not available yet. Choose external link.';

  @override
  String get sessionModeExternalDisabled =>
      'Your teacher has not added a meeting link yet. Choose voice or video.';

  @override
  String get meetingLinkUnavailable =>
      'This teacher has not set up a meeting link for external sessions. Choose voice or video, or try again later.';

  @override
  String get callProviderUnavailable =>
      'This session cannot be joined from the app right now.';

  @override
  String rtcPermissionDenied(String permission) {
    return 'Microphone or camera access is required to join this session. Enable $permission in Settings and try again.';
  }

  @override
  String get rtcCallJoinFailed =>
      'Could not connect to the voice or video call. Try again in a moment.';

  @override
  String get webrtcSignalingUnavailable =>
      'In-app WebRTC calls are not available yet. Choose voice with Agora or an external meeting link.';

  @override
  String get inAppCallShellTitle => 'Session call';

  @override
  String get inAppCallShellBody =>
      'You are connected to this session\'s call room. End the call when your lesson finishes.';

  @override
  String get inAppCallShellEndCall => 'Leave call';

  @override
  String get inAppCallShellMute => 'Mute microphone';

  @override
  String get inAppCallShellUnmute => 'Unmute microphone';

  @override
  String get inAppCallShellConnecting => 'Connecting…';

  @override
  String get inAppCallShellConnected => 'Connected';

  @override
  String get inAppCallShellWaitingForParticipant =>
      'Waiting for the other participant';

  @override
  String get inAppCallShellMockBetaBody =>
      'Beta preview — no live audio or video. Book a new session with Agora enabled to try a real call.';

  @override
  String get externalMeetingJoinTitle => 'Join outside MeMuslim?';

  @override
  String get externalMeetingJoinBody =>
      'You\'ll briefly leave MeMuslim to join your session in Google Meet, Zoom, or your browser. Come back here anytime — your session details stay open.';

  @override
  String get externalMeetingJoinOpen => 'Open';

  @override
  String get externalMeetingJoinCopy => 'Copy URL';

  @override
  String get externalMeetingJoinLinkCopied => 'Link copied';

  @override
  String get externalMeetingJoinAgain => 'Open meeting again';

  @override
  String get externalMeetingLaunchFailed =>
      'Couldn\'t open the meeting link. Try again or copy the link.';

  @override
  String get externalMeetingLinkCopied =>
      'Meeting link copied. Paste it in your browser to join.';

  @override
  String get groupBookingNotSupported =>
      'Group sessions are not available in Free Beta.';

  @override
  String get unsupportedSessionMode => 'This session type is not supported.';

  @override
  String get reviewSubmittedThanks => 'Thank you — your review was submitted!';

  @override
  String upcomingSessionsSection(int count) {
    return 'Upcoming ($count)';
  }

  @override
  String get noUpcomingSessions => 'No upcoming sessions';

  @override
  String pastSessionsSection(int count) {
    return 'Past ($count)';
  }

  @override
  String get noPastSessions => 'No past sessions';

  @override
  String get cancelSessionDialogTitle => 'Cancel session?';

  @override
  String get cancelSessionDialogMessage => 'This action cannot be undone.';

  @override
  String get keepSession => 'Keep session';

  @override
  String get cancelSessionAction => 'Cancel session';

  @override
  String get cancelReasonLabel => 'Reason for cancellation';

  @override
  String get cancelReasonHint => 'Tell us why you need to cancel (required)';

  @override
  String get cancelReasonRequired => 'Please enter at least 3 characters.';

  @override
  String get cancelPolicyBlockedNotice =>
      'Cancellation is not allowed this close to the session start time.';

  @override
  String get cancelPolicyFree => 'This is a free session. No refund applies.';

  @override
  String get cancelPolicyFullRefund =>
      'You will receive a full refund if you cancel now.';

  @override
  String get cancelPolicyPartialRefund =>
      'A partial refund may apply based on our cancellation policy.';

  @override
  String get cancelPolicyNoRefund =>
      'No refund applies for cancellations at this time.';

  @override
  String get rescheduleSessionTitle => 'Reschedule session';

  @override
  String get rescheduleReasonLabel => 'Reason for rescheduling';

  @override
  String get rescheduleReasonHint => 'Briefly explain why you need a new time';

  @override
  String get rescheduleSubmitAction => 'Request reschedule';

  @override
  String get rescheduleRequestSubmitted =>
      'Reschedule request sent. Waiting for confirmation.';

  @override
  String get rescheduleAwaitingCounterparty =>
      'Waiting for the other participant to confirm your new time.';

  @override
  String get reschedulePendingTitle => 'Reschedule request';

  @override
  String reschedulePendingProposedTime(String dateTime) {
    return 'Proposed time: $dateTime';
  }

  @override
  String reschedulePendingReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get rescheduleAcceptAction => 'Accept new time';

  @override
  String get rescheduleRejectAction => 'Keep current time';

  @override
  String get rescheduleAcceptedToast =>
      'Reschedule accepted. Session time updated.';

  @override
  String get rescheduleRejectedToast =>
      'Reschedule declined. Original time kept.';

  @override
  String get rescheduleAction => 'Reschedule';

  @override
  String get sessionDetailTitle => 'Session details';

  @override
  String get sessionTimelineTitle => 'Activity timeline';

  @override
  String get sessionTimelineEmpty => 'No activity recorded yet.';

  @override
  String get sessionTimelineLoadFailed =>
      'Could not load the activity timeline. Check your connection and try again.';

  @override
  String get sessionPendingRescheduleLoadFailed =>
      'Could not load the pending reschedule request. Try again in a moment.';

  @override
  String sessionLockedAtBookingNote(String callType, String callProvider) {
    return 'Call type ($callType) and provider ($callProvider) were set when you booked. To change them, cancel and rebook or contact support.';
  }

  @override
  String get callProviderExternal => 'External link';

  @override
  String get callProviderMock => 'In-app (preview)';

  @override
  String get callProviderAgora => 'In-app (Agora)';

  @override
  String get callProviderWebrtc => 'In-app (WebRTC)';

  @override
  String sessionStatusLabel(String status) {
    return 'Status: $status';
  }

  @override
  String sessionStartsAtLabel(String when) {
    return 'Starts: $when';
  }

  @override
  String get viewSessionDetails => 'View details';

  @override
  String get noSessionsYet => 'No sessions yet';

  @override
  String get bookFirstSessionHint =>
      'Book your first session with one of our certified teachers';

  @override
  String get teacherProfileTitle => 'Teacher profile';

  @override
  String teacherRatingReviews(String rating, int count) {
    return '$rating · $count reviews';
  }

  @override
  String get availableSlots => 'Available slots';

  @override
  String get reviewsSection => 'Reviews';

  @override
  String get noReviewsYet => 'No reviews yet';

  @override
  String get bookSessionAction => 'Book a session';

  @override
  String get sessionStatusScheduled => 'Scheduled';

  @override
  String get sessionStatusInProgress => 'In progress';

  @override
  String get sessionStatusCompleted => 'Completed';

  @override
  String get sessionStatusCancelled => 'Cancelled';

  @override
  String get sessionStatusNoShow => 'No-show';

  @override
  String get cancel => 'Cancel';

  @override
  String get joinSession => 'Join';

  @override
  String get noSlotsAvailable => 'No slots available';

  @override
  String get noSlotsAvailableThisDay => 'No slots available on this day';

  @override
  String get teacherDashboardTitle => 'Teacher dashboard';

  @override
  String get noSessionsOrSlotsYet => 'No sessions or slots yet';

  @override
  String get addAvailableSlot => 'Add available slot';

  @override
  String openSlotsSection(int count) {
    return 'Open slots ($count)';
  }

  @override
  String get addSlot => 'Add slot';

  @override
  String get noOpenSlots => 'No open slots';

  @override
  String get slotBooked => 'Booked';

  @override
  String get slotAvailable => 'Available';

  @override
  String get editSlot => 'Edit slot';

  @override
  String get deleteSlot => 'Block this time';

  @override
  String get deleteSlotConfirmTitle => 'Block this time?';

  @override
  String get deleteSlotConfirmMessage =>
      'Students will no longer be able to book this time. Tap Undo on the snackbar to restore it.';

  @override
  String get deleteSlotConfirm => 'Block time';

  @override
  String get deleteSlotSuccess => 'Time blocked';

  @override
  String get deleteSlotUndo => 'Undo';

  @override
  String deleteSlotRemovedSnackBar(String time) {
    return 'Blocked $time';
  }

  @override
  String deleteSlotRemovedSnackBarWithPending(String time, int count) {
    return 'Blocked $time ($count pending)';
  }

  @override
  String deleteSlotRefreshDiscarded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pending blocks were discarded — slots restored',
      one: '1 pending block was discarded — slots restored',
    );
    return '$_temp0';
  }

  @override
  String get addNewSlot => 'Add new slot';

  @override
  String get slotDate => 'Slot date';

  @override
  String get slotTime => 'Slot time';

  @override
  String get addSlotButton => 'Add slot';

  @override
  String get availabilityTitle => 'Weekly availability';

  @override
  String get availabilityRecurringBanner =>
      'This is your recurring weekly availability. It is used to generate bookable times for future days.';

  @override
  String get bookableTimesSectionTitle => 'Bookable times — next 14 days';

  @override
  String get bookableTimesSectionSubtext =>
      'Generated from your weekly availability, minus exceptions and bookings.';

  @override
  String get bookableTimesThisWeekSectionTitle => 'This week';

  @override
  String get bookableTimesNextWeekSectionTitle => 'Next week';

  @override
  String get bookableTimesWeekScopedTitle => 'Bookable times';

  @override
  String bookableTimesSelectedDayCaption(String dayLabel) {
    return 'Showing times for $dayLabel';
  }

  @override
  String get bookableTimesEmptyThisWeek => 'No bookable times this week.';

  @override
  String get bookableTimesEmptyNextWeek => 'No bookable times next week.';

  @override
  String get bookableTimesEmptyThisWeekTitle => 'No bookable times this week';

  @override
  String get bookableTimesEmptyThisWeekSubtitle =>
      'Open days in your weekly template become slots here. Adjust your hours or check exceptions if you expected times.';

  @override
  String get bookableTimesEmptyNextWeekTitle => 'No bookable times next week';

  @override
  String get bookableTimesEmptyNextWeekSubtitle =>
      'Next week is built from your recurring weekly availability. Review your template to add or change days.';

  @override
  String get bookableTimesEmptyHorizonTitle =>
      'No bookable times in the next 14 days';

  @override
  String get bookableTimesEmptyHorizonSubtitle =>
      'Set your recurring weekly availability and open days will appear here automatically.';

  @override
  String get upcomingSessionsEmptyTitle => 'No upcoming sessions';

  @override
  String get upcomingSessionsEmptySubtitle =>
      'Confirmed bookings will appear here when students reserve a time with you.';

  @override
  String get fridayReviewBannerMessage =>
      'Review next week\'s availability. Students book from your weekly template.';

  @override
  String get fridayReviewBannerAction => 'Review';

  @override
  String get fridayReviewBannerDismiss => 'Dismiss';

  @override
  String get editWeeklyTemplate => 'Edit weekly template';

  @override
  String get availabilityTabHours => 'Hours';

  @override
  String get availabilityTabOverrides => 'Overrides';

  @override
  String get availabilityUseSameHours => 'Use same hours for all days';

  @override
  String get availabilityTimezone => 'Timezone';

  @override
  String get availabilitySessionLength => 'Session length';

  @override
  String availabilityDurationMinutes(int count) {
    return '$count min';
  }

  @override
  String get availabilityHoursRow => 'Hours';

  @override
  String get availabilityDayClosed => 'Closed';

  @override
  String get availabilityAddRange => 'Add range';

  @override
  String get availabilityEditRange => 'Edit range';

  @override
  String get availabilityRemoveRange => 'Remove';

  @override
  String get availabilitySave => 'Save';

  @override
  String get availabilitySavedToast => 'Schedule saved';

  @override
  String get availabilityOverrideRemovedToast => 'Date override removed';

  @override
  String get availabilityOverrideAddedToast => 'Date override added';

  @override
  String get availabilityDeleteVacationTitle => 'Delete vacation?';

  @override
  String get availabilityDeleteVacationMessage =>
      'These dates will become available for students to book again.';

  @override
  String get availabilityDeleteVacationConfirm => 'Delete vacation';

  @override
  String get availabilityVacationOverlapError =>
      'These dates overlap an existing vacation. Adjust the range or remove the existing vacation first.';

  @override
  String get availabilityUnsavedChanges => 'Unsaved changes';

  @override
  String get availabilityLoadError => 'Couldn\'t load your schedule';

  @override
  String get availabilityStartTime => 'Start time';

  @override
  String get availabilityEndTime => 'End time';

  @override
  String get availabilityUseTheseTimes => 'Use these times';

  @override
  String get availabilityRangeInvalid => 'End time must be after start time';

  @override
  String get availabilityRangeOverlap => 'This range overlaps another';

  @override
  String get availabilityNoOpenDaysError =>
      'Select at least one day with working hours';

  @override
  String get availabilityOverridesEmpty => 'No date overrides yet';

  @override
  String get availabilityOverridesEmptyHint =>
      'Block a day off or add special hours for a specific date.';

  @override
  String get availabilityAddOverride => 'Add date override';

  @override
  String get availabilityOverrideUnavailable => 'Unavailable (day off)';

  @override
  String get availabilityOverrideCustom => 'Custom hours';

  @override
  String get availabilityOverrideDate => 'Date';

  @override
  String get availabilityOverrideStartDate => 'From';

  @override
  String get availabilityOverrideEndDate => 'To';

  @override
  String get availabilityOverrideEndDateInvalid =>
      'End date must be on or after start date';

  @override
  String get availabilitySetupHeadline =>
      'Set your hours once and students can book automatically';

  @override
  String get availabilitySetupCta => 'Set up weekly schedule';

  @override
  String get availabilitySetupBenefitRecurring => 'No manual repetition';

  @override
  String get availabilitySetupBenefitTimezone => 'Timezone-aware';

  @override
  String get availabilitySetupBenefitSelfBooking => 'Students book themselves';

  @override
  String get availabilityTimezonePickerTitle => 'Choose timezone';

  @override
  String get availabilityDiscardChanges => 'Discard changes?';

  @override
  String get availabilityDiscardConfirm => 'Discard';

  @override
  String get availabilityKeepEditing => 'Keep editing';

  @override
  String get weekdaySaturday => 'Saturday';

  @override
  String get weekdaySunday => 'Sunday';

  @override
  String get weekdayMonday => 'Monday';

  @override
  String get weekdayTuesday => 'Tuesday';

  @override
  String get weekdayWednesday => 'Wednesday';

  @override
  String get weekdayThursday => 'Thursday';

  @override
  String get weekdayFriday => 'Friday';

  @override
  String get teacherApplicationTitle => 'Teacher application';

  @override
  String get submittingApplication => 'Submitting application…';

  @override
  String get becomeTeacherOnTilawa => 'Become a teacher on MeMuslim';

  @override
  String get becomeTeacherApplicationIntro =>
      'Join our certified teachers and help students on their Quran journey.';

  @override
  String get startApplication => 'Start application';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get phoneNumberRequiredHint =>
      'Required for identity verification. Visible to admin only.';

  @override
  String get preferredContactMethod => 'Preferred contact method';

  @override
  String get teachingLanguages => 'Teaching languages';

  @override
  String get teachingLanguagesSelect =>
      'Teaching languages * (select one or more)';

  @override
  String get specializations => 'Specializations';

  @override
  String get specializationsSelect => 'Specializations * (select one or more)';

  @override
  String get bio => 'Bio';

  @override
  String get bioSectionTitle => 'Bio *';

  @override
  String get bioHint =>
      'Tell students about your experience, qualifications, and teaching style…';

  @override
  String get submitApplicationForReview => 'Submit application for review';

  @override
  String get countryCode => 'Country code';

  @override
  String get contactWhatsapp => 'WhatsApp';

  @override
  String get contactPhone => 'Phone';

  @override
  String get contactEmail => 'Email';

  @override
  String get teachingLanguage_ar => 'Arabic';

  @override
  String get teachingLanguage_en => 'English';

  @override
  String get teachingLanguage_ur => 'Urdu';

  @override
  String get teachingLanguage_fr => 'French';

  @override
  String get teachingLanguage_tr => 'Turkish';

  @override
  String get teachingLanguage_ms => 'Malay';

  @override
  String get specialization_tajweed => 'Tajweed';

  @override
  String get specialization_recitation => 'Recitation';

  @override
  String get specialization_hifz => 'Memorisation';

  @override
  String get specialization_review => 'Review';

  @override
  String get specialization_children => 'Children';

  @override
  String get specialization_qaida => 'Qaida';

  @override
  String get specialization_tafsir => 'Tafsir';

  @override
  String get specialization_arabic => 'Arabic';

  @override
  String get applicationStatusTitle => 'Application status';

  @override
  String get unknownStatus => 'Unknown status';

  @override
  String get applicationStatusPendingTitle =>
      'Your application is under review';

  @override
  String get applicationStatusPendingSubtitle =>
      'The MeMuslim team is reviewing your application. We will contact you soon.';

  @override
  String get applicationStatusApprovedTitle => 'Congratulations! Approved';

  @override
  String get applicationStatusApprovedSubtitle =>
      'You are now a certified teacher on MeMuslim.';

  @override
  String get applicationStatusApprovedContinue => 'Continue';

  @override
  String get applicationStatusRejectedTitle => 'Application not approved';

  @override
  String get applicationStatusRejectedSubtitle =>
      'You may reapply after reviewing the team\'s feedback.';

  @override
  String get applicationStatusSuspendedTitle => 'Account temporarily suspended';

  @override
  String get applicationStatusSuspendedSubtitle =>
      'Contact support to ask about the suspension.';

  @override
  String get applicationStatusRevokedTitle => 'Account revoked';

  @override
  String get applicationStatusRevokedSubtitle =>
      'You cannot apply again. Contact support for more information.';

  @override
  String get submittedAtLabel => 'Submitted';

  @override
  String get reviewedAtLabel => 'Reviewed';

  @override
  String get reasonLabel => 'Reason';

  @override
  String labelWithColon(String label) {
    return '$label:';
  }

  @override
  String get debugModeTitle => 'Development mode';

  @override
  String get debugApprovalDescription =>
      'This button is for internal testing only and does not appear in production. It simulates admin approval without an admin interface.';

  @override
  String get simulateAdminApproval => 'Simulate admin approval';

  @override
  String get priceFree => 'Free';

  @override
  String pricePerSession(String amount) {
    return '$amount / session';
  }

  @override
  String get teachingOnMemuslimTitle => 'Teaching on MeMuslim';

  @override
  String get teachingOnMemuslimApply => 'Apply as a teacher';

  @override
  String get teachingOnMemuslimContinueDraft => 'Continue registration';

  @override
  String get teachingOnMemuslimViewStatus => 'View application status';

  @override
  String get teachingOnMemuslimTeacherDashboard => 'Teacher dashboard';

  @override
  String get teachingOnMemuslimOpenDashboard => 'Open teacher dashboard';

  @override
  String get teachingOnMemuslimManageScheduleSubtitle =>
      'Manage your schedule and sessions from here.';

  @override
  String get teachingOnMemuslimReapplySubtitle =>
      'View details or reapply when allowed.';

  @override
  String get verifiedTeacherBadge => 'Verified Teacher';

  @override
  String get teacherCapabilityStatusDraft => 'Draft';

  @override
  String get teacherCapabilityStatusPending => 'Under review';

  @override
  String get teacherCapabilityStatusRejected => 'Rejected';

  @override
  String get teacherCapabilityStatusSuspended => 'Suspended';

  @override
  String get teacherCapabilityStatusRevoked => 'Accreditation revoked';

  @override
  String get teachingOnMemuslimNotAppliedSubtitle =>
      'Apply to join our verified teacher community after team review.';

  @override
  String get teachingOnMemuslimPendingSubtitle =>
      'Your application is under review. We will contact you soon.';

  @override
  String get teachingOnMemuslimApprovedSubtitle =>
      'Your application was approved. Manage sessions from the teacher dashboard.';

  @override
  String get teachingOnMemuslimRejectedSubtitle =>
      'Your application was not approved. View details and reapply when allowed.';

  @override
  String get teachingOnMemuslimSuspendedSubtitle =>
      'Your teacher account is temporarily suspended. Contact support.';

  @override
  String get teachingOnMemuslimRevokedSubtitle =>
      'Your teacher account was revoked. Contact support for details.';

  @override
  String get sessionsEmptyTitle => 'No teachers in your area yet';

  @override
  String get sessionsEmptySubtitle =>
      'We are adding verified teachers gradually. Register interest to get notified.';

  @override
  String get sessionsEmptyNotifyMe => 'Notify me when available';

  @override
  String get sessionsEmptyChangeCity => 'Change city';

  @override
  String get sessionsEmptyInterestedTeaching => 'Interested in teaching Quran?';

  @override
  String get sessionsEmptyJoinAsTeacher => 'Join as a teacher';

  @override
  String get notifyInterestSubmitted =>
      'We will notify you when teachers are available in your area.';

  @override
  String get teacherApplicationDisabled =>
      'Teacher applications are not available right now.';

  @override
  String get bookingDisabledNoSupply =>
      'Booking is unavailable until verified teachers exist in your area.';

  @override
  String get completeTeacherProfileTitle => 'Complete teacher profile';

  @override
  String get completeTeacherProfileSubtitle =>
      'Add the public details students see before opening your dashboard.';

  @override
  String get completeTeacherProfileFirstMessage =>
      'Complete your teacher profile before opening the dashboard.';

  @override
  String get teacherDashboard => 'Teacher dashboard';

  @override
  String get openTeacherDashboard => 'Open teacher dashboard';

  @override
  String get completeTeacherProfile => 'Complete teacher profile';

  @override
  String get teacherPublicNameLabel => 'Full teacher name';

  @override
  String get teacherPublicNameHelper =>
      'Your real full name as students see it in the marketplace. It may differ from your account name.';

  @override
  String get teacherExternalMeetingUrlLabel => 'External meeting link';

  @override
  String get teacherExternalMeetingUrlHint =>
      'https://meet.google.com/your-room';

  @override
  String get teacherExternalMeetingUrlHelper =>
      'Students who book external sessions join via this HTTPS link (Google Meet, Zoom, Microsoft Teams).';

  @override
  String get teacherExternalMeetingUrlSaved => 'Meeting link saved';

  @override
  String get teacherExternalMeetingUrlSave => 'Save meeting link';

  @override
  String get teacherExternalMeetingUrlInvalid =>
      'Enter a valid HTTPS meeting link (Google Meet, Zoom, or Teams).';

  @override
  String get teacherOffersExternalSessions => 'External sessions available';

  @override
  String get sessionMeetingLinkLabel => 'Meeting link';

  @override
  String get teacherPublicNameRequired => 'Full teacher name is required.';

  @override
  String get teacherPublicNameInvalid =>
      'Enter a valid full name (at least 3 characters, or two words).';

  @override
  String get teacherPublicNamePlaceholderNotAllowed =>
      'Choose your real full name — generic placeholders like \"Quran Teacher\" are not allowed.';

  @override
  String get teacherProfileHiddenUntilComplete =>
      'Your profile stays hidden from students until all required public fields are complete.';

  @override
  String get publicTeacherName => 'Full teacher name';

  @override
  String get visibleToStudents => 'Your full name shown to students';

  @override
  String get realNameRequiredForTeachers =>
      'Teachers must use a real public name that students can recognize.';

  @override
  String get teachingLanguagesRequired =>
      'Select at least one teaching language.';

  @override
  String get specializationsRequired => 'Select at least one specialization.';

  @override
  String get bioRequired => 'Bio is required.';

  @override
  String get teacherProfileUnavailableTitle => 'Teacher profile unavailable';

  @override
  String get teacherProfileUnavailableSubtitle =>
      'This teacher has not finished their public profile yet.';

  @override
  String get verifiedTeacher => 'Verified teacher';

  @override
  String get quranTeacherFallbackName => 'Quran Teacher';

  @override
  String get teacherProfileIncomplete =>
      'Your teacher profile is missing required public fields.';

  @override
  String get teacherProfileIncompleteAction => 'Complete profile';

  @override
  String get manageYourAvailabilityAndSessions =>
      'Manage your schedule and sessions from here.';

  @override
  String get noAvailabilityYet => 'No availability published yet.';

  @override
  String get reportConcernAction => 'Report a concern';

  @override
  String get reportConcernTitle => 'Report a safety concern';

  @override
  String get reportConcernSubtitle =>
      'Tell us what happened. Our team reviews reports promptly.';

  @override
  String get reportConcernCategory => 'Category';

  @override
  String get reportConcernDescriptionLabel => 'Description';

  @override
  String get reportConcernDescriptionHint =>
      'Describe what happened (at least 20 characters)';

  @override
  String get reportConcernDescriptionTooShort =>
      'Please provide at least 20 characters.';

  @override
  String get reportConcernCancel => 'Cancel';

  @override
  String get reportConcernSubmit => 'Submit report';

  @override
  String get reportConcernSubmitted =>
      'Your report was submitted. Our team will review it.';

  @override
  String get openDisputeAction => 'Open a dispute';

  @override
  String get openDisputeTitle => 'Open a dispute';

  @override
  String get openDisputeSubtitle =>
      'Tell us what went wrong. Our team will review your case.';

  @override
  String get openDisputeReasonLabel => 'Reason';

  @override
  String get openDisputeReasonHint =>
      'Describe the issue (at least 3 characters)';

  @override
  String get openDisputeReasonTooShort =>
      'Please provide at least 3 characters.';

  @override
  String get openDisputeCancel => 'Cancel';

  @override
  String get openDisputeSubmit => 'Submit dispute';

  @override
  String get openDisputeSubmitted =>
      'Your dispute was submitted. Our team will review it.';

  @override
  String get reportCategorySafetyConcern => 'Safety concern';

  @override
  String get reportCategoryAbuseOrHarassment => 'Abuse or harassment';

  @override
  String get reportCategoryInappropriateContent => 'Inappropriate content';

  @override
  String get reportCategoryChildSafety => 'Child safety';

  @override
  String get reportCategoryFraudOrScam => 'Fraud or scam';

  @override
  String get reportCategoryOther => 'Other';

  @override
  String get walletTitle => 'My wallet';

  @override
  String get walletAvailableBalanceLabel => 'Available balance';

  @override
  String walletHeldBalanceLabel(String amount) {
    return 'On hold: $amount';
  }

  @override
  String get walletTransactionsTitle => 'Transaction history';

  @override
  String get walletEmptyState => 'Credits appear when refunds are processed.';

  @override
  String get walletFrozenMessage =>
      'Wallet temporarily unavailable — contact support.';

  @override
  String walletTransactionTypeLabel(String type) {
    return '$type';
  }

  @override
  String get walletTransactionTypeRefund => 'Refund';

  @override
  String get walletTransactionTypeCompensation => 'Compensation';

  @override
  String get walletTransactionTypeAdmin => 'Admin credit';

  @override
  String get walletTransactionTypePromo => 'Promotional credit';

  @override
  String get walletTransactionTypeBooking => 'Session payment';

  @override
  String get walletTransactionTypeHold => 'Hold';

  @override
  String get walletTransactionTypeHoldRelease => 'Hold released';

  @override
  String get walletTransactionTypeReversal => 'Reversal';

  @override
  String get walletTransactionTypeExpiry => 'Expired credit';

  @override
  String get walletEntryAction => 'Wallet';

  @override
  String get paymentCheckoutTitle => 'Confirm payment';

  @override
  String paymentCheckoutAmount(String amount) {
    return 'Total: $amount';
  }

  @override
  String get paymentCheckoutAmountPending => 'Session price (sandbox)';

  @override
  String get paymentCheckoutRefundToWalletNotice =>
      'If you cancel or we approve a refund, the amount is added to your Tilawa wallet as credit. Wallet credit is not automatically returned to your card.';

  @override
  String get paymentCheckoutConfirm => 'Confirm payment (sandbox)';
}

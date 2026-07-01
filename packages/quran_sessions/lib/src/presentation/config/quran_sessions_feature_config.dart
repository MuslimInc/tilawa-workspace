import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Where teacher-application entry points may appear in the product.
enum TeacherApplicationDiscoverability {
  /// No in-app discovery; routes may still exist for deep links when disabled.
  none,

  /// Profile / Settings section only (canonical).
  profileOnly,

  /// Profile plus Learn Quran empty-state secondary CTA (Option D).
  profileAndEmptyState,
}

/// Host-provided feature configuration for Quran Sessions presentation.
///
/// Resolved in the app layer ([AppLaunchConfig]) and passed into screens.
/// Keeps Firebase and remote config out of the package.
@immutable
class QuranSessionsFeatureConfig extends Equatable {
  const QuranSessionsFeatureConfig({
    this.quranSessionsEnabled = true,
    this.learnQuranStudentFeatureEnabled = false,
    this.teacherApplicationEntryEnabled = false,
    this.homeTeacherApplicationCardEnabled = false,
    this.teacherApplicationFormUrl = '',
    this.teacherApplicationEnabled = false,
    this.teacherApplicationDiscoverability =
        TeacherApplicationDiscoverability.none,
    this.quranSessionsBookingEnabled = false,
    this.walletEnabled = false,
  });

  final bool quranSessionsEnabled;
  final bool learnQuranStudentFeatureEnabled;
  final bool teacherApplicationEntryEnabled;
  final bool homeTeacherApplicationCardEnabled;
  final String teacherApplicationFormUrl;
  final bool teacherApplicationEnabled;
  final TeacherApplicationDiscoverability teacherApplicationDiscoverability;
  final bool quranSessionsBookingEnabled;

  /// Wallet UI and routes — staging sandbox only (paid/refund scope).
  final bool walletEnabled;

  /// Student hub, teachers list, booking, and my sessions entry points.
  bool get showLearnQuranStudentExperience =>
      quranSessionsEnabled && learnQuranStudentFeatureEnabled;

  /// Google Form teacher application entry in Settings/Profile.
  bool get showTeacherApplicationEntry =>
      quranSessionsEnabled && teacherApplicationEntryEnabled;

  /// Optional Home inline card — never auto-shown as a modal.
  bool get showHomeTeacherApplicationCard =>
      showTeacherApplicationEntry && homeTeacherApplicationCardEnabled;

  /// In-app teacher apply flow (legacy intake screen).
  bool get showInAppTeacherApplicationEntry =>
      quranSessionsEnabled &&
      learnQuranStudentFeatureEnabled &&
      teacherApplicationEnabled &&
      teacherApplicationDiscoverability !=
          TeacherApplicationDiscoverability.none;

  bool get showProfileTeacherEntry =>
      showTeacherApplicationEntry || showInAppTeacherApplicationEntry;

  bool get showEmptyStateTeacherEntry =>
      showInAppTeacherApplicationEntry &&
      teacherApplicationDiscoverability ==
          TeacherApplicationDiscoverability.profileAndEmptyState;

  @override
  List<Object?> get props => [
    quranSessionsEnabled,
    learnQuranStudentFeatureEnabled,
    teacherApplicationEntryEnabled,
    homeTeacherApplicationCardEnabled,
    teacherApplicationFormUrl,
    teacherApplicationEnabled,
    teacherApplicationDiscoverability,
    quranSessionsBookingEnabled,
    walletEnabled,
  ];
}

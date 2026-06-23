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
    this.teacherApplicationEnabled = false,
    this.teacherApplicationDiscoverability =
        TeacherApplicationDiscoverability.none,
    this.quranSessionsBookingEnabled = false,
  });

  final bool quranSessionsEnabled;
  final bool teacherApplicationEnabled;
  final TeacherApplicationDiscoverability teacherApplicationDiscoverability;
  final bool quranSessionsBookingEnabled;

  bool get showProfileTeacherEntry =>
      quranSessionsEnabled &&
      teacherApplicationEnabled &&
      teacherApplicationDiscoverability !=
          TeacherApplicationDiscoverability.none;

  bool get showEmptyStateTeacherEntry =>
      quranSessionsEnabled &&
      teacherApplicationEnabled &&
      teacherApplicationDiscoverability ==
          TeacherApplicationDiscoverability.profileAndEmptyState;

  @override
  List<Object?> get props => [
    quranSessionsEnabled,
    teacherApplicationEnabled,
    teacherApplicationDiscoverability,
    quranSessionsBookingEnabled,
  ];
}

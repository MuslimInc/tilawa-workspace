import 'package:equatable/equatable.dart';
import 'package:tilawa_core/errors/failures.dart';

enum HomeQuranResumeStatus { initial, loading, ready, failure }

/// Last-read Quran snapshot for the Home resume card.
final class HomeQuranResumeState extends Equatable {
  const HomeQuranResumeState({
    this.status = HomeQuranResumeStatus.initial,
    this.surahNumber,
    this.ayahNumber,
    this.page,
    this.failure,
    this.streakDays,
    this.goalProgress,
    this.hasActiveKhatmaPlan = false,
  });

  final HomeQuranResumeStatus status;
  final int? surahNumber;
  final int? ayahNumber;
  final int? page;
  final Failure? failure;
  final int? streakDays;
  final double? goalProgress;
  final bool hasActiveKhatmaPlan;

  bool get hasResumePosition => surahNumber != null || page != null;

  double? progressFraction(int pageCount) {
    final int? resumePage = page;
    if (resumePage == null || resumePage <= 0) {
      return null;
    }
    return (resumePage / pageCount).clamp(0.0, 1.0);
  }

  HomeQuranResumeState copyWith({
    HomeQuranResumeStatus? status,
    int? surahNumber,
    int? ayahNumber,
    int? page,
    Failure? failure,
    int? streakDays,
    double? goalProgress,
    bool? hasActiveKhatmaPlan,
    bool clearFailure = false,
    bool clearPosition = false,
    bool clearGoalProgress = false,
  }) {
    return HomeQuranResumeState(
      status: status ?? this.status,
      surahNumber: clearPosition ? null : surahNumber ?? this.surahNumber,
      ayahNumber: clearPosition ? null : ayahNumber ?? this.ayahNumber,
      page: clearPosition ? null : page ?? this.page,
      failure: clearFailure ? null : failure ?? this.failure,
      streakDays: streakDays ?? this.streakDays,
      goalProgress: clearGoalProgress
          ? null
          : goalProgress ?? this.goalProgress,
      hasActiveKhatmaPlan: hasActiveKhatmaPlan ?? this.hasActiveKhatmaPlan,
    );
  }

  @override
  List<Object?> get props => [
    status,
    surahNumber,
    ayahNumber,
    page,
    failure,
    streakDays,
    goalProgress,
    hasActiveKhatmaPlan,
  ];
}

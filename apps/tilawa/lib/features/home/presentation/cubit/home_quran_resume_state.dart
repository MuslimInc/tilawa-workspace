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
  });

  final HomeQuranResumeStatus status;
  final int? surahNumber;
  final int? ayahNumber;
  final int? page;
  final Failure? failure;

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
    bool clearFailure = false,
    bool clearPosition = false,
  }) {
    return HomeQuranResumeState(
      status: status ?? this.status,
      surahNumber: clearPosition ? null : surahNumber ?? this.surahNumber,
      ayahNumber: clearPosition ? null : ayahNumber ?? this.ayahNumber,
      page: clearPosition ? null : page ?? this.page,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    surahNumber,
    ayahNumber,
    page,
    failure,
  ];
}

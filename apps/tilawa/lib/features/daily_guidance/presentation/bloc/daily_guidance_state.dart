import 'package:equatable/equatable.dart';

import '../../domain/entities/daily_guidance_enums.dart';
import '../../domain/entities/daily_guidance_item.dart';
import '../../domain/entities/daily_guidance_preferences.dart';

abstract class DailyGuidanceState extends Equatable {
  const DailyGuidanceState();

  @override
  List<Object?> get props => [];
}

class DailyGuidanceInitial extends DailyGuidanceState {}

class DailyGuidanceLoading extends DailyGuidanceState {}

class DailyGuidanceLoaded extends DailyGuidanceState {
  final DailyGuidanceItem? todayItem;
  final DailyGuidancePreferences preferences;
  final FeatureState featureState;

  const DailyGuidanceLoaded({
    this.todayItem,
    required this.preferences,
    required this.featureState,
  });

  DailyGuidanceLoaded copyWith({
    DailyGuidanceItem? todayItem,
    DailyGuidancePreferences? preferences,
    FeatureState? featureState,
  }) {
    return DailyGuidanceLoaded(
      todayItem: todayItem ?? this.todayItem,
      preferences: preferences ?? this.preferences,
      featureState: featureState ?? this.featureState,
    );
  }

  @override
  List<Object?> get props => [todayItem, preferences, featureState];
}

class DailyGuidanceError extends DailyGuidanceState {
  const DailyGuidanceError();
}

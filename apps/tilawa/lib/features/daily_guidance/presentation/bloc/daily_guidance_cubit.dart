import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';

import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/daily_guidance_enums.dart';
import '../../domain/repositories/daily_guidance_preferences_repository.dart';
import '../../domain/usecases/select_daily_guidance_item_use_case.dart';
import '../../domain/usecases/schedule_daily_guidance_use_case.dart';
import 'daily_guidance_state.dart';

@injectable
class DailyGuidanceCubit extends Cubit<DailyGuidanceState> {
  final SelectDailyGuidanceItemUseCase _selectUseCase;
  final ToggleDailyGuidanceUseCase _toggleUseCase;
  final DailyGuidancePreferencesRepository _prefsRepo;

  DailyGuidanceCubit(
    this._selectUseCase,
    this._toggleUseCase,
    this._prefsRepo,
  ) : super(DailyGuidanceInitial());

  Future<void> loadTodayGuidance({required String locale}) async {
    emit(DailyGuidanceLoading());
    try {
      final prefs = await _prefsRepo.getPreferences();
      final localDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final item = await _selectUseCase(
        localDate: localDate,
        preferences: prefs,
        locale: locale,
      );

      final state = prefs.enabled
          ? FeatureState.enabled
          : FeatureState.disabled; // Simple evaluation for MVP

      emit(
        DailyGuidanceLoaded(
          todayItem: item,
          preferences: prefs,
          featureState: state,
        ),
      );
    } on Exception catch (error, stackTrace) {
      logger.e(
        'Daily Guidance failed to load trusted content',
        error: error,
        stackTrace: stackTrace,
      );
      emit(const DailyGuidanceError());
    }
  }

  Future<void> toggleFeature({required bool enable}) async {
    if (state is DailyGuidanceLoaded) {
      final currentState = state as DailyGuidanceLoaded;
      try {
        final newPrefs = await _toggleUseCase(enable: enable);
        emit(
          currentState.copyWith(
            preferences: newPrefs,
            featureState: enable ? FeatureState.enabled : FeatureState.disabled,
          ),
        );
      } on Exception catch (error, stackTrace) {
        logger.e(
          'Daily Guidance reminder toggle failed',
          error: error,
          stackTrace: stackTrace,
        );
        emit(const DailyGuidanceError());
      }
    }
  }
}

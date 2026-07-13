import 'package:injectable/injectable.dart';

import '../entities/daily_guidance_preferences.dart';
import '../repositories/daily_guidance_preferences_repository.dart';

/// Contract for the platform notification scheduler.
abstract class DailyGuidanceNotificationService {
  /// Schedules the recurring daily trigger at [preferences.preferredLocalTime].
  Future<void> scheduleDailyTrigger(DailyGuidancePreferences preferences);

  /// Cancels any existing daily triggers.
  Future<void> cancelDailyTrigger();
}

@injectable
class ToggleDailyGuidanceUseCase {
  final DailyGuidancePreferencesRepository _repository;
  final DailyGuidanceNotificationService _notificationService;

  const ToggleDailyGuidanceUseCase(
    this._repository,
    this._notificationService,
  );

  Future<DailyGuidancePreferences> call({required bool enable}) async {
    final prefs = await _repository.getPreferences();
    if (prefs.enabled == enable) return prefs;

    final updated = prefs.copyWith(
      enabled: enable,
      updatedAt: DateTime.now(),
    );
    await _repository.savePreferences(updated);

    if (enable) {
      await _notificationService.scheduleDailyTrigger(updated);
    } else {
      await _notificationService.cancelDailyTrigger();
    }

    return updated;
  }
}

@injectable
class ScheduleDailyGuidanceUseCase {
  final DailyGuidancePreferencesRepository _repository;
  final DailyGuidanceNotificationService _notificationService;

  const ScheduleDailyGuidanceUseCase(
    this._repository,
    this._notificationService,
  );

  Future<void> call({required DailyGuidancePreferences preferences}) async {
    final updated = preferences.copyWith(updatedAt: DateTime.now());
    await _repository.savePreferences(updated);

    if (updated.enabled) {
      await _notificationService.scheduleDailyTrigger(updated);
    } else {
      await _notificationService.cancelDailyTrigger();
    }
  }
}

import '../../domain/entities/market_scheduling_config.dart';
import '../../domain/entities/scheduling_mode.dart';
import '../../domain/entities/weekday.dart';
import '../dtos/market_scheduling_config_dto.dart';

MarketSchedulingConfig marketSchedulingConfigFromDto(
  MarketSchedulingConfigDto dto,
) {
  return MarketSchedulingConfig(
    schedulingMode: SchedulingModeX.fromKey(dto.schedulingMode),
    weekStartDay: _weekStartDayFromKey(dto.weekStartDay),
    weekScopedDashboardEnabled: dto.weekScopedDashboardEnabled,
    fridayReviewReminderEnabled: dto.fridayReviewReminderEnabled,
    reminderLocalHour: dto.reminderLocalHour,
    bookingHorizonDays: dto.bookingHorizonDays,
    policyVersion: dto.policyVersion,
  );
}

Weekday _weekStartDayFromKey(String key) {
  try {
    return Weekday.fromKey(key.length >= 3 ? key.substring(0, 3) : key);
  } on ArgumentError {
    return Weekday.saturday;
  }
}

MarketSchedulingConfigDto marketSchedulingConfigToDto(
  MarketSchedulingConfig config,
) {
  return MarketSchedulingConfigDto(
    schedulingMode: config.schedulingMode.storageKey,
    weekStartDay: config.weekStartDay.key,
    weekScopedDashboardEnabled: config.weekScopedDashboardEnabled,
    fridayReviewReminderEnabled: config.fridayReviewReminderEnabled,
    reminderLocalHour: config.reminderLocalHour,
    bookingHorizonDays: config.bookingHorizonDays,
    policyVersion: config.policyVersion,
  );
}

MarketSchedulingConfigDto defaultMarketSchedulingConfigDto() =>
    marketSchedulingConfigToDto(MarketSchedulingConfig.defaults);

Map<String, dynamic>? schedulingMapFromDto(MarketSchedulingConfigDto? dto) {
  if (dto == null) return null;
  return {
    'schedulingMode': dto.schedulingMode,
    'weekStartDay': dto.weekStartDay,
    'weekScopedDashboardEnabled': dto.weekScopedDashboardEnabled,
    'fridayReviewReminderEnabled': dto.fridayReviewReminderEnabled,
    'reminderLocalHour': dto.reminderLocalHour,
    'bookingHorizonDays': dto.bookingHorizonDays,
    'policyVersion': dto.policyVersion,
  };
}

MarketSchedulingConfigDto marketSchedulingConfigDtoFromMap(
  Map<String, dynamic>? map,
) {
  if (map == null || map.isEmpty) {
    return defaultMarketSchedulingConfigDto();
  }
  return MarketSchedulingConfigDto(
    schedulingMode: map['schedulingMode'] as String? ?? 'recurring',
    weekStartDay: map['weekStartDay'] as String? ?? 'sat',
    weekScopedDashboardEnabled:
        map['weekScopedDashboardEnabled'] as bool? ?? true,
    fridayReviewReminderEnabled:
        map['fridayReviewReminderEnabled'] as bool? ?? true,
    reminderLocalHour: map['reminderLocalHour'] as int? ?? 10,
    bookingHorizonDays: map['bookingHorizonDays'] as int? ?? 30,
    policyVersion: map['policyVersion'] as int? ?? 1,
  );
}

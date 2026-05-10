import 'package:tilawa/l10n/generated/app_localizations.dart';

import '../../domain/entities/entities.dart';
import '../formatters/prayer_time_label_formatter.dart';
import '../models/prayer_row_view_data.dart';

/// Maps prayer/domain state into lightweight row data for presentation.
abstract final class PrayerRowViewDataMapper {
  static List<PrayerRowViewData> map({
    required PrayerTimeEntity prayerTimes,
    required PrayerSettingsEntity settings,
    required PrayerTimeItem? currentPrayer,
    required AppLocalizations l10n,
    required bool isArabic,
  }) {
    final prayers = prayerTimes.mainPrayers.where((prayer) {
      return settings.showSunrise || prayer.type != PrayerType.sunrise;
    });

    return prayers.map((prayer) {
      final isCurrent = currentPrayer?.type == prayer.type;
      final hasPassed = prayerTimes.hasPrayerPassed(prayer.type) && !isCurrent;
      final prayerAlert = alertForType(settings, prayer.type);
      final showAlertIndicators = prayerAlert != null;

      return PrayerRowViewData(
        type: prayer.type,
        prayerName: _localizedPrayerName(prayer.type, l10n),
        prayerTime: PrayerTimeLabelFormatter.formatItem(
          prayer,
          use24HourFormat: settings.use24HourFormat,
          isArabic: isArabic,
        ),
        statusText: _localizedStatus(
          isCurrent: isCurrent,
          hasPassed: hasPassed,
          l10n: l10n,
        ),
        isCurrent: isCurrent,
        hasPassed: hasPassed,
        isSecondary: prayer.type == PrayerType.sunrise,
        showAlertIndicators: showAlertIndicators,
        notificationEnabled: prayerAlert?.enabled ?? false,
        adhanEnabled: prayerAlert?.playAdhan ?? false,
        alert: alertViewData(settings: settings, type: prayer.type, l10n: l10n),
      );
    }).toList();
  }

  static PrayerAlertViewData alertViewData({
    required PrayerSettingsEntity settings,
    required PrayerType type,
    required AppLocalizations l10n,
  }) {
    final alert = alertForType(settings, type);
    if (alert == null) {
      return PrayerAlertViewData(
        state: PrayerAlertViewState.off,
        label: l10n.disabled,
        supportsAlerts: false,
        supportsAdhan: false,
      );
    }

    final supportsAdhan = type != PrayerType.sunrise;
    final state = switch (alert.mode) {
      PrayerAlertMode.none => PrayerAlertViewState.off,
      PrayerAlertMode.notification => PrayerAlertViewState.notification,
      PrayerAlertMode.adhan when supportsAdhan => PrayerAlertViewState.adhan,
      PrayerAlertMode.adhan => PrayerAlertViewState.notification,
    };

    return PrayerAlertViewData(
      state: state,
      label: switch (state) {
        PrayerAlertViewState.off => l10n.prayerAlertModeOff,
        PrayerAlertViewState.notification => l10n.prayerAlertModeNotifyOnly,
        PrayerAlertViewState.adhan => l10n.prayerAlertModeAdhan,
      },
      supportsAlerts: true,
      supportsAdhan: supportsAdhan,
    );
  }

  static PrayerNotificationSettings? alertForType(
    PrayerSettingsEntity settings,
    PrayerType type,
  ) {
    return switch (type) {
      PrayerType.fajr => settings.fajrNotification,
      PrayerType.sunrise => settings.sunriseNotification,
      PrayerType.dhuhr => settings.dhuhrNotification,
      PrayerType.asr => settings.asrNotification,
      PrayerType.maghrib => settings.maghribNotification,
      PrayerType.isha => settings.ishaNotification,
      PrayerType.midnight || PrayerType.lastThird => null,
    };
  }

  static String? prayerIdForType(PrayerType type) {
    return switch (type) {
      PrayerType.fajr => 'fajr',
      PrayerType.sunrise => 'sunrise',
      PrayerType.dhuhr => 'dhuhr',
      PrayerType.asr => 'asr',
      PrayerType.maghrib => 'maghrib',
      PrayerType.isha => 'isha',
      PrayerType.midnight || PrayerType.lastThird => null,
    };
  }

  static String _localizedPrayerName(PrayerType type, AppLocalizations l10n) {
    return switch (type) {
      PrayerType.fajr => l10n.fajr,
      PrayerType.sunrise => l10n.sunrise,
      PrayerType.dhuhr => l10n.dhuhr,
      PrayerType.asr => l10n.asr,
      PrayerType.maghrib => l10n.maghrib,
      PrayerType.isha => l10n.isha,
      PrayerType.midnight => l10n.midnight,
      PrayerType.lastThird => l10n.lastThird,
    };
  }

  static String _localizedStatus({
    required bool isCurrent,
    required bool hasPassed,
    required AppLocalizations l10n,
  }) {
    if (isCurrent) return l10n.next;
    if (hasPassed) return l10n.prayerTimesPassed;
    return l10n.prayerTimesUpcoming;
  }

  static PrayerSettingsEntity? toggledNotificationSettings(
    PrayerSettingsEntity settings,
    PrayerType type,
  ) {
    final prayerId = prayerIdForType(type);
    if (prayerId == null) return null;

    final currentAlert = alertForType(settings, type);
    if (currentAlert == null) return null;

    return settings.updatePrayerAlert(
      prayerId,
      notificationEnabled: !currentAlert.enabled,
    );
  }

  static PrayerSettingsEntity? toggledAdhanSettings(
    PrayerSettingsEntity settings,
    PrayerType type,
  ) {
    final prayerId = prayerIdForType(type);
    if (prayerId == null) return null;

    final currentAlert = alertForType(settings, type);
    if (currentAlert == null || !currentAlert.enabled) return null;

    return settings.updatePrayerAlert(
      prayerId,
      adhanEnabled: !currentAlert.playAdhan,
    );
  }

  static PrayerSettingsEntity? updatedAlertModeSettings(
    PrayerSettingsEntity settings,
    PrayerType type,
    PrayerAlertMode mode,
  ) {
    final prayerId = prayerIdForType(type);
    if (prayerId == null) return null;

    return settings.updatePrayerAlert(
      prayerId,
      notificationEnabled: mode.isNotificationEnabled,
      adhanEnabled: type != PrayerType.sunrise && mode.isAdhanEnabled,
    );
  }
}

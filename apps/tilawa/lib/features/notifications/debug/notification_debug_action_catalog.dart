import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa/router/notification_navigation_resolver.dart';

import 'notification_debug_constants.dart';

/// Builds debug action specs with localized behavior labels.
class NotificationDebugActionCatalog {
  NotificationDebugActionCatalog._();

  static List<NotificationDebugActionSpec> localNotificationActions(
    AppLocalizations l10n,
  ) {
    return <NotificationDebugActionSpec>[
      _spec(
        key: 'schedule_morning_athkar',
        notificationId: NotificationDebugConstants.morningAthkar,
        payload: NotificationDebugConstants.morningAthkarPayload(),
        l10n: l10n,
        mechanism: NotificationDebugMechanism.realLocalNotification,
        behavior: l10n.notificationDebugBehaviorScheduleAthkar,
        scheduleDelay: const Duration(seconds: 5),
      ),
      _spec(
        key: 'schedule_evening_athkar',
        notificationId: NotificationDebugConstants.eveningAthkar,
        payload: NotificationDebugConstants.eveningAthkarPayload(),
        l10n: l10n,
        mechanism: NotificationDebugMechanism.realLocalNotification,
        behavior: l10n.notificationDebugBehaviorScheduleAthkar,
        scheduleDelay: const Duration(seconds: 5),
      ),
      _spec(
        key: 'trigger_morning_athkar_now',
        notificationId: NotificationDebugConstants.morningAthkar,
        payload: NotificationDebugConstants.morningAthkarPayload(),
        l10n: l10n,
        mechanism: NotificationDebugMechanism.realLocalNotification,
        behavior: l10n.notificationDebugBehaviorShowNow,
      ),
      _spec(
        key: 'trigger_prayer_now',
        notificationId: NotificationDebugConstants.prayer,
        payload: NotificationDebugConstants.prayerPayload(),
        l10n: l10n,
        mechanism: NotificationDebugMechanism.realLocalNotification,
        behavior: l10n.notificationDebugBehaviorShowNow,
      ),
      _spec(
        key: 'trigger_native_prayer_payload_only',
        notificationId: null,
        payload: NotificationDebugConstants.prayerPayload(),
        l10n: l10n,
        mechanism: NotificationDebugMechanism.dispatcherSimulation,
        behavior: l10n.notificationDebugBehaviorNativePayloadOnly,
      ),
      _spec(
        key: 'trigger_tasbeeh',
        notificationId: NotificationDebugConstants.tasbeeh,
        payload: NotificationDebugConstants.tasbeehPayload(),
        l10n: l10n,
        mechanism: NotificationDebugMechanism.realLocalNotification,
        behavior: l10n.notificationDebugBehaviorShowNow,
      ),
      _spec(
        key: 'trigger_download',
        notificationId: NotificationDebugConstants.download,
        payload: NotificationDebugConstants.downloadPayload(),
        l10n: l10n,
        mechanism: NotificationDebugMechanism.realLocalNotification,
        behavior: l10n.notificationDebugBehaviorShowNow,
      ),
      _spec(
        key: 'trigger_invalid_payload',
        notificationId: NotificationDebugConstants.invalidPayloadId,
        payload: NotificationDebugConstants.invalidPayloadValue(),
        l10n: l10n,
        mechanism: NotificationDebugMechanism.dispatcherSimulation,
        behavior: l10n.notificationDebugBehaviorInvalidPayload,
      ),
      _spec(
        key: 'trigger_empty_payload',
        notificationId: NotificationDebugConstants.emptyPayload,
        payload: '',
        l10n: l10n,
        mechanism: NotificationDebugMechanism.dispatcherSimulation,
        behavior: l10n.notificationDebugBehaviorEmptyPayload,
      ),
      _spec(
        key: 'trigger_payload_only_no_id',
        notificationId: null,
        payload: NotificationDebugConstants.morningAthkarPayload(
          suffix: 'payload_only',
        ),
        l10n: l10n,
        mechanism: NotificationDebugMechanism.dispatcherSimulation,
        behavior: l10n.notificationDebugBehaviorPayloadOnlyNoId,
      ),
      _spec(
        key: 'same_id_same_payload',
        notificationId: NotificationDebugConstants.sameIdSamePayload,
        payload: NotificationDebugConstants.morningAthkarPayload(
          suffix: 'same_sig',
        ),
        l10n: l10n,
        mechanism: NotificationDebugMechanism.dispatcherSimulation,
        behavior: l10n.notificationDebugBehaviorDedupSameSig,
      ),
      _spec(
        key: 'same_id_different_payload',
        notificationId: NotificationDebugConstants.sameIdDifferentPayloadA,
        payload: NotificationDebugConstants.morningAthkarPayload(
          suffix: 'variant_b',
        ),
        l10n: l10n,
        mechanism: NotificationDebugMechanism.dispatcherSimulation,
        behavior: l10n.notificationDebugBehaviorFreshDifferentPayload,
      ),
      _spec(
        key: 'different_id_same_payload',
        notificationId: NotificationDebugConstants.differentIdSamePayload,
        payload: NotificationDebugConstants.morningAthkarPayload(
          suffix: 'shared_payload',
        ),
        l10n: l10n,
        mechanism: NotificationDebugMechanism.dispatcherSimulation,
        behavior: l10n.notificationDebugBehaviorSharedPayloadSig,
      ),
    ];
  }

  static List<NotificationDebugActionSpec> launchSimulationActions(
    AppLocalizations l10n,
  ) {
    return <NotificationDebugActionSpec>[
      _spec(
        key: 'simulate_athkar_launch',
        notificationId: NotificationDebugConstants.morningAthkar,
        payload: NotificationDebugConstants.morningAthkarPayload(),
        l10n: l10n,
        mechanism: NotificationDebugMechanism.bootstrapLaunchProbe,
        behavior: l10n.notificationDebugBehaviorSimulateTap,
      ),
      _spec(
        key: 'simulate_prayer_launch',
        notificationId: NotificationDebugConstants.prayer,
        payload: NotificationDebugConstants.prayerPayload(),
        l10n: l10n,
        mechanism: NotificationDebugMechanism.bootstrapLaunchProbe,
        behavior: l10n.notificationDebugBehaviorSimulateTap,
      ),
      _spec(
        key: 'simulate_settings_launch',
        notificationId: NotificationDebugConstants.download,
        payload: NotificationDebugConstants.settingsPayload(),
        l10n: l10n,
        mechanism: NotificationDebugMechanism.bootstrapLaunchProbe,
        behavior: l10n.notificationDebugBehaviorSimulateTap,
      ),
      _spec(
        key: 'simulate_invalid_launch',
        notificationId: NotificationDebugConstants.invalidPayloadId,
        payload: NotificationDebugConstants.invalidPayloadValue(),
        l10n: l10n,
        mechanism: NotificationDebugMechanism.bootstrapLaunchProbe,
        behavior: l10n.notificationDebugBehaviorInvalidLaunch,
      ),
      _spec(
        key: 'simulate_payload_only_prayer',
        notificationId: null,
        payload: NotificationDebugConstants.prayerPayload(),
        l10n: l10n,
        mechanism: NotificationDebugMechanism.bootstrapLaunchProbe,
        behavior: l10n.notificationDebugBehaviorNativePayloadOnly,
      ),
      _spec(
        key: 'simulate_already_processed',
        notificationId: NotificationDebugConstants.morningAthkar,
        payload: NotificationDebugConstants.morningAthkarPayload(),
        l10n: l10n,
        mechanism: NotificationDebugMechanism.dedupOnly,
        behavior: l10n.notificationDebugBehaviorMarkProcessed,
      ),
      _spec(
        key: 'simulate_fresh_pid_scope',
        notificationId: NotificationDebugConstants.morningAthkar,
        payload: NotificationDebugConstants.morningAthkarPayload(),
        l10n: l10n,
        mechanism: NotificationDebugMechanism.clearPidScope,
        behavior: l10n.notificationDebugBehaviorClearPidScope,
      ),
    ];
  }

  static NotificationDebugActionSpec _spec({
    required String key,
    required int? notificationId,
    required String? payload,
    required AppLocalizations l10n,
    required NotificationDebugMechanism mechanism,
    required String behavior,
    Duration? scheduleDelay,
  }) {
    final Map<String, dynamic>? data =
        NotificationNavigationResolver.notificationDataFromPayload(payload);
    final String route = data == null
        ? const HomeRoute().location
        : NotificationNavigationResolver.resolveLocation(data);
    return NotificationDebugActionSpec(
      key: key,
      notificationId: notificationId,
      payload: payload,
      expectedRoute: route,
      expectedBehavior: behavior,
      mechanism: mechanism,
      scheduleDelay: scheduleDelay,
    );
  }

  static String mechanismLabel(
    AppLocalizations l10n,
    NotificationDebugMechanism mechanism,
  ) {
    return switch (mechanism) {
      NotificationDebugMechanism.realLocalNotification =>
        l10n.notificationDebugMechanismReal,
      NotificationDebugMechanism.dispatcherSimulation =>
        l10n.notificationDebugMechanismDispatcher,
      NotificationDebugMechanism.bootstrapLaunchProbe =>
        l10n.notificationDebugMechanismBootstrap,
      NotificationDebugMechanism.dedupOnly =>
        l10n.notificationDebugMechanismDedup,
      NotificationDebugMechanism.clearPidScope =>
        l10n.notificationDebugMechanismClearPid,
    };
  }
}

import 'package:flutter/foundation.dart';

import '../features/prayer_times/presentation/widgets/prayer_alerts_permission_flow.dart';

/// In-session payload for [PrayerAlertsPermissionRoute] (not JSON-restorable).
@immutable
class PrayerAlertsPermissionNavExtra {
  const PrayerAlertsPermissionNavExtra({this.steps});

  /// When null, the screen derives steps from [PrayerPermissionsCubit].
  final List<PrayerAlertsPermissionStep>? steps;
}

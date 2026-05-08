import 'dart:io';
import 'package:injectable/injectable.dart';

import 'package:tilawa/features/prayer_times/domain/services/adhan_alarm_player_interface.dart';
import 'package:tilawa/core/services/android_adhan_alarm_player.dart';
import 'package:tilawa/core/services/noop_adhan_alarm_player.dart';

@module
abstract class AdhanModule {
  @lazySingleton
  IAdhanAlarmPlayer adhanAlarmPlayer(AndroidAdhanAlarmPlayer androidPlayer) {
    if (Platform.isAndroid) {
      return androidPlayer;
    } else {
      return const NoOpAdhanAlarmPlayer();
    }
  }
}

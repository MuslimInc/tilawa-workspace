import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/core/services/android_adhan_alarm_player.dart';
import 'package:tilawa/core/services/noop_adhan_alarm_player.dart';
import 'package:tilawa/features/prayer_times/domain/services/adhan_alarm_player_interface.dart';

class AdhanModule {
  AdhanModule._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<IAdhanAlarmPlayer>(() {
      if (!kIsWeb && Platform.isAndroid) {
        return getIt<AndroidAdhanAlarmPlayer>();
      }
      return const NoOpAdhanAlarmPlayer();
    });
  }
}

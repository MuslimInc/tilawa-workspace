import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tilawa/core/config/notification_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Shared Android notification chrome for Tilawa local notifications.
abstract final class AndroidNotificationDefaults {
  static const Color accentColor = AppColors.notificationAccent;

  static const String smallIcon = NotificationConfig.androidSmallIcon;

  static const AndroidInitializationSettings initializationSettings =
      AndroidInitializationSettings(smallIcon);
}

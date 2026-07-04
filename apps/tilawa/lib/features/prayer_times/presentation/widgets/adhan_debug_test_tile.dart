import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/services/notification_permission_service.dart';
import 'package:tilawa/features/prayer_times/domain/services/prayer_adhan_notification_service_interface.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Developer-only settings control for scheduling a manual Adhan test.
class AdhanDebugTestTile extends StatefulWidget {
  const AdhanDebugTestTile({
    super.key,
    this.isLast = false,
    this.debugMode = kDebugMode,
    this.notificationPermissionService,
    this.prayerNotificationService,
  });

  final bool isLast;
  final bool debugMode;
  final NotificationPermissionService? notificationPermissionService;
  final IPrayerAdhanNotificationService? prayerNotificationService;

  @override
  State<AdhanDebugTestTile> createState() => _AdhanDebugTestTileState();
}

class _AdhanDebugTestTileState extends State<AdhanDebugTestTile> {
  bool _isScheduling = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.debugMode) {
      return const SizedBox.shrink();
    }

    final tokens = Theme.of(context).tokens;

    return TilawaSettingsTile(
      title: context.l10n.adhanDebugTestTitle,
      subtitle: context.l10n.adhanDebugTestSubtitle,
      showDivider: !widget.isLast,
      trailing: _isScheduling
          ? SizedBox(
              width: tokens.iconSizeSmall,
              height: tokens.iconSizeSmall,
              child: const TilawaLoadingIndicator(
                centered: false,
                strokeWidth: 2.0,
              ),
            )
          : null,
      onTap: _scheduleAdhanTest,
    );
  }

  Future<void> _scheduleAdhanTest() async {
    if (_isScheduling) {
      return;
    }

    setState(() => _isScheduling = true);
    try {
      final notificationPermissions =
          widget.notificationPermissionService ??
          getIt<NotificationPermissionService>();
      await notificationPermissions.requestPermission();
      final hasPermission = await notificationPermissions.isPermissionGranted();
      if (!mounted) {
        return;
      }
      if (!hasPermission) {
        TilawaFeedback.showToast(
          context,
          message: context.l10n.adhanDebugPermissionMissing,
          variant: TilawaFeedbackVariant.error,
        );
        return;
      }

      final prayerNotifications =
          widget.prayerNotificationService ??
          getIt<IPrayerAdhanNotificationService>();
      await prayerNotifications.debugScheduleTestAdhan();
      if (!mounted) {
        return;
      }
      TilawaFeedback.showToast(
        context,
        message: context.l10n.adhanDebugScheduled,
        variant: TilawaFeedbackVariant.success,
      );
    } catch (_) {
      if (mounted) {
        TilawaFeedback.showToast(
          context,
          message: context.l10n.adhanDebugFailed,
          variant: TilawaFeedbackVariant.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isScheduling = false);
      }
    }
  }
}

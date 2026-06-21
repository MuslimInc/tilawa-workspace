import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/services/prayer_notification_config.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/fire_prayer_test_notification_use_case.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../router/app_router_config.dart';

class RouteListScreen extends StatelessWidget {
  const RouteListScreen({super.key, this.routes});

  final List<RouteBase>? routes;

  @override
  Widget build(BuildContext context) {
    final List<String> interactions = _getAllRoutes(routes ?? $appRoutes);
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: const TilawaAppBar(title: 'All Routes'),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'route_list_fajr_adhan_fab',
        tooltip: 'Preview Fajr adhan notification screen',
        onPressed: () => _previewFajrAdhanNotification(context),
        icon: const Icon(Icons.notifications_active_outlined),
        label: const Text('Fajr Adhan'),
      ),
      body: ListView.separated(
        itemCount: interactions.length,
        separatorBuilder: (context, index) => const TilawaDivider(height: 1),
        itemBuilder: (context, index) {
          final String path = interactions[index];
          final bool isClickable = !path.contains(':');

          return ListTile(
            title: Text(
              path,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'Courier',
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            trailing: isClickable
                ? Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant)
                : Chip(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    side: BorderSide(
                      color: colorScheme.outlineVariant,
                      width: tokens.borderWidthThin,
                    ),
                    label: Text(
                      'Parameterized',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
            onTap: isClickable ? () => context.push(path) : null,
          );
        },
      ),
    );
  }

  List<String> _getAllRoutes(List<RouteBase> routes, [String parentPath = '']) {
    final List<String> paths = [];

    for (final route in routes) {
      if (route is GoRoute) {
        String fullPath = parentPath + route.path;
        if (parentPath.isNotEmpty && route.path.startsWith('/')) {
          // Handle cases where sub-routes might be defined with absolute paths (though less common in nested config)
          // or standard concatenation.
          // GoRouter usually concatenates. If route.path is just "/" it might just be the parent.
          if (route.path != '/') {
            fullPath =
                parentPath +
                (parentPath.endsWith('/') ? '' : '/') +
                route.path.substring(1);
          }
        } else if (parentPath.isNotEmpty && !parentPath.endsWith('/')) {
          fullPath = '$parentPath/${route.path}';
        }

        // Clean up double slashes if any
        fullPath = fullPath.replaceAll('//', '/');

        paths.add(fullPath);

        // Recursively add sub-routes
        paths.addAll(_getAllRoutes(route.routes, fullPath));
      } else if (route is ShellRoute) {
        paths.addAll(_getAllRoutes(route.routes, parentPath));
      } else if (route is StatefulShellRoute) {
        for (final StatefulShellBranch branch in route.branches) {
          paths.addAll(_getAllRoutes(branch.routes, parentPath));
        }
      }
    }

    return paths;
  }
}

Future<void> _previewFajrAdhanNotification(BuildContext context) async {
  final int scheduledMs = DateTime.now().millisecondsSinceEpoch;
  final String payload = jsonEncode({
    PrayerNotificationConfig.payloadTypeKey:
        PrayerNotificationConfig.payloadTypeValue,
    PrayerNotificationConfig.payloadPrayerKey: PrayerType.fajr.name,
    'prayer_name': PrayerType.fajr.name,
    'prayer_key': PrayerType.fajr.name,
    'scheduled_time_ms': scheduledMs,
    'adhan_enabled': true,
    'sound_name': PrayerNotificationConfig.adhanSoundRawName,
    'notification_id': PrayerNotificationConfig.staticId(PrayerType.fajr),
  });

  try {
    await getIt<FirePrayerTestNotificationUseCase>()(
      prayer: PrayerType.fajr,
      playAdhan: true,
    );
    if (!context.mounted) return;
    await PrayerNotificationStatusRoute($extra: payload).push(context);
  } catch (e) {
    if (!context.mounted) return;
    TilawaFeedback.showToast(
      context,
      message: 'Fajr adhan preview failed: $e',
      variant: TilawaFeedbackVariant.error,
    );
  }
}

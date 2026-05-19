import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      appBar: AppBar(
        title: const Text('All Routes'),
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

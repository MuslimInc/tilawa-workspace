/// A framework component that product code must obtain through the UI Kit.
final class ComponentPolicy {
  const ComponentPolicy({
    required this.libraryUri,
    required this.className,
    required this.replacements,
  });

  final String libraryUri;
  final String className;
  final List<String> replacements;
}

/// The canonical list of confirmed framework-to-UI-Kit equivalents.
const componentPolicies = <ComponentPolicy>[
  ComponentPolicy(
    libraryUri: 'package:flutter/src/material/app_bar.dart',
    className: 'AppBar',
    replacements: <String>['TilawaAppBar', 'TilawaCatalogAppBar'],
  ),
  ComponentPolicy(
    libraryUri: 'package:flutter/src/material/app_bar.dart',
    className: 'SliverAppBar',
    replacements: <String>['TilawaSliverAppBar'],
  ),
];

/// A temporary, reviewed exception for one existing raw component use.
final class UiKitException {
  const UiKitException({
    required this.id,
    required this.pathSuffix,
    required this.component,
    required this.reason,
    required this.trackingReference,
  });

  final String id;
  final String pathSuffix;
  final String component;
  final String reason;
  final String trackingReference;
}

/// Reviewed migration debt. Every entry must have a reason and tracker.
const uiKitExceptions = <UiKitException>[
  UiKitException(
    id: 'UIKIT-APPBAR-ROUTER',
    pathSuffix: 'apps/tilawa/lib/router/app_router_config.dart',
    component: 'AppBar',
    reason: 'Router-owned error page does not yet accept TilawaAppBar.',
    trackingReference: 'docs/TODO.md#ui-kit-app-bar-migration',
  ),
  UiKitException(
    id: 'UIKIT-APPBAR-GENUI',
    pathSuffix:
        'apps/tilawa/lib/features/genui_assistant/presentation/screens/'
        'genui_assistant_screen.dart',
    component: 'AppBar',
    reason: 'The experimental screen still uses a non-localized prototype bar.',
    trackingReference: 'docs/TODO.md#ui-kit-app-bar-migration',
  ),
  UiKitException(
    id: 'UIKIT-APPBAR-SENTRY-FORM',
    pathSuffix:
        'apps/tilawa/lib/core/telemetry/tilawa_sentry_feedback_form.dart',
    component: 'AppBar',
    reason: 'The embedded Sentry form needs compatibility validation first.',
    trackingReference: 'docs/TODO.md#ui-kit-app-bar-migration',
  ),
  UiKitException(
    id: 'UIKIT-APPBAR-SENTRY-SCREENSHOT',
    pathSuffix:
        'apps/tilawa/lib/core/telemetry/tilawa_sentry_feedback_form.dart',
    component: 'AppBar',
    reason: 'The screenshot editor needs compatibility validation first.',
    trackingReference: 'docs/TODO.md#ui-kit-app-bar-migration',
  ),
  UiKitException(
    id: 'UIKIT-APPBAR-EMAIL-SIGNIN',
    pathSuffix:
        'apps/tilawa/lib/features/auth/presentation/screens/'
        'email_auth_screens.dart',
    component: 'AppBar',
    reason: 'Email auth navigation behavior requires migration verification.',
    trackingReference: 'docs/TODO.md#ui-kit-app-bar-migration',
  ),
  UiKitException(
    id: 'UIKIT-APPBAR-EMAIL-VERIFY',
    pathSuffix:
        'apps/tilawa/lib/features/auth/presentation/screens/'
        'email_auth_screens.dart',
    component: 'AppBar',
    reason: 'Email verification navigation requires migration verification.',
    trackingReference: 'docs/TODO.md#ui-kit-app-bar-migration',
  ),
  UiKitException(
    id: 'UIKIT-APPBAR-FORGOT-PASSWORD',
    pathSuffix:
        'apps/tilawa/lib/features/auth/presentation/screens/'
        'email_auth_screens.dart',
    component: 'AppBar',
    reason: 'Password recovery navigation requires migration verification.',
    trackingReference: 'docs/TODO.md#ui-kit-app-bar-migration',
  ),
  UiKitException(
    id: 'UIKIT-APPBAR-DEVICES-LIST',
    pathSuffix:
        'apps/tilawa/lib/features/auth/presentation/screens/'
        'manage_devices_screen.dart',
    component: 'AppBar',
    reason: 'The device list action layout needs parity verification.',
    trackingReference: 'docs/TODO.md#ui-kit-app-bar-migration',
  ),
  UiKitException(
    id: 'UIKIT-APPBAR-DEVICE-DETAIL',
    pathSuffix:
        'apps/tilawa/lib/features/auth/presentation/screens/'
        'manage_devices_screen.dart',
    component: 'AppBar',
    reason: 'The device detail action layout needs parity verification.',
    trackingReference: 'docs/TODO.md#ui-kit-app-bar-migration',
  ),
];

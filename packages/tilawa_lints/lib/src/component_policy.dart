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
  ComponentPolicy(
    libraryUri: 'package:flutter/src/material/elevated_button.dart',
    className: 'ElevatedButton',
    replacements: <String>['TilawaButton'],
  ),
  ComponentPolicy(
    libraryUri: 'package:flutter/src/material/filled_button.dart',
    className: 'FilledButton',
    replacements: <String>['TilawaButton'],
  ),
  ComponentPolicy(
    libraryUri: 'package:flutter/src/material/text_button.dart',
    className: 'TextButton',
    replacements: <String>['TilawaButton'],
  ),
  ComponentPolicy(
    libraryUri: 'package:flutter/src/material/outlined_button.dart',
    className: 'OutlinedButton',
    replacements: <String>['TilawaButton'],
  ),
  ComponentPolicy(
    libraryUri: 'package:flutter/src/material/chip.dart',
    className: 'Chip',
    replacements: <String>['TilawaChip'],
  ),
  ComponentPolicy(
    libraryUri: 'package:flutter/src/material/text_field.dart',
    className: 'TextField',
    replacements: <String>['TilawaTextField'],
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
  UiKitException(
    id: 'UIKIT-BUTTON-STARTUP-FATAL',
    pathSuffix: 'apps/tilawa/lib/core/bootstrap/app_startup_widgets.dart',
    component: 'FilledButton',
    reason:
        'The fatal-error app renders before the design-system theme and '
        'tokens exist, so TilawaButton (token-dependent) cannot be used.',
    trackingReference: 'docs/TODO.md#ui-kit-button-migration',
  ),
  UiKitException(
    id: 'SHELL-SCAFFOLD-ERROR-ROUTE',
    pathSuffix: 'apps/tilawa/lib/router/app_router_config.dart',
    component: 'Scaffold',
    reason:
        'Inline ErrorRoute placeholder is not a full feature screen; keep a '
        'minimal Material Scaffold until the error surface is redesigned.',
    trackingReference: 'docs/adr/009-shell-owns-keyboard-resize.md',
  ),
  UiKitException(
    id: 'SHELL-SCAFFOLD-GENUI-UNAVAILABLE',
    pathSuffix: 'apps/tilawa/lib/router/app_router_config.dart',
    component: 'Scaffold',
    reason:
        'SmartQuranPlanRoute unavailable fallback renders before GenUI deps '
        'are registered; temporary bare Scaffold only.',
    trackingReference: 'docs/adr/009-shell-owns-keyboard-resize.md',
  ),
];

bool isGeneratedDartFile(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.freezed.dart') ||
    path.endsWith('.gen.dart') ||
    path.endsWith('.config.dart') ||
    path.endsWith('.mocks.dart');

bool isUiKitImplementation(String path) =>
    path.replaceAll(r'\', '/').contains('/packages/ui_kit/lib/');

/// The interactive UI Kit gallery and the throwaway prototype app are
/// kit-adjacent infrastructure, not shipping product surfaces. Per the design
/// system policy, catalogs and prototypes get separate handling: the gallery
/// legitimately renders raw framework widgets to showcase and compare them, so
/// component-identity enforcement must not apply there.
bool isCatalogOrPrototypeApp(String path) {
  final normalized = path.replaceAll(r'\', '/');
  return normalized.contains('/apps/ui_kit_gallery/') ||
      normalized.contains('/apps/prototype/');
}

/// Developer-only diagnostic tooling (debug labs, the UI Kit demo screens)
/// is not a shipping product surface. It legitimately renders raw framework
/// widgets to exercise or compare them, so design-system component enforcement
/// does not apply — matching the catalog carve-out above.
bool isDeveloperToolingFile(String path) {
  final normalized = path.replaceAll(r'\', '/');
  return normalized.contains('/debug/') ||
      normalized.contains('/ui_kit_debug/');
}

/// Vendored third-party widget code adapted into the app tree (e.g. the
/// color-picker palette). It carries its own framework-level widgets and is
/// not brand product UI, so it is excluded like [flex_color_scheme].
bool isVendoredInAppWidgetLibrary(String path) {
  return path.replaceAll(r'\', '/').contains('/features/color_picker/');
}

bool isProductDartFile(String path) {
  final normalized = path.replaceAll(r'\', '/');
  if (isGeneratedDartFile(normalized) ||
      isUiKitImplementation(normalized) ||
      isCatalogOrPrototypeApp(normalized) ||
      isDeveloperToolingFile(normalized) ||
      isVendoredInAppWidgetLibrary(normalized)) {
    return false;
  }
  return normalized.contains('/lib/') &&
      !normalized.contains('/packages/tilawa_lints/lib/') &&
      !normalized.contains('/packages/flex_color_scheme/lib/');
}

/// Path markers for screens hosted under TilawaAdaptiveShell /
/// `AppShellRoute` — raw Material Scaffold must be TilawaShellChildScaffold
/// (ADR-009).
///
/// Outside-shell / immersive routes (auth login, Athkar, Quran reader,
/// splash, share composers, root overlays) intentionally omit these markers.
const shellHostedScaffoldPathMarkers = <String>[
  '/apps/tilawa/lib/features/home/presentation/screens/',
  '/apps/tilawa/lib/features/bookmarks/presentation/screens/',
  '/apps/tilawa/lib/features/history/presentation/screens/',
  '/apps/tilawa/lib/features/downloads/presentation/screens/',
  '/apps/tilawa/lib/features/settings/presentation/screens/',
  '/apps/tilawa/lib/features/support/presentation/screens/',
  '/apps/tilawa/lib/features/daily_guidance/presentation/screens/',
  '/apps/tilawa/lib/features/smart_khatma/presentation/screens/',
  '/apps/tilawa/lib/features/qibla/presentation/screens/',
  '/apps/tilawa/lib/features/reciters/presentation/screens/',
  '/apps/tilawa/lib/features/genui_assistant/presentation/screens/',
  '/apps/tilawa/lib/features/prayer_times/presentation/screens/prayer_times_screen.dart',
  '/apps/tilawa/lib/features/prayer_times/presentation/screens/prayer_notification_status_screen.dart',
  '/apps/tilawa/lib/features/auth/presentation/screens/manage_devices_screen.dart',
  '/apps/tilawa/lib/features/quran_reader/presentation/screens/quran_index_screen.dart',
  '/apps/tilawa/lib/features/quran_reader/presentation/screens/quran_render_demo_screen.dart',
  '/apps/tilawa/lib/screens/main_screen.dart',
  '/apps/tilawa/lib/screens/route_list_screen.dart',
  '/apps/tilawa/lib/screens/playlists_screen.dart',
  '/apps/tilawa/lib/router/app_router_config.dart',
];

/// Whether [path] is a shell-hosted product file that must not nest a raw
/// Scaffold under TilawaAdaptiveShell.
bool isShellHostedScaffoldScope(String path) {
  if (!isProductDartFile(path)) {
    return false;
  }
  final normalized = path.replaceAll(r'\', '/');
  return shellHostedScaffoldPathMarkers.any(normalized.contains);
}

/// Coverage manifest for public UI Kit widgets vs gallery demos.
///
/// Each [GalleryWidgetCoverage] entry maps a exported widget (or helper
/// function) to a [galleryCatalog] id. Skipped symbols are internal-only or
/// non-visual theme utilities documented with [skipReason].
class GalleryWidgetCoverage {
  const GalleryWidgetCoverage({
    required this.symbol,
    this.galleryId,
    this.skipReason,
  }) : assert(
         (galleryId != null) ^ (skipReason != null),
         'Provide galleryId or skipReason, not both',
       );

  final String symbol;
  final String? galleryId;
  final String? skipReason;

  bool get isSkipped => skipReason != null;
}

/// Maintained alongside [galleryCatalog]; CI fails when kit adds a widget
/// without a demo or an explicit skip entry.
const List<GalleryWidgetCoverage> galleryWidgetManifest = [
  // Atoms
  GalleryWidgetCoverage(symbol: 'TilawaButton', galleryId: 'tilawa_button'),
  GalleryWidgetCoverage(
    symbol: 'TilawaGoogleSignInButton',
    galleryId: 'tilawa_google_sign_in_button',
  ),
  GalleryWidgetCoverage(symbol: 'TilawaCard', galleryId: 'tilawa_card'),
  GalleryWidgetCoverage(symbol: 'TilawaDivider', galleryId: 'tilawa_divider'),
  GalleryWidgetCoverage(
    symbol: 'TilawaEmptyState',
    galleryId: 'tilawa_empty_state',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaErrorState',
    galleryId: 'tilawa_error_state',
  ),
  GalleryWidgetCoverage(symbol: 'TilawaIconBox', galleryId: 'tilawa_icon_box'),
  GalleryWidgetCoverage(
    symbol: 'TilawaIconToggle',
    galleryId: 'tilawa_icon_toggle',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaIllustratedState',
    galleryId: 'tilawa_illustrated_state',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaLoadingIndicator',
    galleryId: 'tilawa_loading_indicator',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaSectionTitle',
    galleryId: 'tilawa_section_title',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaSheetHandle',
    galleryId: 'tilawa_sheet_handle',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaStateVisual',
    galleryId: 'tilawa_state_visual',
  ),
  GalleryWidgetCoverage(symbol: 'TilawaCheckbox', galleryId: 'tilawa_checkbox'),
  GalleryWidgetCoverage(symbol: 'TilawaSwitch', galleryId: 'tilawa_switch'),
  GalleryWidgetCoverage(
    symbol: 'TilawaTextField',
    galleryId: 'tilawa_text_field',
  ),
  GalleryWidgetCoverage(
    symbol: 'HiddenThumbComponentShape',
    skipReason: 'Internal slider thumb shape; not user-facing',
  ),

  // Molecules
  GalleryWidgetCoverage(symbol: 'TilawaAppBar', galleryId: 'tilawa_app_bar'),
  GalleryWidgetCoverage(
    symbol: 'TilawaCatalogAppBar',
    galleryId: 'tilawa_catalog_app_bar',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaAlphabetScrollbar',
    galleryId: 'tilawa_alphabet_scrollbar',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaLanguageSwitcher',
    galleryId: 'tilawa_language_switcher',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaMetadataChip',
    galleryId: 'tilawa_metadata_chip',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaNavigationRow',
    galleryId: 'tilawa_navigation_row',
  ),
  GalleryWidgetCoverage(symbol: 'TilawaSeekBar', galleryId: 'tilawa_seek_bar'),
  GalleryWidgetCoverage(
    symbol: 'TilawaSelectionPill',
    galleryId: 'tilawa_selection_pill',
  ),
  GalleryWidgetCoverage(symbol: 'TilawaChip', galleryId: 'tilawa_chip'),
  GalleryWidgetCoverage(
    symbol: 'TilawaCountProgressRing',
    galleryId: 'tilawa_count_progress_ring',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaMetricTile',
    galleryId: 'tilawa_metric_tile',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaFeedbackStrip',
    galleryId: 'tilawa_feedback_strip',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaGlassPanel',
    galleryId: 'tilawa_glass_panel',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaIconActionButton',
    galleryId: 'tilawa_icon_action_button',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaPermissionBanner',
    galleryId: 'tilawa_permission_banner',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaPrimaryFab',
    galleryId: 'tilawa_primary_fab',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaQuickFilterBar',
    galleryId: 'tilawa_quick_filter_bar',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaSearchField',
    galleryId: 'tilawa_search_field',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaCatalogSettingsBody',
    galleryId: 'tilawa_catalog_settings',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaCatalogSettingsSection',
    skipReason: 'Composed in tilawa_catalog_settings demo',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaCatalogSettingsLinkRow',
    skipReason: 'Composed in tilawa_catalog_settings demo',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaCatalogSettingsSwitchRow',
    skipReason: 'Composed in tilawa_catalog_settings demo',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaCatalogSettingsProfileRow',
    skipReason: 'Composed in tilawa_catalog_settings demo',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaSectionHeader',
    galleryId: 'tilawa_section_header',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaSegmentedControl',
    galleryId: 'tilawa_segmented_control',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaSelectionTile',
    galleryId: 'tilawa_selection_tile',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaSettingsTile',
    galleryId: 'tilawa_settings_tile',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaSettingsSwitchTile',
    galleryId: 'tilawa_settings_switch_tile',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaStatusChip',
    galleryId: 'tilawa_status_chip',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaAppBarConfig',
    skipReason: 'Configuration constants; shown via TilawaAppBar demo',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaAppBarScope',
    skipReason: 'InheritedWidget scope; shown via TilawaAppBar demo',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaAppBarChrome',
    skipReason: 'Toolbar chrome helpers; shown via app bar demos',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaSliverAppBar',
    skipReason: 'Scroll variant; same API family as TilawaAppBar',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaSearchFieldSlot',
    skipReason: 'Internal catalog padding slot',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaSegment',
    skipReason: 'Segment data holder; shown in segmented control demo',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaSettingsGroupRowStyle',
    skipReason: 'Internal inherited row styling',
  ),

  // Organisms
  GalleryWidgetCoverage(
    symbol: 'ImmersiveComposerScaffold',
    galleryId: 'immersive_composer_scaffold',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaAdaptiveShell',
    galleryId: 'tilawa_adaptive_shell',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaMediaPlayerBar',
    galleryId: 'tilawa_media_player_bar',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaBackdropImageLayer',
    galleryId: 'tilawa_backdrop_image_layer',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaSettingsGroup',
    galleryId: 'tilawa_settings_group',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaShareFooterBar',
    galleryId: 'tilawa_share_footer_bar',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaAsyncContent',
    galleryId: 'tilawa_async_content',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaHeroSummaryCard',
    galleryId: 'tilawa_hero_summary_card',
  ),
  GalleryWidgetCoverage(
    symbol: 'BehanceFeaturedCardPattern',
    galleryId: 'behance_featured_card',
  ),
  GalleryWidgetCoverage(
    symbol: 'BehanceInstructionChipPattern',
    galleryId: 'behance_instruction_chip',
  ),
  GalleryWidgetCoverage(
    symbol: 'TravelDashboardSheetPattern',
    galleryId: 'travel_dashboard_sheet',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaNavDestination',
    skipReason: 'Shell destination model; shown in adaptive shell demo',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaHeroSummaryBadge',
    skipReason: 'Composed in tilawa_hero_summary_card demo',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaHeroSummaryProgress',
    skipReason: 'Composed in tilawa_hero_summary_card demo',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaHubNavigationGroup',
    skipReason: 'Composed in tilawa_navigation_row demo',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaSettingsGroupHorizontalInset',
    skipReason: 'Layout wrapper for settings/hub groups',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaSettingsGroupPanel',
    skipReason: 'Layout wrapper for settings/hub groups',
  ),

  // Foundation — interactive
  GalleryWidgetCoverage(
    symbol: 'TilawaContentBounds',
    galleryId: 'tilawa_content_bounds',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaContentGrid',
    galleryId: 'tilawa_content_grid',
  ),
  GalleryWidgetCoverage(
    symbol: 'showTilawaModalBottomSheet',
    galleryId: 'show_tilawa_modal_bottom_sheet',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaBottomSheetScaffold',
    galleryId: 'tilawa_bottom_sheet_scaffold',
  ),
  GalleryWidgetCoverage(
    symbol: 'showTilawaConfirmDialog',
    galleryId: 'show_tilawa_dialog',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaBottomSheetTitleRow',
    skipReason: 'Composed in sheet and dialog demos',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaBottomSheetActions',
    skipReason: 'Composed in sheet demos',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaDialog',
    skipReason: 'Private scaffold; use showTilawa*Dialog presets',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaFabLocation',
    skipReason: 'FAB placement helper; shown in primary FAB demo',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaThumbReachLayout',
    skipReason: 'Layout utility without standalone visual',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaBottomActionInset',
    skipReason: 'Layout inset utility without standalone visual',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaInteractiveSurface',
    skipReason: 'Low-level interaction primitive',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaInteractionFeedback',
    skipReason: 'Haptic helper; no visual demo',
  ),

  // Foundation — theme/tokens (no visual demo)
  GalleryWidgetCoverage(
    symbol: 'AppColors',
    skipReason: 'Color constants; covered by theme',
  ),
  GalleryWidgetCoverage(
    symbol: 'AppTheme',
    skipReason: 'Theme factory; gallery app applies AppTheme globally',
  ),
  GalleryWidgetCoverage(
    symbol: 'MeMuslimDesignTokens',
    skipReason: 'ThemeExtension tokens',
  ),
  GalleryWidgetCoverage(
    symbol: 'MeMuslimComponentTokens',
    skipReason: 'ThemeExtension tokens',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaBreakpoints',
    skipReason: 'Breakpoint constants',
  ),
  GalleryWidgetCoverage(
    symbol: 'DisplayFeatureInsets',
    skipReason: 'Display feature layout helper',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaResponsiveTypography',
    skipReason: 'Typography extension',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaShellPadding',
    skipReason: 'InheritedWidget padding scope',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaDensity',
    skipReason: 'Density enum for tokens',
  ),
  GalleryWidgetCoverage(
    symbol: 'TilawaSemanticTint',
    skipReason: 'Semantic tint enum used by components',
  ),
];

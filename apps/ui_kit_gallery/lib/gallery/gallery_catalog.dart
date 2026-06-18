import 'demos/atoms_demos.dart';
import 'demos/foundation_demos.dart';
import 'demos/molecules_demos.dart';
import 'demos/organisms_demos.dart';
import 'gallery_entry.dart';

/// All browsable UI Kit demos, grouped by atomic-design layer.
const List<GalleryEntry> galleryCatalog = [
  // Atoms
  GalleryEntry(
    id: 'tilawa_button',
    name: 'TilawaButton',
    category: GalleryCategory.atoms,
    description: 'Primary actions with variants, sizes, and loading state.',
    builder: AtomsDemos.button,
  ),
  GalleryEntry(
    id: 'tilawa_checkbox',
    name: 'TilawaCheckbox',
    category: GalleryCategory.atoms,
    description: '44×44 dp adaptive checkbox with compact visual slot.',
    builder: AtomsDemos.checkbox,
  ),
  GalleryEntry(
    id: 'tilawa_card',
    name: 'TilawaCard',
    category: GalleryCategory.atoms,
    builder: AtomsDemos.card,
  ),
  GalleryEntry(
    id: 'tilawa_divider',
    name: 'TilawaDivider',
    category: GalleryCategory.atoms,
    builder: AtomsDemos.divider,
  ),
  GalleryEntry(
    id: 'tilawa_empty_state',
    name: 'TilawaEmptyState',
    category: GalleryCategory.atoms,
    builder: AtomsDemos.emptyState,
  ),
  GalleryEntry(
    id: 'tilawa_error_state',
    name: 'TilawaErrorState',
    category: GalleryCategory.atoms,
    builder: AtomsDemos.errorState,
  ),
  GalleryEntry(
    id: 'tilawa_google_sign_in_button',
    name: 'TilawaGoogleSignInButton',
    category: GalleryCategory.atoms,
    description: 'Branded Sign in with Google control.',
    builder: AtomsDemos.googleSignInButton,
  ),
  GalleryEntry(
    id: 'tilawa_illustrated_state',
    name: 'TilawaIllustratedState',
    category: GalleryCategory.atoms,
    builder: AtomsDemos.illustratedState,
  ),
  GalleryEntry(
    id: 'tilawa_icon_box',
    name: 'TilawaIconBox',
    category: GalleryCategory.atoms,
    builder: AtomsDemos.iconBox,
  ),
  GalleryEntry(
    id: 'tilawa_icon_toggle',
    name: 'TilawaIconToggle',
    category: GalleryCategory.atoms,
    builder: AtomsDemos.iconToggle,
  ),
  GalleryEntry(
    id: 'tilawa_loading_indicator',
    name: 'TilawaLoadingIndicator',
    category: GalleryCategory.atoms,
    builder: AtomsDemos.loadingIndicator,
  ),
  GalleryEntry(
    id: 'tilawa_state_visual',
    name: 'TilawaStateVisual',
    category: GalleryCategory.atoms,
    description: 'Tone-based icon visual for empty and error states.',
    builder: AtomsDemos.stateVisual,
  ),
  GalleryEntry(
    id: 'tilawa_section_title',
    name: 'TilawaSectionTitle',
    category: GalleryCategory.atoms,
    builder: AtomsDemos.sectionTitle,
  ),
  GalleryEntry(
    id: 'tilawa_sheet_handle',
    name: 'TilawaSheetHandle',
    category: GalleryCategory.atoms,
    description: 'Drag handle with thumb-zone dismiss.',
    builder: AtomsDemos.sheetHandle,
  ),
  GalleryEntry(
    id: 'tilawa_switch',
    name: 'TilawaSwitch',
    category: GalleryCategory.atoms,
    description: '44×44 dp adaptive switch atom.',
    builder: AtomsDemos.switchAtom,
  ),
  GalleryEntry(
    id: 'tilawa_text_field',
    name: 'TilawaTextField',
    category: GalleryCategory.atoms,
    builder: AtomsDemos.textField,
  ),

  // Molecules
  GalleryEntry(
    id: 'tilawa_app_bar',
    name: 'TilawaAppBar',
    category: GalleryCategory.molecules,
    description: 'Standard feature scaffold app bar.',
    builder: MoleculesDemos.appBar,
  ),
  GalleryEntry(
    id: 'tilawa_alphabet_scrollbar',
    name: 'TilawaAlphabetScrollbar',
    category: GalleryCategory.molecules,
    builder: MoleculesDemos.alphabetScrollbar,
  ),
  GalleryEntry(
    id: 'tilawa_chip',
    name: 'TilawaChip',
    category: GalleryCategory.molecules,
    builder: MoleculesDemos.chip,
  ),
  GalleryEntry(
    id: 'tilawa_catalog_app_bar',
    name: 'TilawaCatalogAppBar',
    category: GalleryCategory.molecules,
    description: 'Parchment catalog header with optional search row.',
    builder: MoleculesDemos.catalogAppBar,
  ),
  GalleryEntry(
    id: 'tilawa_catalog_settings',
    name: 'TilawaCatalogSettings',
    category: GalleryCategory.molecules,
    description: 'Flat Pinterest-style settings sections and rows.',
    builder: MoleculesDemos.catalogSettings,
  ),
  GalleryEntry(
    id: 'tilawa_count_progress_ring',
    name: 'TilawaCountProgressRing',
    category: GalleryCategory.molecules,
    builder: MoleculesDemos.countProgressRing,
  ),
  GalleryEntry(
    id: 'tilawa_feedback_strip',
    name: 'TilawaFeedbackStrip',
    category: GalleryCategory.molecules,
    builder: MoleculesDemos.feedbackStrip,
  ),
  GalleryEntry(
    id: 'tilawa_glass_panel',
    name: 'TilawaGlassPanel',
    category: GalleryCategory.molecules,
    builder: MoleculesDemos.glassPanel,
  ),
  GalleryEntry(
    id: 'tilawa_icon_action_button',
    name: 'TilawaIconActionButton',
    category: GalleryCategory.molecules,
    builder: MoleculesDemos.iconActionButton,
  ),
  GalleryEntry(
    id: 'tilawa_language_switcher',
    name: 'TilawaLanguageSwitcher',
    category: GalleryCategory.molecules,
    builder: MoleculesDemos.languageSwitcher,
  ),
  GalleryEntry(
    id: 'tilawa_metadata_chip',
    name: 'TilawaMetadataChip',
    category: GalleryCategory.molecules,
    builder: MoleculesDemos.metadataChip,
  ),
  GalleryEntry(
    id: 'tilawa_navigation_row',
    name: 'TilawaNavigationRow',
    category: GalleryCategory.molecules,
    description: 'Hub drill-down row inside TilawaHubNavigationGroup.',
    builder: MoleculesDemos.navigationRow,
  ),
  GalleryEntry(
    id: 'tilawa_permission_banner',
    name: 'TilawaPermissionBanner',
    category: GalleryCategory.molecules,
    builder: MoleculesDemos.permissionBanner,
  ),
  GalleryEntry(
    id: 'tilawa_primary_fab',
    name: 'TilawaPrimaryFab',
    category: GalleryCategory.molecules,
    description: 'Primary floating action with TilawaFabLocation helper.',
    builder: MoleculesDemos.primaryFab,
  ),
  GalleryEntry(
    id: 'tilawa_quick_filter_bar',
    name: 'TilawaQuickFilterBar',
    category: GalleryCategory.molecules,
    description: 'Horizontal catalog filter pill strip.',
    builder: MoleculesDemos.quickFilterBar,
  ),
  GalleryEntry(
    id: 'tilawa_search_field',
    name: 'TilawaSearchField',
    category: GalleryCategory.molecules,
    builder: MoleculesDemos.searchField,
  ),
  GalleryEntry(
    id: 'tilawa_section_header',
    name: 'TilawaSectionHeader',
    category: GalleryCategory.molecules,
    builder: MoleculesDemos.sectionHeader,
  ),
  GalleryEntry(
    id: 'tilawa_seek_bar',
    name: 'TilawaSeekBar',
    category: GalleryCategory.molecules,
    builder: MoleculesDemos.seekBar,
  ),
  GalleryEntry(
    id: 'tilawa_segmented_control',
    name: 'TilawaSegmentedControl',
    category: GalleryCategory.molecules,
    builder: MoleculesDemos.segmentedControl,
  ),
  GalleryEntry(
    id: 'tilawa_selection_pill',
    name: 'TilawaSelectionPill',
    category: GalleryCategory.molecules,
    builder: MoleculesDemos.selectionPill,
  ),
  GalleryEntry(
    id: 'tilawa_selection_tile',
    name: 'TilawaSelectionTile',
    category: GalleryCategory.molecules,
    builder: MoleculesDemos.selectionTile,
  ),
  GalleryEntry(
    id: 'tilawa_settings_tile',
    name: 'TilawaSettingsTile',
    category: GalleryCategory.molecules,
    builder: MoleculesDemos.settingsTile,
  ),
  GalleryEntry(
    id: 'tilawa_settings_switch_tile',
    name: 'TilawaSettingsSwitchTile',
    category: GalleryCategory.molecules,
    description: 'Settings row with TilawaSwitch trailing control.',
    builder: MoleculesDemos.settingsSwitchTile,
  ),
  GalleryEntry(
    id: 'tilawa_status_chip',
    name: 'TilawaStatusChip',
    category: GalleryCategory.molecules,
    builder: MoleculesDemos.statusChip,
  ),

  // Organisms
  GalleryEntry(
    id: 'tilawa_adaptive_shell',
    name: 'TilawaAdaptiveShell',
    category: GalleryCategory.organisms,
    builder: OrganismsDemos.adaptiveShell,
  ),
  GalleryEntry(
    id: 'tilawa_backdrop_image_layer',
    name: 'TilawaBackdropImageLayer',
    category: GalleryCategory.organisms,
    builder: OrganismsDemos.backdropImageLayer,
  ),
  GalleryEntry(
    id: 'tilawa_bottom_sheet_scaffold',
    name: 'TilawaBottomSheetScaffold',
    category: GalleryCategory.organisms,
    description: 'Modal sheet helper with drag-to-dismiss handle.',
    builder: OrganismsDemos.bottomSheetScaffold,
  ),
  GalleryEntry(
    id: 'immersive_composer_scaffold',
    name: 'ImmersiveComposerScaffold',
    category: GalleryCategory.organisms,
    builder: OrganismsDemos.immersiveComposer,
  ),
  GalleryEntry(
    id: 'tilawa_media_player_bar',
    name: 'TilawaMediaPlayerBar',
    category: GalleryCategory.organisms,
    builder: OrganismsDemos.mediaPlayerBar,
  ),
  GalleryEntry(
    id: 'tilawa_settings_group',
    name: 'TilawaSettingsGroup',
    category: GalleryCategory.organisms,
    builder: OrganismsDemos.settingsGroup,
  ),
  GalleryEntry(
    id: 'tilawa_share_footer_bar',
    name: 'TilawaShareFooterBar',
    category: GalleryCategory.organisms,
    builder: OrganismsDemos.shareFooterBar,
  ),
  GalleryEntry(
    id: 'tilawa_async_content',
    name: 'TilawaAsyncContent',
    category: GalleryCategory.organisms,
    description: 'Loading, empty, error, and content states with retry.',
    builder: OrganismsDemos.asyncContent,
  ),
  GalleryEntry(
    id: 'tilawa_hero_summary_card',
    name: 'TilawaHeroSummaryCard',
    category: GalleryCategory.organisms,
    description: 'Dashboard summary card with badges and progress footer.',
    builder: OrganismsDemos.heroSummaryCard,
  ),
  GalleryEntry(
    id: 'behance_featured_card',
    name: 'Behance Featured Card',
    category: GalleryCategory.organisms,
    description: 'Warm gold gradient Last Read dashboard card pattern.',
    builder: OrganismsDemos.behanceFeaturedCard,
  ),
  GalleryEntry(
    id: 'travel_dashboard_sheet',
    name: 'Travel Dashboard Sheet',
    category: GalleryCategory.organisms,
    description:
        'Ronas IT–style hero gradient with overlapping parchment content lip.',
    builder: OrganismsDemos.travelDashboardSheet,
  ),
  GalleryEntry(
    id: 'behance_instruction_chip',
    name: 'Behance Instruction Chip',
    category: GalleryCategory.organisms,
    description: 'Qibla rotation hint chip on parchment tertiary fill.',
    builder: OrganismsDemos.behanceInstructionChip,
  ),

  // Foundation
  GalleryEntry(
    id: 'tilawa_content_bounds',
    name: 'TilawaContentBounds',
    category: GalleryCategory.foundation,
    description:
        'Token-backed max-width clamp for reader, form, media, settings.',
    builder: FoundationDemos.contentBounds,
  ),
  GalleryEntry(
    id: 'tilawa_content_grid',
    name: 'TilawaContentGrid',
    category: GalleryCategory.foundation,
    description: 'Responsive grid with max cross-axis extent.',
    builder: FoundationDemos.contentGrid,
  ),
  GalleryEntry(
    id: 'show_tilawa_dialog',
    name: 'showTilawaDialog',
    category: GalleryCategory.foundation,
    description: 'Centered confirm and picker dialog presets.',
    builder: FoundationDemos.dialog,
  ),
  GalleryEntry(
    id: 'show_tilawa_modal_bottom_sheet',
    name: 'showTilawaModalBottomSheet',
    category: GalleryCategory.foundation,
    description: 'Modal sheet helper composed with TilawaBottomSheetScaffold.',
    builder: FoundationDemos.modalBottomSheet,
  ),
];

GalleryEntry? findGalleryEntry(String id) {
  for (final entry in galleryCatalog) {
    if (entry.id == id) return entry;
  }
  return null;
}

Map<GalleryCategory, List<GalleryEntry>> groupGalleryCatalog() {
  final grouped = <GalleryCategory, List<GalleryEntry>>{};
  for (final category in GalleryCategory.values) {
    grouped[category] = [];
  }
  for (final entry in galleryCatalog) {
    grouped[entry.category]!.add(entry);
  }
  return grouped;
}

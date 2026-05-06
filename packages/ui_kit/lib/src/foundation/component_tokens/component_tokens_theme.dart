import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../density.dart';
import 'atoms_tokens.dart';
import 'molecules_tokens.dart';
import 'organisms_tokens.dart';

@immutable
class TilawaComponentTokens extends ThemeExtension<TilawaComponentTokens> {
  const TilawaComponentTokens({
    required this.density,
    required this.sectionTitle,
    required this.sheetHandle,
    required this.card,
    required this.iconBox,
    required this.loadingIndicator,
    required this.divider,
    required this.emptyState,
    required this.errorState,
    required this.alphabetScrollbar,
    required this.feedbackStrip,
    required this.glassPanel,
    required this.iconActionButton,
    required this.chip,
    required this.segmentedControl,
    required this.seekBar,
    required this.searchField,
    required this.countProgressRing,
    required this.playerBackground,
    required this.footerBar,
    required this.mediaPlayerBar,
    required this.adaptiveShell,
    required this.settingsGroup,
    required this.immersiveComposer,
    required this.iconToggle,
    required this.permissionBanner,
    required this.prayerAlertRow,
    required this.bottomSheetScaffold,
    required this.skeleton,
  });

  final TilawaSectionTitleTokens sectionTitle;
  final TilawaSheetHandleTokens sheetHandle;
  final TilawaCardTokens card;
  final TilawaIconBoxTokens iconBox;
  final TilawaLoadingIndicatorTokens loadingIndicator;
  final TilawaDividerTokens divider;
  final TilawaEmptyStateTokens emptyState;
  final TilawaErrorStateTokens errorState;
  final TilawaAlphabetScrollbarTokens alphabetScrollbar;
  final TilawaFeedbackStripTokens feedbackStrip;
  final TilawaGlassPanelTokens glassPanel;
  final TilawaIconActionButtonTokens iconActionButton;
  final TilawaChipTokens chip;
  final TilawaSegmentedControlTokens segmentedControl;
  final TilawaSeekBarTokens seekBar;
  final TilawaSearchFieldTokens searchField;
  final TilawaCountProgressRingTokens countProgressRing;
  final TilawaPlayerBackgroundTokens playerBackground;
  final TilawaFooterBarTokens footerBar;
  final TilawaMediaPlayerBarTokens mediaPlayerBar;
  final TilawaAdaptiveShellTokens adaptiveShell;
  final TilawaSettingsGroupTokens settingsGroup;
  final TilawaImmersiveComposerTokens immersiveComposer;
  final TilawaIconToggleTokens iconToggle;
  final TilawaPermissionBannerTokens permissionBanner;
  final TilawaPrayerAlertRowTokens prayerAlertRow;
  final TilawaBottomSheetScaffoldTokens bottomSheetScaffold;
  final TilawaSkeletonTokens skeleton;

  /// The density mode for this component token set.
  final TilawaDensity density;

  /// Creates light theme component tokens.
  ///
  /// [density] controls component sizing. In Phase 0, both modes produce
  /// identical values. Future phases will implement compact-specific values
  /// per component family.
  factory TilawaComponentTokens.light({
    TilawaDensity density = TilawaDensity.comfortable,
    ColorScheme? colorScheme,
  }) => TilawaComponentTokens._create(
    density: density,
    brightness: Brightness.light,
    colorScheme: colorScheme,
  );

  factory TilawaComponentTokens.dark({
    TilawaDensity density = TilawaDensity.comfortable,
    ColorScheme? colorScheme,
  }) => TilawaComponentTokens._create(
    density: density,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
  );

  /// Internal factory for creating tokens with the given density and brightness.
  factory TilawaComponentTokens._create({
    required TilawaDensity density,
    required Brightness brightness,
    ColorScheme? colorScheme,
  }) {
    final effectiveColorScheme =
        colorScheme ??
        ColorScheme.fromSeed(
          seedColor: AppColors.defaultPrimary,
          brightness: brightness,
        );
    return TilawaComponentTokens(
      density: density,
      sectionTitle: TilawaSectionTitleTokens.defaults(density: density),
      sheetHandle: TilawaSheetHandleTokens.defaults(density: density),
      card: TilawaCardTokens.defaults(density: density),
      iconBox: TilawaIconBoxTokens.defaults(density: density),
      loadingIndicator: TilawaLoadingIndicatorTokens.defaults(density: density),
      divider: TilawaDividerTokens.defaults(density: density),
      emptyState: TilawaEmptyStateTokens.defaults(density: density),
      errorState: TilawaErrorStateTokens.defaults(density: density),
      alphabetScrollbar: TilawaAlphabetScrollbarTokens.defaults(
        density: density,
      ),
      feedbackStrip: TilawaFeedbackStripTokens.defaults(density: density),
      glassPanel: TilawaGlassPanelTokens.defaults(density: density),
      iconActionButton: TilawaIconActionButtonTokens.defaults(density: density),
      chip: TilawaChipTokens.defaults(density: density),
      segmentedControl: TilawaSegmentedControlTokens.defaults(density: density),
      seekBar: TilawaSeekBarTokens.defaults(density: density),
      searchField: TilawaSearchFieldTokens.defaults(density: density),
      countProgressRing: TilawaCountProgressRingTokens.defaults(
        density: density,
      ),
      playerBackground: TilawaPlayerBackgroundTokens.defaults(density: density),
      footerBar: TilawaFooterBarTokens.defaults(density: density),
      mediaPlayerBar: TilawaMediaPlayerBarTokens.defaults(density: density),
      adaptiveShell: TilawaAdaptiveShellTokens.defaults(density: density),
      settingsGroup: TilawaSettingsGroupTokens.defaults(density: density),
      immersiveComposer: TilawaImmersiveComposerTokens.defaults(
        density: density,
      ),
      iconToggle: TilawaIconToggleTokens.defaults(density: density),
      permissionBanner: TilawaPermissionBannerTokens.defaults(density: density),
      prayerAlertRow: TilawaPrayerAlertRowTokens.defaults(density: density),
      bottomSheetScaffold: TilawaBottomSheetScaffoldTokens.defaults(
        density: density,
      ),
      skeleton: TilawaSkeletonTokens.defaults(
        colorScheme: effectiveColorScheme,
        density: density,
      ),
    );
  }

  @override
  TilawaComponentTokens copyWith({
    TilawaDensity? density,
    TilawaSectionTitleTokens? sectionTitle,
    TilawaSheetHandleTokens? sheetHandle,
    TilawaCardTokens? card,
    TilawaIconBoxTokens? iconBox,
    TilawaLoadingIndicatorTokens? loadingIndicator,
    TilawaDividerTokens? divider,
    TilawaEmptyStateTokens? emptyState,
    TilawaErrorStateTokens? errorState,
    TilawaAlphabetScrollbarTokens? alphabetScrollbar,
    TilawaFeedbackStripTokens? feedbackStrip,
    TilawaGlassPanelTokens? glassPanel,
    TilawaIconActionButtonTokens? iconActionButton,
    TilawaChipTokens? chip,
    TilawaSegmentedControlTokens? segmentedControl,
    TilawaSeekBarTokens? seekBar,
    TilawaSearchFieldTokens? searchField,
    TilawaCountProgressRingTokens? countProgressRing,
    TilawaPlayerBackgroundTokens? playerBackground,
    TilawaFooterBarTokens? footerBar,
    TilawaMediaPlayerBarTokens? mediaPlayerBar,
    TilawaAdaptiveShellTokens? adaptiveShell,
    TilawaSettingsGroupTokens? settingsGroup,
    TilawaImmersiveComposerTokens? immersiveComposer,
    TilawaIconToggleTokens? iconToggle,
    TilawaPermissionBannerTokens? permissionBanner,
    TilawaPrayerAlertRowTokens? prayerAlertRow,
    TilawaBottomSheetScaffoldTokens? bottomSheetScaffold,
    TilawaSkeletonTokens? skeleton,
  }) {
    return TilawaComponentTokens(
      density: density ?? this.density,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      sheetHandle: sheetHandle ?? this.sheetHandle,
      card: card ?? this.card,
      iconBox: iconBox ?? this.iconBox,
      loadingIndicator: loadingIndicator ?? this.loadingIndicator,
      divider: divider ?? this.divider,
      emptyState: emptyState ?? this.emptyState,
      errorState: errorState ?? this.errorState,
      alphabetScrollbar: alphabetScrollbar ?? this.alphabetScrollbar,
      feedbackStrip: feedbackStrip ?? this.feedbackStrip,
      glassPanel: glassPanel ?? this.glassPanel,
      iconActionButton: iconActionButton ?? this.iconActionButton,
      chip: chip ?? this.chip,
      segmentedControl: segmentedControl ?? this.segmentedControl,
      seekBar: seekBar ?? this.seekBar,
      searchField: searchField ?? this.searchField,
      countProgressRing: countProgressRing ?? this.countProgressRing,
      playerBackground: playerBackground ?? this.playerBackground,
      footerBar: footerBar ?? this.footerBar,
      mediaPlayerBar: mediaPlayerBar ?? this.mediaPlayerBar,
      adaptiveShell: adaptiveShell ?? this.adaptiveShell,
      settingsGroup: settingsGroup ?? this.settingsGroup,
      immersiveComposer: immersiveComposer ?? this.immersiveComposer,
      iconToggle: iconToggle ?? this.iconToggle,
      permissionBanner: permissionBanner ?? this.permissionBanner,
      prayerAlertRow: prayerAlertRow ?? this.prayerAlertRow,
      bottomSheetScaffold: bottomSheetScaffold ?? this.bottomSheetScaffold,
      skeleton: skeleton ?? this.skeleton,
    );
  }

  @override
  TilawaComponentTokens lerp(
    ThemeExtension<TilawaComponentTokens>? other,
    double t,
  ) {
    if (other is! TilawaComponentTokens) return this;
    // Preserve density of 'this' token during lerp.
    return TilawaComponentTokens(
      density: density,
      sectionTitle: TilawaSectionTitleTokens.lerp(
        sectionTitle,
        other.sectionTitle,
        t,
      ),
      sheetHandle: TilawaSheetHandleTokens.lerp(
        sheetHandle,
        other.sheetHandle,
        t,
      ),
      card: TilawaCardTokens.lerp(card, other.card, t),
      iconBox: TilawaIconBoxTokens.lerp(iconBox, other.iconBox, t),
      loadingIndicator: TilawaLoadingIndicatorTokens.lerp(
        loadingIndicator,
        other.loadingIndicator,
        t,
      ),
      divider: TilawaDividerTokens.lerp(divider, other.divider, t),
      emptyState: TilawaEmptyStateTokens.lerp(emptyState, other.emptyState, t),
      errorState: TilawaErrorStateTokens.lerp(errorState, other.errorState, t),
      alphabetScrollbar: TilawaAlphabetScrollbarTokens.lerp(
        alphabetScrollbar,
        other.alphabetScrollbar,
        t,
      ),
      feedbackStrip: TilawaFeedbackStripTokens.lerp(
        feedbackStrip,
        other.feedbackStrip,
        t,
      ),
      glassPanel: TilawaGlassPanelTokens.lerp(glassPanel, other.glassPanel, t),
      iconActionButton: TilawaIconActionButtonTokens.lerp(
        iconActionButton,
        other.iconActionButton,
        t,
      ),
      chip: TilawaChipTokens.lerp(chip, other.chip, t),
      segmentedControl: TilawaSegmentedControlTokens.lerp(
        segmentedControl,
        other.segmentedControl,
        t,
      ),
      seekBar: TilawaSeekBarTokens.lerp(seekBar, other.seekBar, t),
      searchField: TilawaSearchFieldTokens.lerp(
        searchField,
        other.searchField,
        t,
      ),
      countProgressRing: TilawaCountProgressRingTokens.lerp(
        countProgressRing,
        other.countProgressRing,
        t,
      ),
      playerBackground: TilawaPlayerBackgroundTokens.lerp(
        playerBackground,
        other.playerBackground,
        t,
      ),
      footerBar: TilawaFooterBarTokens.lerp(footerBar, other.footerBar, t),
      mediaPlayerBar: TilawaMediaPlayerBarTokens.lerp(
        mediaPlayerBar,
        other.mediaPlayerBar,
        t,
      ),
      adaptiveShell: TilawaAdaptiveShellTokens.lerp(
        adaptiveShell,
        other.adaptiveShell,
        t,
      ),
      settingsGroup: TilawaSettingsGroupTokens.lerp(
        settingsGroup,
        other.settingsGroup,
        t,
      ),
      immersiveComposer: TilawaImmersiveComposerTokens.lerp(
        immersiveComposer,
        other.immersiveComposer,
        t,
      ),
      iconToggle: TilawaIconToggleTokens.lerp(iconToggle, other.iconToggle, t),
      permissionBanner: TilawaPermissionBannerTokens.lerp(
        permissionBanner,
        other.permissionBanner,
        t,
      ),
      prayerAlertRow: TilawaPrayerAlertRowTokens.lerp(
        prayerAlertRow,
        other.prayerAlertRow,
        t,
      ),
      bottomSheetScaffold: TilawaBottomSheetScaffoldTokens.lerp(
        bottomSheetScaffold,
        other.bottomSheetScaffold,
        t,
      ),
      skeleton: TilawaSkeletonTokens.lerp(skeleton, other.skeleton, t),
    );
  }
}

extension TilawaComponentTokensX on ThemeData {
  TilawaComponentTokens get componentTokens =>
      extension<TilawaComponentTokens>() ?? TilawaComponentTokens.light();
}

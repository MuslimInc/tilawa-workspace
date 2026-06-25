import 'package:flutter/material.dart';

import '../app_colors.dart';
import 'atoms_tokens.dart';
import 'molecules_tokens.dart';
import 'organisms_tokens.dart';

@immutable
class MeMuslimComponentTokens extends ThemeExtension<MeMuslimComponentTokens> {
  const MeMuslimComponentTokens({
    required this.sectionTitle,
    required this.sheetHandle,
    required this.card,
    required this.iconBox,
    required this.loadingIndicator,
    required this.divider,
    required this.emptyState,
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
    required this.bottomSheetScaffold,
    required this.homeNextPrayerHero,
    required this.homeDashboardCard,
    required this.capabilityActionCard,
    required this.experimentalBadge,
    required this.cupertinoWheelPicker,
  });

  final TilawaSectionTitleTokens sectionTitle;
  final TilawaSheetHandleTokens sheetHandle;
  final TilawaCardTokens card;
  final TilawaIconBoxTokens iconBox;
  final TilawaLoadingIndicatorTokens loadingIndicator;
  final TilawaDividerTokens divider;
  final TilawaEmptyStateTokens emptyState;
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
  final TilawaBottomSheetScaffoldTokens bottomSheetScaffold;
  final TilawaHomeNextPrayerHeroTokens homeNextPrayerHero;
  final TilawaHomeDashboardCardTokens homeDashboardCard;
  final TilawaCapabilityActionCardTokens capabilityActionCard;
  final TilawaExperimentalBadgeTokens experimentalBadge;
  final TilawaCupertinoWheelPickerTokens cupertinoWheelPicker;

  /// Creates light theme component tokens.
  factory MeMuslimComponentTokens.light({ColorScheme? colorScheme}) =>
      MeMuslimComponentTokens._create(
        brightness: Brightness.light,
        colorScheme: colorScheme,
      );

  factory MeMuslimComponentTokens.dark({ColorScheme? colorScheme}) =>
      MeMuslimComponentTokens._create(
        brightness: Brightness.dark,
        colorScheme: colorScheme,
      );

  /// Internal factory for creating tokens with the given brightness.
  factory MeMuslimComponentTokens._create({
    required Brightness brightness,
    ColorScheme? colorScheme,
  }) {
    final effectiveColorScheme =
        colorScheme ??
        ColorScheme.fromSeed(
          seedColor: AppColors.defaultPrimary,
          brightness: brightness,
        );
    return MeMuslimComponentTokens(
      sectionTitle: TilawaSectionTitleTokens.defaults(),
      sheetHandle: TilawaSheetHandleTokens.defaults(),
      card: TilawaCardTokens.defaults(),
      iconBox: TilawaIconBoxTokens.fromColorScheme(effectiveColorScheme),
      loadingIndicator: TilawaLoadingIndicatorTokens.defaults(),
      divider: TilawaDividerTokens.defaults(),
      emptyState: TilawaEmptyStateTokens.defaults(),
      alphabetScrollbar: TilawaAlphabetScrollbarTokens.fromColorScheme(
        effectiveColorScheme,
      ),
      feedbackStrip: TilawaFeedbackStripTokens.defaults(),
      glassPanel: TilawaGlassPanelTokens.defaults(),
      iconActionButton: TilawaIconActionButtonTokens.defaults(),
      chip: TilawaChipTokens.fromColorScheme(effectiveColorScheme),
      segmentedControl: TilawaSegmentedControlTokens.fromColorScheme(
        effectiveColorScheme,
      ),
      seekBar: TilawaSeekBarTokens.defaults(),
      searchField: TilawaSearchFieldTokens.fromColorScheme(
        effectiveColorScheme,
      ),
      countProgressRing: TilawaCountProgressRingTokens.defaults(),
      playerBackground: TilawaPlayerBackgroundTokens.defaults(),
      footerBar: TilawaFooterBarTokens.defaults(),
      mediaPlayerBar: TilawaMediaPlayerBarTokens.fromColorScheme(
        effectiveColorScheme,
      ),
      adaptiveShell: TilawaAdaptiveShellTokens.fromColorScheme(
        effectiveColorScheme,
      ),
      settingsGroup: TilawaSettingsGroupTokens.fromColorScheme(
        effectiveColorScheme,
      ),
      immersiveComposer: TilawaImmersiveComposerTokens.fromColorScheme(
        effectiveColorScheme,
      ),
      iconToggle: TilawaIconToggleTokens.fromColorScheme(effectiveColorScheme),
      permissionBanner: TilawaPermissionBannerTokens.defaults(),
      bottomSheetScaffold: TilawaBottomSheetScaffoldTokens.defaults(),
      homeNextPrayerHero: TilawaHomeNextPrayerHeroTokens.defaults(),
      homeDashboardCard: TilawaHomeDashboardCardTokens.fromColorScheme(
        effectiveColorScheme,
      ),
      capabilityActionCard: TilawaCapabilityActionCardTokens.fromColorScheme(
        effectiveColorScheme,
      ),
      experimentalBadge: TilawaExperimentalBadgeTokens.fromColorScheme(
        effectiveColorScheme,
      ),
      cupertinoWheelPicker: TilawaCupertinoWheelPickerTokens.fromColorScheme(
        effectiveColorScheme,
      ),
    );
  }

  @override
  MeMuslimComponentTokens copyWith({
    TilawaSectionTitleTokens? sectionTitle,
    TilawaSheetHandleTokens? sheetHandle,
    TilawaCardTokens? card,
    TilawaIconBoxTokens? iconBox,
    TilawaLoadingIndicatorTokens? loadingIndicator,
    TilawaDividerTokens? divider,
    TilawaEmptyStateTokens? emptyState,
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
    TilawaBottomSheetScaffoldTokens? bottomSheetScaffold,
    TilawaHomeNextPrayerHeroTokens? homeNextPrayerHero,
    TilawaHomeDashboardCardTokens? homeDashboardCard,
    TilawaCapabilityActionCardTokens? capabilityActionCard,
    TilawaExperimentalBadgeTokens? experimentalBadge,
    TilawaCupertinoWheelPickerTokens? cupertinoWheelPicker,
  }) {
    return MeMuslimComponentTokens(
      sectionTitle: sectionTitle ?? this.sectionTitle,
      sheetHandle: sheetHandle ?? this.sheetHandle,
      card: card ?? this.card,
      iconBox: iconBox ?? this.iconBox,
      loadingIndicator: loadingIndicator ?? this.loadingIndicator,
      divider: divider ?? this.divider,
      emptyState: emptyState ?? this.emptyState,
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
      bottomSheetScaffold: bottomSheetScaffold ?? this.bottomSheetScaffold,
      homeNextPrayerHero: homeNextPrayerHero ?? this.homeNextPrayerHero,
      homeDashboardCard: homeDashboardCard ?? this.homeDashboardCard,
      capabilityActionCard: capabilityActionCard ?? this.capabilityActionCard,
      experimentalBadge: experimentalBadge ?? this.experimentalBadge,
      cupertinoWheelPicker: cupertinoWheelPicker ?? this.cupertinoWheelPicker,
    );
  }

  @override
  MeMuslimComponentTokens lerp(
    ThemeExtension<MeMuslimComponentTokens>? other,
    double t,
  ) {
    if (other is! MeMuslimComponentTokens) return this;
    return MeMuslimComponentTokens(
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
      bottomSheetScaffold: TilawaBottomSheetScaffoldTokens.lerp(
        bottomSheetScaffold,
        other.bottomSheetScaffold,
        t,
      ),
      homeNextPrayerHero: TilawaHomeNextPrayerHeroTokens.lerp(
        homeNextPrayerHero,
        other.homeNextPrayerHero,
        t,
      ),
      homeDashboardCard: TilawaHomeDashboardCardTokens.lerp(
        homeDashboardCard,
        other.homeDashboardCard,
        t,
      ),
      capabilityActionCard: TilawaCapabilityActionCardTokens.lerp(
        capabilityActionCard,
        other.capabilityActionCard,
        t,
      ),
      experimentalBadge: TilawaExperimentalBadgeTokens.lerp(
        experimentalBadge,
        other.experimentalBadge,
        t,
      ),
      cupertinoWheelPicker: TilawaCupertinoWheelPickerTokens.lerp(
        cupertinoWheelPicker,
        other.cupertinoWheelPicker,
        t,
      ),
    );
  }
}

extension MeMuslimComponentTokensX on ThemeData {
  /// Resolves kit tokens from [ThemeExtension], or rebuilds them from
  /// [colorScheme] when a subtree uses a partial [ThemeData] that omits the
  /// extension (common with nested [Theme] wrappers). Avoids falling back to
  /// [ColorScheme.fromSeed] with [AppColors.defaultPrimary], which ignores the
  /// active user primary and refined surfaces.
  MeMuslimComponentTokens get componentTokens {
    final MeMuslimComponentTokens? ext = extension<MeMuslimComponentTokens>();
    if (ext != null) return ext;

    return colorScheme.brightness == Brightness.dark
        ? MeMuslimComponentTokens.dark(colorScheme: colorScheme)
        : MeMuslimComponentTokens.light(colorScheme: colorScheme);
  }
}

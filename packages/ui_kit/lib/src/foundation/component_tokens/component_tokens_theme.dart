import 'package:flutter/material.dart';

import 'atoms_tokens.dart';
import 'molecules_tokens.dart';
import 'organisms_tokens.dart';

@immutable
class TilawaComponentTokens extends ThemeExtension<TilawaComponentTokens> {
  const TilawaComponentTokens({
    required this.sectionTitle,
    required this.sheetHandle,
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
  });

  final TilawaSectionTitleTokens sectionTitle;
  final TilawaSheetHandleTokens sheetHandle;
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

  factory TilawaComponentTokens.light() => TilawaComponentTokens(
    sectionTitle: TilawaSectionTitleTokens.defaults(),
    sheetHandle: TilawaSheetHandleTokens.defaults(),
    alphabetScrollbar: TilawaAlphabetScrollbarTokens.defaults(),
    feedbackStrip: TilawaFeedbackStripTokens.defaults(),
    glassPanel: TilawaGlassPanelTokens.defaults(),
    iconActionButton: TilawaIconActionButtonTokens.defaults(),
    chip: TilawaChipTokens.defaults(),
    segmentedControl: TilawaSegmentedControlTokens.defaults(),
    seekBar: TilawaSeekBarTokens.defaults(),
    searchField: TilawaSearchFieldTokens.defaults(),
    countProgressRing: TilawaCountProgressRingTokens.defaults(),
    playerBackground: TilawaPlayerBackgroundTokens.defaults(),
    footerBar: TilawaFooterBarTokens.defaults(),
    mediaPlayerBar: TilawaMediaPlayerBarTokens.defaults(),
    adaptiveShell: TilawaAdaptiveShellTokens.defaults(),
    settingsGroup: TilawaSettingsGroupTokens.defaults(),
    immersiveComposer: TilawaImmersiveComposerTokens.defaults(),
  );

  factory TilawaComponentTokens.dark() => TilawaComponentTokens.light();

  @override
  TilawaComponentTokens copyWith({
    TilawaSectionTitleTokens? sectionTitle,
    TilawaSheetHandleTokens? sheetHandle,
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
  }) {
    return TilawaComponentTokens(
      sectionTitle: sectionTitle ?? this.sectionTitle,
      sheetHandle: sheetHandle ?? this.sheetHandle,
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
    );
  }

  @override
  TilawaComponentTokens lerp(
    ThemeExtension<TilawaComponentTokens>? other,
    double t,
  ) {
    if (other is! TilawaComponentTokens) return this;

    return TilawaComponentTokens(
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
    );
  }
}

extension TilawaComponentTokensX on ThemeData {
  TilawaComponentTokens get componentTokens =>
      extension<TilawaComponentTokens>() ?? TilawaComponentTokens.light();
}

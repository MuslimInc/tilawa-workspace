import 'package:flutter/material.dart';

import 'atoms_tokens.dart';
import 'molecules_tokens.dart';
import 'organisms_tokens.dart';

@immutable
class TilawaComponentTokens extends ThemeExtension<TilawaComponentTokens> {
  const TilawaComponentTokens({
    required this.sectionTitle,
    required this.sheetHandle,
    required this.feedbackStrip,
    required this.glassPanel,
    required this.iconActionButton,
    required this.searchField,
    required this.settingsGroup,
    required this.immersiveComposer,
  });

  final TilawaSectionTitleTokens sectionTitle;
  final TilawaSheetHandleTokens sheetHandle;
  final TilawaFeedbackStripTokens feedbackStrip;
  final TilawaGlassPanelTokens glassPanel;
  final TilawaIconActionButtonTokens iconActionButton;
  final TilawaSearchFieldTokens searchField;
  final TilawaSettingsGroupTokens settingsGroup;
  final TilawaImmersiveComposerTokens immersiveComposer;

  factory TilawaComponentTokens.light() => TilawaComponentTokens(
    sectionTitle: TilawaSectionTitleTokens.defaults(),
    sheetHandle: TilawaSheetHandleTokens.defaults(),
    feedbackStrip: TilawaFeedbackStripTokens.defaults(),
    glassPanel: TilawaGlassPanelTokens.defaults(),
    iconActionButton: TilawaIconActionButtonTokens.defaults(),
    searchField: TilawaSearchFieldTokens.defaults(),
    settingsGroup: TilawaSettingsGroupTokens.defaults(),
    immersiveComposer: TilawaImmersiveComposerTokens.defaults(),
  );

  factory TilawaComponentTokens.dark() => TilawaComponentTokens.light();

  @override
  TilawaComponentTokens copyWith({
    TilawaSectionTitleTokens? sectionTitle,
    TilawaSheetHandleTokens? sheetHandle,
    TilawaFeedbackStripTokens? feedbackStrip,
    TilawaGlassPanelTokens? glassPanel,
    TilawaIconActionButtonTokens? iconActionButton,
    TilawaSearchFieldTokens? searchField,
    TilawaSettingsGroupTokens? settingsGroup,
    TilawaImmersiveComposerTokens? immersiveComposer,
  }) {
    return TilawaComponentTokens(
      sectionTitle: sectionTitle ?? this.sectionTitle,
      sheetHandle: sheetHandle ?? this.sheetHandle,
      feedbackStrip: feedbackStrip ?? this.feedbackStrip,
      glassPanel: glassPanel ?? this.glassPanel,
      iconActionButton: iconActionButton ?? this.iconActionButton,
      searchField: searchField ?? this.searchField,
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
      searchField: TilawaSearchFieldTokens.lerp(
        searchField,
        other.searchField,
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
      extension<TilawaComponentTokens>()!;
}

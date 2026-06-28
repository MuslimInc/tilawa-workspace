import 'package:flutter/material.dart';
import 'package:tilawa/shared/widgets/quran_player_widget.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// FAB offset and surah-list bottom padding for [ReciterDetailsScreen].
///
/// Handles shell mini-player footer, system nav, and keyboard states.
@immutable
final class ReciterDetailsFabLayout {
  const ReciterDetailsFabLayout({
    required this.fabBottomOffset,
    required this.listBottomPadding,
    required this.showScrollToTopFab,
  });

  final double fabBottomOffset;
  final double listBottomPadding;
  final bool showScrollToTopFab;

  static ReciterDetailsFabLayout resolve(
    BuildContext context, {
    required bool scrollToTopFabVisible,
  }) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;

    if (context.isKeyboardVisible) {
      return ReciterDetailsFabLayout(
        fabBottomOffset: 0,
        listBottomPadding: tokens.spaceSmall,
        showScrollToTopFab: false,
      );
    }

    final double fabBottomOffset =
        QuranPlayerWidget.fabBottomOffset(context) + tokens.spaceLarge;
    final double fabClearance =
        fabBottomOffset + kMeMuslimMinInteractiveDimension + tokens.spaceLarge;

    final double listBottomPadding =
        QuranPlayerWidget.shellFooterShowsMiniPlayer(context)
        ? fabClearance + tokens.spaceMedium
        : fabClearance;

    return ReciterDetailsFabLayout(
      fabBottomOffset: fabBottomOffset,
      listBottomPadding: listBottomPadding,
      showScrollToTopFab: scrollToTopFabVisible,
    );
  }
}

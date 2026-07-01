import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// One phone bottom-navigation destination in [AppShellScreen].
@immutable
class AppShellNavDestination extends Equatable {
  const AppShellNavDestination({
    required this.label,
    required this.icon,
    this.activeIcon,
    this.iconBuilder,
    this.tabIndex,
    this.semanticsIdentifier,
    this.usesProfileAvatar = false,
  });

  final String label;
  final IconData icon;
  final IconData? activeIcon;

  /// Optional widget builder for non-font icons (e.g. custom SVGs).
  ///
  /// When provided, the shell uses this instead of the default [Icon]
  /// widget. The builder receives the resolved foreground [color] based on
  /// selection state.
  final Widget Function(BuildContext context, {required Color color})?
  iconBuilder;

  /// [MainTabViewport] index when this item selects a shell tab.
  ///
  /// `null` means a pushed route (Quran index) instead of a tab switch.
  final int? tabIndex;

  final String? semanticsIdentifier;

  /// When true, [AppShellScreen] renders the signed-in user's photo in the bar.
  final bool usesProfileAvatar;

  bool get isPushRoute => tabIndex == null;

  @override
  List<Object?> get props => [
    label,
    icon,
    activeIcon,
    iconBuilder,
    tabIndex,
    semanticsIdentifier,
    usesProfileAvatar,
  ];
}

/// Builds the phone shell bottom bar (Home → Quran reader → Reciters → Settings).
List<AppShellNavDestination> buildPhoneShellNavDestinations(
  AppLocalizations l10n,
) {
  return [
    AppShellNavDestination(
      tabIndex: 0,
      icon: TilawaIcons.home,
      activeIcon: TilawaIcons.homeActive,
      label: l10n.bottomNavHome,
      semanticsIdentifier: 'home_tab',
    ),
    AppShellNavDestination(
      label: l10n.bottomNavQuran,
      icon: TilawaIcons.menuBook,
      iconBuilder: (context, {required Color color}) {
        final double iconSize = Theme.of(
          context,
        ).componentTokens.adaptiveShell.navButtonIconSize;
        return TilawaIcons.quran.svg(color: color, size: iconSize);
      },
      semanticsIdentifier: 'quran_index_nav',
    ),
    AppShellNavDestination(
      tabIndex: kAppShellRecitersTabIndex,
      icon: TilawaIcons.reciters,
      activeIcon: TilawaIcons.recitersActive,
      label: l10n.bottomNavReciters,
      semanticsIdentifier: 'reciters_tab',
    ),
    AppShellNavDestination(
      tabIndex: kAppShellSettingsTabIndex,
      icon: TilawaIcons.profile,
      activeIcon: TilawaIcons.profileActive,
      label: l10n.bottomNavSettings,
      semanticsIdentifier: 'settings_tab',
      usesProfileAvatar: true,
    ),
  ];
}

/// Reciters main-tab index in [MainTabViewport].
const int kAppShellRecitersTabIndex = 1;

/// Settings shell tab (index 2), shown on the phone bottom bar as profile.
const int kAppShellSettingsTabIndex = 2;

/// Tab indices that appear on the phone bottom bar (excluding push-only Quran).
const Set<int> kPhoneShellNavTabIndices = {0, 1, 2};

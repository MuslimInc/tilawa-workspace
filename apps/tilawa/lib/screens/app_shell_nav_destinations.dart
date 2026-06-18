import 'package:equatable/equatable.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

/// One phone bottom-navigation destination in [AppShellScreen].
@immutable
class AppShellNavDestination extends Equatable {
  const AppShellNavDestination({
    required this.label,
    required this.icon,
    this.activeIcon,
    this.svgPath,
    this.tabIndex,
    this.semanticsIdentifier,
  });

  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final String? svgPath;

  /// [MainTabViewport] index when this item selects a shell tab.
  ///
  /// `null` means a pushed route (Quran index) instead of a tab switch.
  final int? tabIndex;

  final String? semanticsIdentifier;

  bool get isPushRoute => tabIndex == null;

  @override
  List<Object?> get props => [
    label,
    icon,
    activeIcon,
    svgPath,
    tabIndex,
    semanticsIdentifier,
  ];
}

/// Builds the four visible phone shell nav items (Behance lifestyle IA).
///
/// Order: Home → Quran (index push) → Qibla → Athkar.
/// Reciters (viewport index 1) and Settings (index 4) are reached from Home.
List<AppShellNavDestination> buildPhoneShellNavDestinations(
  AppLocalizations l10n,
) {
  return [
    AppShellNavDestination(
      tabIndex: 0,
      icon: FluentIcons.home_24_regular,
      activeIcon: FluentIcons.home_24_filled,
      label: l10n.bottomNavHome,
      semanticsIdentifier: 'home_tab',
    ),
    AppShellNavDestination(
      label: l10n.bottomNavQuran,
      icon: Icons.menu_book_rounded,
      semanticsIdentifier: 'quran_index_nav',
    ),
    AppShellNavDestination(
      tabIndex: 2,
      icon: FluentIcons.compass_northwest_24_regular,
      activeIcon: FluentIcons.compass_northwest_24_filled,
      label: l10n.bottomNavQibla,
      semanticsIdentifier: 'qibla_tab',
    ),
    AppShellNavDestination(
      tabIndex: 3,
      icon: FluentIcons.book_open_24_regular,
      activeIcon: FluentIcons.book_open_24_filled,
      svgPath: 'assets/icons/athkar_icon.svg',
      label: l10n.bottomNavAthkar,
      semanticsIdentifier: 'athkar_tab',
    ),
  ];
}

/// Viewport tab indices not exposed on the phone bottom bar.
const int kAppShellRecitersTabIndex = 1;

/// Settings remains a shell tab (index 4) but is not on the phone bottom bar.
const int kAppShellSettingsTabIndex = 4;

/// Tab indices that appear on the phone bottom bar (excluding push-only Quran).
const Set<int> kPhoneShellNavTabIndices = {0, 2, 3};

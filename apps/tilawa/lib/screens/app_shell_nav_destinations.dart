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
  /// `null` means a pushed route (Quran last-read) instead of a tab switch.
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

/// Builds the five visible phone shell nav items.
///
/// Reciters (viewport index 1) is intentionally omitted — reach it from Home
/// More or programmatic tab selection.
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
      tabIndex: 2,
      icon: FluentIcons.clock_24_regular,
      activeIcon: FluentIcons.clock_24_filled,
      label: l10n.bottomNavPrayer,
      semanticsIdentifier: 'prayer_times_tab',
    ),
    AppShellNavDestination(
      label: l10n.bottomNavQuran,
      icon: Icons.menu_book_rounded,
      semanticsIdentifier: 'quran_last_read_nav',
    ),
    AppShellNavDestination(
      tabIndex: 3,
      icon: FluentIcons.book_open_24_regular,
      activeIcon: FluentIcons.book_open_24_filled,
      svgPath: 'assets/icons/athkar_icon.svg',
      label: l10n.bottomNavAthkar,
      semanticsIdentifier: 'athkar_tab',
    ),
    AppShellNavDestination(
      tabIndex: 4,
      icon: FluentIcons.settings_24_regular,
      activeIcon: FluentIcons.settings_24_filled,
      label: l10n.bottomNavSettings,
      semanticsIdentifier: 'settings_tab',
    ),
  ];
}

/// Viewport tab indices not exposed on the phone bottom bar.
const int kAppShellRecitersTabIndex = 1;

/// Tab indices that appear on the phone bottom bar (excluding push-only Quran).
const Set<int> kPhoneShellNavTabIndices = {0, 2, 3, 4};

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/domain/entities/home_prayer_slot.dart';
import 'package:tilawa/features/home/presentation/widgets/home_feature_pastel.dart';
import 'package:tilawa/features/home/presentation/widgets/home_hero_background.dart';
import 'package:tilawa/features/home/presentation/widgets/home_prayer_schedule_strip.dart';
import 'package:tilawa/features/home/presentation/widgets/home_primary_action_tile.dart';
import 'package:tilawa/features/home/presentation/widgets/home_quick_tools_section.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/shared/widgets/profile_avatar.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Lightweight, non-interactive Home miniature for onboarding device chrome.
///
/// Mirrors the real Home stack (hero → primary actions → quick tools → shell
/// nav) with static mock data. No cubits, routes, permissions, or timers.
class OnboardingHomePreview extends StatelessWidget {
  const OnboardingHomePreview({super.key});

  /// Logical canvas width the preview is authored against before fit-scale.
  static const double designWidth = 320;

  /// Matches phone-frame 9∶20 canvas.
  static const double designHeight = designWidth * 20 / 9;

  /// Mock profile name — preview-only, not live auth.
  static const String _mockDisplayName = 'Ahmad';

  /// Mock location chip — preview-only, not GPS.
  static const String _mockLocation = 'Madinah';

  /// Fixed clock for the next-prayer hero (matches onboarding mock).
  static final DateTime _mockFajrTime = DateTime(2026, 1, 1, 4, 7);

  static void _noop() {}

  @override
  Widget build(BuildContext context) {
    return const AbsorbPointer(
      child: FittedBox(
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: designWidth,
          height: designHeight,
          child: _OnboardingHomePreviewBody(),
        ),
      ),
    );
  }
}

class _OnboardingHomePreviewBody extends StatelessWidget {
  const _OnboardingHomePreviewBody();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme scheme = theme.colorScheme;
    final TilawaHomeScreenTokens screenTokens =
        theme.componentTokens.homeScreen;
    final TilawaHomeNextPrayerHeroTokens heroTokens =
        TilawaHomeNextPrayerHeroTokens.day();
    final MeMuslimProductColors product = theme.productColors;
    final Color onHero = heroTokens.foregroundColor;
    final Color muted = onHero.withValues(
      alpha: heroTokens.mutedForegroundOpacity,
    );
    final Color quranAccent = HomeFeaturePastel.accentFor(
      HomeExploreFeature.quran,
      product,
    );
    final Color athkarAccent = HomeFeaturePastel.accentFor(
      HomeExploreFeature.athkar,
      product,
    );
    final double iconSize = tokens.iconSizeLarge;
    final List<HomePrayerSlot> mockSlots = _mockPrayerSlots();

    return ColoredBox(
      color: screenTokens.backgroundGradientEnd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _PreviewHero(
            heroTokens: heroTokens,
            screenTokens: screenTokens,
            onHero: onHero,
            muted: muted,
            slots: mockSlots,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.spaceLarge,
                tokens.spaceLarge,
                tokens.spaceLarge,
                tokens.spaceSmall,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: tokens.spaceExtraLarge,
                children: <Widget>[
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: tokens.spaceLarge,
                      children: <Widget>[
                        Expanded(
                          child: HomePrimaryActionTile(
                            accent: quranAccent,
                            surfaceColor: HomeFeaturePastel.ceremonialWash(
                              accent: quranAccent,
                              colorScheme: scheme,
                            ),
                            icon: TilawaIcons.quran.svg(
                              size: iconSize,
                              color: quranAccent,
                            ),
                            label: context.l10n.homeQuickQuranReader,
                            subtitle: context.l10n.homeQuickQuranReaderSubtitle,
                            onTap: OnboardingHomePreview._noop,
                          ),
                        ),
                        Expanded(
                          child: HomePrimaryActionTile(
                            accent: athkarAccent,
                            surfaceColor: HomeFeaturePastel.ceremonialWash(
                              accent: athkarAccent,
                              colorScheme: scheme,
                            ),
                            icon: Icon(
                              TilawaIcons.athkar,
                              size: iconSize,
                              color: athkarAccent,
                            ),
                            label: context.l10n.athkar,
                            subtitle: context.l10n.homeDailyHabitSubtitle,
                            onTap: OnboardingHomePreview._noop,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Reuse the real quick-tools section; AbsorbPointer blocks
                  // its route pushes.
                  const HomeQuickToolsSection(),
                  const Spacer(),
                ],
              ),
            ),
          ),
          const _PreviewShellNav(),
        ],
      ),
    );
  }

  List<HomePrayerSlot> _mockPrayerSlots() {
    final DateTime day = OnboardingHomePreview._mockFajrTime;
    return <HomePrayerSlot>[
      HomePrayerSlot(
        type: PrayerType.fajr,
        time: day,
        isNext: true,
        hasPassed: false,
      ),
      HomePrayerSlot(
        type: PrayerType.dhuhr,
        time: day.add(const Duration(hours: 8)),
        isNext: false,
        hasPassed: false,
      ),
      HomePrayerSlot(
        type: PrayerType.asr,
        time: day.add(const Duration(hours: 11)),
        isNext: false,
        hasPassed: false,
      ),
      HomePrayerSlot(
        type: PrayerType.maghrib,
        time: day.add(const Duration(hours: 14)),
        isNext: false,
        hasPassed: false,
      ),
      HomePrayerSlot(
        type: PrayerType.isha,
        time: day.add(const Duration(hours: 16)),
        isNext: false,
        hasPassed: false,
      ),
    ];
  }
}

class _PreviewHero extends StatelessWidget {
  const _PreviewHero({
    required this.heroTokens,
    required this.screenTokens,
    required this.onHero,
    required this.muted,
    required this.slots,
  });

  final TilawaHomeNextPrayerHeroTokens heroTokens;
  final TilawaHomeScreenTokens screenTokens;
  final Color onHero;
  final Color muted;
  final List<HomePrayerSlot> slots;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    const String mockName = OnboardingHomePreview._mockDisplayName;
    final String clock =
        '${OnboardingHomePreview._mockFajrTime.hour.toString().padLeft(2, '0')}'
        ':${OnboardingHomePreview._mockFajrTime.minute.toString().padLeft(2, '0')}';

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: HomeHeroBackground(
            heroTokens: heroTokens,
            screenTokens: screenTokens,
            showDecorativeLayers: true,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceLarge,
            tokens.spaceLarge,
            tokens.spaceLarge,
            tokens.spaceMedium,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: tokens.spaceExtraSmall,
                      children: <Widget>[
                        Text(
                          context.l10n.homeGreeting,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: onHero,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            height: 1.25,
                          ),
                        ),
                        Text(
                          mockName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: onHero.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: onHero.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: ProfileAvatar(
                      displayName: mockName,
                      size: tokens.minInteractiveDimension * 0.72,
                      backgroundColor: onHero.withValues(alpha: 0.14),
                      foregroundColor: onHero,
                      fallbackStyle: ProfileAvatarFallbackStyle.initial,
                    ),
                  ),
                ],
              ),
              SizedBox(height: tokens.spaceMedium),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      context.l10n.nextPrayer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: muted,
                        fontWeight: FontWeight.w400,
                        fontSize: 10,
                        height: 1.2,
                      ),
                    ),
                  ),
                  Icon(
                    FluentIcons.location_24_filled,
                    size: 11,
                    color: muted,
                  ),
                  SizedBox(width: tokens.spaceExtraSmall),
                  Text(
                    OnboardingHomePreview._mockLocation,
                    maxLines: 1,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: onHero.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              SizedBox(height: tokens.spaceSmall),
              Text(
                context.l10n.fajr.toUpperCase(),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: muted,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
              Text(
                clock,
                textAlign: TextAlign.center,
                style: theme.textTheme.displayMedium?.copyWith(
                  color: onHero,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                  fontSize: 36,
                  height: 1.15,
                  letterSpacing: 0,
                ),
              ),
              Text(
                context.l10n.homeNextPrayerCountdownHoursMinutes(3, 33),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: muted,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
              SizedBox(height: tokens.spaceMedium),
              HomePrayerScheduleStrip(
                slots: slots,
                onOpenPrayer: OnboardingHomePreview._noop,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewShellNav extends StatelessWidget {
  const _PreviewShellNav();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final TilawaAdaptiveShellTokens shell = theme.componentTokens.adaptiveShell;
    final ColorScheme scheme = theme.colorScheme;
    final Color active = scheme.primary;
    final Color inactive = scheme.onSurfaceVariant;
    final double iconSize = shell.navButtonIconSize * 0.85;

    Widget item({
      required String label,
      required Widget icon,
      required bool selected,
    }) {
      final Color color = selected ? active : inactive;
      return Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: <Widget>[
            IconTheme(
              data: IconThemeData(size: iconSize, color: color),
              child: icon,
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 8,
                height: 1.1,
              ),
            ),
          ],
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: shell.bottomNavBackgroundColor,
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withValues(
              alpha: tokens.opacitySubtle,
            ),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: tokens.spaceExtraSmall,
          horizontal: tokens.spaceExtraSmall,
        ),
        child: Row(
          children: <Widget>[
            item(
              label: context.l10n.bottomNavHome,
              selected: true,
              icon: Icon(TilawaIcons.homeActive, color: active),
            ),
            item(
              label: context.l10n.bottomNavQuran,
              selected: false,
              icon: TilawaIcons.quranNav.svg(color: inactive, size: iconSize),
            ),
            item(
              label: context.l10n.bottomNavReciters,
              selected: false,
              icon: TilawaIcons.qari.svg(color: inactive, size: iconSize),
            ),
            item(
              label: context.l10n.bottomNavSettings,
              selected: false,
              icon: Icon(TilawaIcons.settings, color: inactive),
            ),
          ],
        ),
      ),
    );
  }
}

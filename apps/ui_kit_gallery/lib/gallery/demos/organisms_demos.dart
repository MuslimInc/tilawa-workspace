import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'demo_helpers.dart';

/// Organism-layer component demos.
abstract final class OrganismsDemos {
  static Widget adaptiveShell(BuildContext context) {
    return _AdaptiveShellDemo();
  }

  static Widget backdropImageLayer(BuildContext context) {
    return const GalleryDemoFrame(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 320,
        width: double.infinity,
        child: TilawaBackdropImageLayer(
          image: NetworkImage('https://picsum.photos/800/1200'),
          blurAmount: 12,
          overlayOpacity: 0.4,
        ),
      ),
    );
  }

  static Widget bottomSheetScaffold(BuildContext context) {
    return GalleryDemoFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TilawaButton(
            text: 'Open modal sheet',
            onPressed: () => _openSheet(context),
          ),
          const SizedBox(height: 24),
          const Text(
            'Inline preview',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const TilawaBottomSheetScaffold(
              topBar: Text('Sheet title'),
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Sheet body content'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget immersiveComposer(BuildContext context) {
    return SizedBox(
      height: 520,
      child: ImmersiveComposerScaffold(
        title: 'Compose',
        subtitle: 'Draft a new ayah image',
        preview: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.indigo, Colors.purple],
            ),
          ),
          child: const Center(
            child: Text(
              'Preview canvas',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
        ),
        bottomPanel: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.text_fields),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.color_lens),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.share)),
            ],
          ),
        ),
        onClose: () {},
      ),
    );
  }

  static Widget mediaPlayerBar(BuildContext context) {
    return GalleryDemoFrame(
      child: Column(
        children: [
          TilawaMediaPlayerBar(
            layoutWidth: 420,
            title: 'Surah Al-Fatiha',
            subtitle: 'Abdul Basit',
            progress: 0.5,
            isPlaying: true,
            canGoPrevious: true,
            canGoNext: true,
            onPlayPause: () {},
            onPrevious: () {},
            onNext: () {},
            onTap: () {},
          ),
          const SizedBox(height: 16),
          TilawaMediaPlayerBar(
            layoutWidth: 360,
            title: 'Surah Al-Fatiha',
            subtitle: 'Abdul Basit',
            progress: 0.35,
            isPlaying: true,
            canGoPrevious: true,
            canGoNext: true,
            isSleepTimerEnabled: true,
            onPlayPause: () {},
            onNext: () {},
            onTap: () {},
          ),
        ],
      ),
    );
  }

  static Widget settingsGroup(BuildContext context) {
    return GalleryDemoFrame(
      child: TilawaSettingsGroup(
        title: 'Preferences',
        children: [
          TilawaSettingsTile(
            icon: Icons.language,
            title: 'Language',
            onTap: () {},
          ),
          TilawaSettingsSwitchTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark mode',
            value: false,
            onChanged: (_) {},
          ),
          TilawaSettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () {},
            showDivider: false,
          ),
        ],
      ),
    );
  }

  static Widget shareFooterBar(BuildContext context) {
    return GalleryDemoFrame(
      child: SizedBox(
        width: 360,
        child: TilawaShareFooterBar(
          primaryLabel: 'Surah Al-Fatiha',
          secondaryLabel: 'Ayah 1',
        ),
      ),
    );
  }

  static Widget asyncContent(BuildContext context) {
    return const _AsyncContentDemo();
  }

  static Widget heroSummaryCard(BuildContext context) {
    return GalleryDemoFrame(
      padding: EdgeInsets.zero,
      child: TilawaHeroSummaryCard(
        label: 'Pages read this week',
        metric: '42',
        badges: const [
          TilawaHeroSummaryBadge(label: 'On track'),
        ],
        footer: const TilawaHeroSummaryProgress(
          progress: 0.72,
          label: 'Weekly goal',
          valueLabel: '72%',
        ),
      ),
    );
  }

  static Widget behanceFeaturedCard(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaHomeDashboardCardTokens cardTokens =
        theme.componentTokens.homeDashboardCard;
    final TilawaDesignTokens tokens = theme.tokens;
    final double radius = tokens.resolveRadius(family: TilawaRadiusFamily.hero);

    return GalleryDemoFrame(
      child: TilawaCard(
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        borderRadius: radius,
        borderWidth: 0,
        surface: TilawaCardSurface.raised,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                cardTokens.gradientStart,
                cardTokens.gradientEnd,
              ],
            ),
          ),
          child: Padding(
            padding: theme.componentTokens.card.padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Last Read',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cardTokens.foregroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: tokens.spaceSmall),
                Text(
                  'Surah Al-Baqarah',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: cardTokens.foregroundColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget travelDashboardSheet(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TilawaDesignTokens tokens = theme.tokens;
    final TilawaHomeNextPrayerHeroTokens heroTokens =
        theme.componentTokens.homeNextPrayerHero;
    final TilawaHomeDashboardCardTokens dashboardTokens =
        theme.componentTokens.homeDashboardCard;
    const double sheetOverlap = 16;

    return GalleryDemoFrame(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        child: SizedBox(
          height: 280,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        heroTokens.gradientTopStart,
                        heroTokens.gradientBottomEnd,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(tokens.spaceLarge),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        'Hero gradient',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: heroTokens.foregroundColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                top: 120,
                child: Transform.translate(
                  offset: const Offset(0, -sheetOverlap),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: dashboardTokens.travelSheetSurface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(tokens.radiusExtraLarge),
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: colorScheme.shadow.withValues(
                            alpha: tokens.opacityShadow,
                          ),
                          blurRadius: tokens.blurShadow,
                          offset: Offset(
                            0,
                            tokens.shadowOffsetMedium.dy * -0.5,
                          ),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(tokens.spaceLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: tokens.spaceMedium,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: dashboardTokens.travelSearchFieldFill,
                              borderRadius: BorderRadius.circular(
                                tokens.radiusExtraLarge,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: tokens.spaceMedium,
                                vertical: tokens.spaceSmall,
                              ),
                              child: Text(
                                'Search surahs, juz, or page',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: dashboardTokens.destinationHeaderTint(0),
                              borderRadius: BorderRadius.circular(
                                tokens.radiusLarge,
                              ),
                            ),
                            child: SizedBox(
                              height: tokens.spaceExtraLarge * 2,
                              child: Center(
                                child: Icon(
                                  Icons.explore_outlined,
                                  color: dashboardTokens
                                      .travelDestinationIconColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget behanceInstructionChip(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TilawaDesignTokens tokens = theme.tokens;

    return GalleryDemoFrame(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(tokens.radiusLarge),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: tokens.opacitySubtle),
            width: tokens.borderWidthThin,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceLarge,
            vertical: tokens.spaceMedium,
          ),
          child: Text(
            'Rotate the phone 44° to the left',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _openSheet(BuildContext context) {
    return showTilawaModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: TilawaBottomSheetScaffold.modalShape(context),
      builder: (sheetContext) {
        return TilawaBottomSheetScaffold(
          topBar: Text(
            'Modal sheet',
            style: Theme.of(sheetContext).textTheme.titleMedium,
          ),
          children: const [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text('Drag the handle down to dismiss.'),
            ),
          ],
        );
      },
    );
  }
}

class _AsyncContentDemo extends StatefulWidget {
  const _AsyncContentDemo();

  @override
  State<_AsyncContentDemo> createState() => _AsyncContentDemoState();
}

class _AsyncContentDemoState extends State<_AsyncContentDemo> {
  TilawaAsyncContentState _state = TilawaAsyncContentState.loading;
  var _isRetrying = false;

  @override
  Widget build(BuildContext context) {
    return GalleryDemoFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<TilawaAsyncContentState>(
            segments: const [
              ButtonSegment(
                value: TilawaAsyncContentState.loading,
                label: Text('Loading'),
              ),
              ButtonSegment(
                value: TilawaAsyncContentState.empty,
                label: Text('Empty'),
              ),
              ButtonSegment(
                value: TilawaAsyncContentState.error,
                label: Text('Error'),
              ),
              ButtonSegment(
                value: TilawaAsyncContentState.content,
                label: Text('Content'),
              ),
            ],
            selected: {_state},
            onSelectionChanged: (selection) {
              setState(() {
                _state = selection.first;
                _isRetrying = false;
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TilawaAsyncContent(
              state: _state,
              skeleton: const _AsyncContentSkeleton(),
              onRetry: _state == TilawaAsyncContentState.error
                  ? () {
                      setState(() => _isRetrying = true);
                      Future<void>.delayed(const Duration(seconds: 1), () {
                        if (mounted) {
                          setState(() {
                            _isRetrying = false;
                            _state = TilawaAsyncContentState.content;
                          });
                        }
                      });
                    }
                  : null,
              isRetrying: _isRetrying,
              builder: (context) => const _AsyncContentLoaded(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AsyncContentSkeleton extends StatelessWidget {
  const _AsyncContentSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Skeleton placeholder'));
  }
}

class _AsyncContentLoaded extends StatelessWidget {
  const _AsyncContentLoaded();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Loaded content'));
  }
}

class _AdaptiveShellDemo extends StatefulWidget {
  @override
  State<_AdaptiveShellDemo> createState() => _AdaptiveShellDemoState();
}

class _AdaptiveShellDemoState extends State<_AdaptiveShellDemo> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 520,
      child: TilawaAdaptiveShell(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          TilawaNavDestination(
            label: 'Home',
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
          ),
          TilawaNavDestination(
            label: 'Quran',
            icon: Icons.menu_book_outlined,
            activeIcon: Icons.menu_book_rounded,
          ),
          TilawaNavDestination(
            label: 'Qibla',
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore_rounded,
          ),
          TilawaNavDestination(
            label: 'Athkar',
            icon: Icons.auto_stories_outlined,
            activeIcon: Icons.auto_stories_rounded,
          ),
        ],
        bottomPlayer: const SizedBox.shrink(),
        child: Center(
          child: Text('Tab ${_index + 1}'),
        ),
      ),
    );
  }
}

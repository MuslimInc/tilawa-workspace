import 'dart:async';
import 'dart:ui';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/home_dashboard.dart';
import '../../domain/entities/home_prayer_slot.dart';
import '../bloc/home_dashboard_bloc.dart';
import '../bloc/home_dashboard_state.dart';

/// Stacked-deck prayer card carousel.
///
/// Visual model (matches the travel-app Dribbble reference):
///   • The front card is centered at full size.
///   • One card peeks from behind on the RIGHT — shifted right + scaled down +
///     moved slightly downward, giving a physical-deck depth illusion.
///   • Swiping LEFT reveals the next card; swiping RIGHT reveals the previous.
///   • No horizontal padding bleed needed — the peek card sits within the
///     same column, partially hidden behind the front card.
class HomePrayerCarousel extends StatefulWidget {
  const HomePrayerCarousel({super.key, required this.onOpenPrayer});

  final VoidCallback onOpenPrayer;

  static const double photoHeight = 268.0;
  static const double barHeight = 52.0;
  static const double cardHeight = photoHeight + barHeight;

  /// Peek card shifts this many logical pixels to the right of center.
  static const double peekShiftX = 28.0;

  /// Peek card shifts this many logical pixels down from the front card top.
  static const double peekShiftY = 10.0;

  /// Peek card is scaled to this fraction of the front card.
  static const double peekScale = 0.93;

  /// Peek card alpha (0–1).
  static const double peekOpacity = 0.72;

  @override
  State<HomePrayerCarousel> createState() => _HomePrayerCarouselState();
}

class _HomePrayerCarouselState extends State<HomePrayerCarousel>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  bool _hasInitialized = false;

  // Drag + snap
  double _drag = 0;
  late AnimationController _snapCtrl;
  late Animation<double> _snapAnim;

  @override
  void initState() {
    super.initState();
    _snapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _snapAnim = const AlwaysStoppedAnimation(0);
  }

  @override
  void dispose() {
    _snapCtrl.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _snapCtrl.stop();
    setState(() => _drag += d.delta.dx);
  }

  void _onDragEnd(DragEndDetails d, int count) {
    const double threshold = 50;
    final double velocity = d.primaryVelocity ?? 0;
    final bool toNext =
        (_drag < -threshold || velocity < -500) && _index < count - 1;
    final bool toPrev = (_drag > threshold || velocity > 500) && _index > 0;

    if (toNext || toPrev) {
      setState(() {
        _index += toNext ? 1 : -1;
        _drag = 0;
      });
      _snapCtrl.forward(from: 0);
    } else {
      // Snap back to rest
      final double from = _drag;
      _snapAnim = Tween<double>(begin: from, end: 0).animate(
        CurvedAnimation(parent: _snapCtrl, curve: Curves.easeOutCubic),
      );
      _snapCtrl.forward(from: 0).then((_) => setState(() => _drag = 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeDashboardBloc, HomeDashboardState>(
      buildWhen: (p, n) {
        if (p.runtimeType != n.runtimeType) return true;
        if (p is HomeDashboardLoaded && n is HomeDashboardLoaded) {
          return p.dashboard.todayPrayers != n.dashboard.todayPrayers;
        }
        return false;
      },
      builder: (context, state) => switch (state) {
        HomeDashboardLoaded(:final HomeDashboard dashboard)
            when dashboard.todayPrayers.isNotEmpty =>
          _buildDeck(context, dashboard.todayPrayers),
        HomeDashboardLoading() ||
        HomeDashboardInitial() => _buildSkeleton(context),
        _ => const SizedBox.shrink(),
      },
    );
  }

  Widget _buildDeck(BuildContext context, List<HomePrayerSlot> prayers) {
    if (!_hasInitialized) {
      _hasInitialized = true;
      final int next = prayers.indexWhere((s) => s.isNext);
      if (next >= 0) _index = next;
    }

    final int count = prayers.length;

    // Extra height to accommodate the downward peek shift so nothing clips.
    final double containerHeight =
        HomePrayerCarousel.cardHeight + HomePrayerCarousel.peekShiftY;

    return SizedBox(
      height: containerHeight,
      child: AnimatedBuilder(
        animation: _snapCtrl,
        builder: (context, _) {
          final double drag = _snapCtrl.isAnimating ? _snapAnim.value : _drag;

          return GestureDetector(
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: (d) => _onDragEnd(d, count),
            // Transparent fill so GestureDetector catches taps anywhere.
            behavior: HitTestBehavior.opaque,
            child: _DeckStack(
              prayers: prayers,
              activeIndex: _index,
              drag: drag,
              onTap: widget.onOpenPrayer,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return SizedBox(
      height: HomePrayerCarousel.cardHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: const Center(child: TilawaLoadingIndicator()),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stack that composes back + front card with correct depth ordering
// ─────────────────────────────────────────────────────────────────────────────

class _DeckStack extends StatelessWidget {
  const _DeckStack({
    required this.prayers,
    required this.activeIndex,
    required this.drag,
    required this.onTap,
  });

  final List<HomePrayerSlot> prayers;
  final int activeIndex;
  final double drag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final int count = prayers.length;
    final bool hasNext = activeIndex < count - 1;
    final bool hasPrev = activeIndex > 0;

    // Dragging left (negative drag) → next card comes in from right.
    // Dragging right (positive drag) → prev card comes in from left.
    final double dragT = (-drag / 280).clamp(-1.0, 1.0);

    // Which "peek" card to show behind the active card:
    // At rest and when dragging left  → show next (right side).
    // When dragging right             → show prev (left side).
    final bool showingPrev = drag > 10 && hasPrev;
    final int peekIndex = showingPrev
        ? activeIndex - 1
        : (hasNext ? activeIndex + 1 : -1);

    // Progress for the peek card animation: 0 = at-rest peek, 1 = fully centered.
    final double peekProgress = showingPrev
        ? (-dragT).clamp(0.0, 1.0) // dragging right
        : dragT.clamp(0.0, 1.0); // dragging left

    // Peek card resting offsets (right side by default, mirrored for prev).
    final double restX = showingPrev
        ? -HomePrayerCarousel.peekShiftX
        : HomePrayerCarousel.peekShiftX;

    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.hardEdge,
      children: [
        // ── Peek (back) card ─────────────────────────────────────────────
        if (peekIndex >= 0)
          Positioned(
            top: _lerp(HomePrayerCarousel.peekShiftY, 0, peekProgress),
            left: 0,
            right: 0,
            child: Transform.translate(
              offset: Offset(_lerp(restX, 0, peekProgress), 0),
              child: Transform.scale(
                scale: _lerp(HomePrayerCarousel.peekScale, 1.0, peekProgress),
                alignment: showingPrev
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Opacity(
                  opacity: _lerp(
                    HomePrayerCarousel.peekOpacity,
                    1.0,
                    peekProgress,
                  ),
                  child: SizedBox(
                    height: HomePrayerCarousel.cardHeight,
                    child: _PrayerCard(
                      slot: prayers[peekIndex],
                      onTap: onTap,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // ── Active (front) card ───────────────────────────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Transform.translate(
            offset: Offset(drag.clamp(-320.0, 320.0), 0),
            child: SizedBox(
              height: HomePrayerCarousel.cardHeight,
              child: _PrayerCard(
                slot: prayers[activeIndex],
                onTap: onTap,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual prayer card
// ─────────────────────────────────────────────────────────────────────────────

class _PrayerCard extends StatefulWidget {
  const _PrayerCard({required this.slot, required this.onTap});

  final HomePrayerSlot slot;
  final VoidCallback onTap;

  @override
  State<_PrayerCard> createState() => _PrayerCardState();
}

class _PrayerCardState extends State<_PrayerCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    if (widget.slot.isNext) _startTicker();
  }

  @override
  void didUpdateWidget(covariant _PrayerCard old) {
    super.didUpdateWidget(old);
    if (old.slot.isNext != widget.slot.isNext ||
        old.slot.time != widget.slot.time) {
      _ticker?.cancel();
      if (widget.slot.isNext) _startTicker();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    final Duration rem = _remaining;
    if (rem <= Duration.zero) return;
    final Duration interval = rem < const Duration(hours: 1)
        ? const Duration(seconds: 1)
        : const Duration(minutes: 1);
    _ticker = Timer.periodic(interval, (_) {
      if (!mounted) return;
      if (_remaining <= Duration.zero) _ticker?.cancel();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Duration get _remaining {
    final d = widget.slot.time.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final _CardPalette palette = _paletteFor(widget.slot.type);
    final bool hasPassed = widget.slot.hasPassed;

    return Semantics(
      button: true,
      label:
          '${_prayerLabel(context, widget.slot.type)}, '
          '${_fmtTime(context, widget.slot.time)}',
      child: GestureDetector(
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Photo / gradient zone ─────────────────────────────────
              Opacity(
                opacity: hasPassed ? 0.55 : 1.0,
                child: SizedBox(
                  height: HomePrayerCarousel.photoHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background gradient
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [palette.topLeft, palette.bottomRight],
                          ),
                        ),
                      ),
                      // Bottom scrim for text legibility
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 140,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Color(0x99000000),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Content: badge top-start, name+time bottom-start
                      Padding(
                        padding: EdgeInsets.all(tokens.spaceMedium),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Badge
                            if (widget.slot.isNext)
                              _CountdownBadge(remaining: _remaining)
                            else if (hasPassed)
                              _PassedBadge()
                            else
                              const SizedBox.shrink(),
                            // Prayer name + time
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _prayerLabel(context, widget.slot.type),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w600,
                                    shadows: _kShadow,
                                  ),
                                ),
                                Text(
                                  _fmtTime(context, widget.slot.time),
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    height: 1.05,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                    shadows: _kShadow,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Action bar ───────────────────────────────────────────
              _ActionBar(onTap: widget.onTap),
            ],
          ),
        ),
      ),
    );
  }
}

const List<Shadow> _kShadow = [
  Shadow(color: Color(0x55000000), blurRadius: 10, offset: Offset(0, 2)),
];

// ─────────────────────────────────────────────────────────────────────────────
// Action bar (frosted dark strip)
// ─────────────────────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    const double circleSize = 36.0;

    return SizedBox(
      height: HomePrayerCarousel.barHeight,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: ColoredBox(
            color: const Color(0xD41C1C1E),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceMedium),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.homePrayerTimesAction,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: circleSize,
                    height: circleSize,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        FluentIcons.arrow_right_24_filled,
                        size: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badges
// ─────────────────────────────────────────────────────────────────────────────

class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({required this.remaining});

  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final double r = tokens.resolveRadius(family: TilawaRadiusFamily.pill);
    final String label = remaining <= Duration.zero
        ? context.l10n.homePrayerNow
        : _fmtCountdown(context, remaining);

    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceSmall,
            vertical: tokens.spaceExtraSmall,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.30),
              width: tokens.borderWidthThin,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: tokens.spaceExtraSmall,
            children: [
              Icon(
                FluentIcons.timer_24_regular,
                size: tokens.iconSizeSmall,
                color: Colors.white,
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PassedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: EdgeInsets.all(tokens.spaceExtraSmall),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        shape: BoxShape.circle,
      ),
      child: Icon(
        FluentIcons.checkmark_circle_24_regular,
        size: tokens.iconSizeSmall,
        color: Colors.white.withValues(alpha: 0.72),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Per-prayer color palette
// ─────────────────────────────────────────────────────────────────────────────

final class _CardPalette {
  const _CardPalette({required this.topLeft, required this.bottomRight});
  final Color topLeft;
  final Color bottomRight;
}

_CardPalette _paletteFor(PrayerType type) => switch (type) {
  PrayerType.fajr => const _CardPalette(
    topLeft: Color(0xFF0F1133),
    bottomRight: Color(0xFF2A2F7A),
  ),
  PrayerType.sunrise => const _CardPalette(
    topLeft: Color(0xFFB84C18),
    bottomRight: Color(0xFFF5A623),
  ),
  PrayerType.dhuhr => const _CardPalette(
    topLeft: Color(0xFF145E8A),
    bottomRight: Color(0xFF2F9DC8),
  ),
  PrayerType.asr => const _CardPalette(
    topLeft: Color(0xFF145238),
    bottomRight: Color(0xFF1E8B5E),
  ),
  PrayerType.maghrib => const _CardPalette(
    topLeft: Color(0xFF7A1F00),
    bottomRight: Color(0xFFCC4A08),
  ),
  PrayerType.isha => const _CardPalette(
    topLeft: Color(0xFF080E1C),
    bottomRight: Color(0xFF14243A),
  ),
  PrayerType.midnight || PrayerType.lastThird => const _CardPalette(
    topLeft: Color(0xFF060A12),
    bottomRight: Color(0xFF101828),
  ),
};

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _prayerLabel(BuildContext context, PrayerType type) => switch (type) {
  PrayerType.fajr => context.l10n.fajr,
  PrayerType.sunrise => context.l10n.sunrise,
  PrayerType.dhuhr => context.l10n.dhuhr,
  PrayerType.asr => context.l10n.asr,
  PrayerType.maghrib => context.l10n.maghrib,
  PrayerType.isha => context.l10n.isha,
  PrayerType.midnight => context.l10n.midnight,
  PrayerType.lastThird => context.l10n.lastThird,
};

String _fmtTime(BuildContext context, DateTime time) =>
    MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(time));

String _fmtCountdown(BuildContext context, Duration d) {
  if (d.inMinutes < 1) return context.l10n.homePrayerNow;
  final int h = d.inMinutes ~/ 60;
  final int m = d.inMinutes % 60;
  if (h == 0) return context.l10n.homePrayerInMinutes(m);
  return context.l10n.homePrayerInHoursMinutes(h, m);
}

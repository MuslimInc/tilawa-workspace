import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/features/audio_player/presentation/quran_player_semantics_ids.dart';
import 'package:tilawa/shared/widgets/quran_player_debug_log.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Stable [Hero] tags for the Quran player shared-element flights.
abstract final class QuranPlayerHeroTags {
  static String artwork(String audioId) => 'quran_player_artwork_$audioId';

  static String metadata(String audioId) => 'quran_player_metadata_$audioId';
}

/// Album art that morphs between mini and expanded via [Hero].
class QuranPlayerHeroArtwork extends StatelessWidget {
  const QuranPlayerHeroArtwork({
    super.key,
    required this.audioId,
    required this.artUri,
    required this.borderRadius,
    required this.size,
    this.placeholderColor,
    this.iconColor,
    this.semanticDestination = false,
  });

  final String audioId;
  final String? artUri;
  final BorderRadius borderRadius;
  final Size size;
  final Color? placeholderColor;
  final Color? iconColor;
  final bool semanticDestination;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final barTokens = theme.componentTokens.mediaPlayerBar;
    final Color bg = placeholderColor ?? barTokens.artworkPlaceholderColor;
    final Color icon = iconColor ?? theme.colorScheme.onSurfaceVariant;

    final Widget image = artUri != null
        ? CachedNetworkImage(
            imageUrl: artUri!,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => _placeholder(tokens, bg, icon),
          )
        : _placeholder(tokens, bg, icon);

    return Hero(
      tag: QuranPlayerHeroTags.artwork(audioId),
      createRectTween: (begin, end) {
        return MaterialRectArcTween(begin: begin, end: end);
      },
      flightShuttleBuilder: (
        flightContext,
        animation,
        flightDirection,
        fromHeroContext,
        toHeroContext,
      ) {
        QuranPlayerDebugLog.hero(
          'flight.artwork',
          <String, Object?>{
            'direction': flightDirection.name,
            't': animation.value.toStringAsFixed(3),
            'audioId': audioId,
          },
        );
        final BorderRadius fromRadius = _readBorderRadius(fromHeroContext.widget);
        final BorderRadius toRadius = _readBorderRadius(toHeroContext.widget);
        final Widget shuttleChild = flightDirection == HeroFlightDirection.push
            ? toHeroContext.widget
            : fromHeroContext.widget;
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final double t = Curves.easeInOutCubic.transform(animation.value);
            return ClipRRect(
              borderRadius: BorderRadius.lerp(fromRadius, toRadius, t)!,
              child: child,
            );
          },
          child: shuttleChild,
        );
      },
      placeholderBuilder: (_, size, child) {
        return Opacity(
          opacity: 0,
          child: SizedBox.fromSize(size: size, child: child),
        );
      },
      child: Semantics(
        identifier: semanticDestination
            ? QuranPlayerSemanticsIds.expandedArtwork
            : null,
        image: semanticDestination,
        child: ClipRRect(
          borderRadius: borderRadius,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: image,
          ),
        ),
      ),
    );
  }

  static BorderRadius _readBorderRadius(Widget widget) {
    if (widget is QuranPlayerHeroArtwork) {
      return widget.borderRadius;
    }
    return BorderRadius.zero;
  }

  Widget _placeholder(TilawaDesignTokens tokens, Color bg, Color icon) {
    return ColoredBox(
      color: bg,
      child: Center(
        child: Icon(
          FluentIcons.music_note_2_24_filled,
          size: tokens.iconSizeLarge,
          color: icon,
        ),
      ),
    );
  }
}

/// Title + subtitle that morph between mini and expanded layouts via [Hero].
class QuranPlayerHeroMetadata extends StatelessWidget {
  const QuranPlayerHeroMetadata({
    super.key,
    required this.audioId,
    required this.title,
    required this.subtitle,
    required this.titleStyle,
    required this.subtitleStyle,
    this.centerAlign = false,
    this.semanticDestination = false,
  });

  final String audioId;
  final String title;
  final String subtitle;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final bool centerAlign;
  final bool semanticDestination;

  @override
  Widget build(BuildContext context) {
    final TextAlign align = centerAlign ? TextAlign.center : TextAlign.start;
    final CrossAxisAlignment cross = centerAlign
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;

    final Widget metadata = Column(
      crossAxisAlignment: cross,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          identifier: semanticDestination
              ? QuranPlayerSemanticsIds.expandedTrackTitle
              : null,
          child: Text(
            title,
            style: titleStyle,
            maxLines: centerAlign ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            textAlign: align,
          ),
        ),
        Semantics(
          identifier: semanticDestination
              ? QuranPlayerSemanticsIds.expandedTrackArtist
              : null,
          child: Text(
            subtitle,
            style: subtitleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: align,
          ),
        ),
      ],
    );

    return Hero(
      tag: QuranPlayerHeroTags.metadata(audioId),
      createRectTween: (begin, end) => MaterialRectArcTween(begin: begin, end: end),
      flightShuttleBuilder: (
        flightContext,
        animation,
        flightDirection,
        fromHeroContext,
        toHeroContext,
      ) {
        QuranPlayerDebugLog.hero(
          'flight.metadata',
          <String, Object?>{
            'direction': flightDirection.name,
            't': animation.value.toStringAsFixed(3),
            'audioId': audioId,
          },
        );
        final Widget shuttle = flightDirection == HeroFlightDirection.push
            ? toHeroContext.widget
            : fromHeroContext.widget;
        return Material(
          type: MaterialType.transparency,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: centerAlign ? Alignment.topCenter : Alignment.topLeft,
            child: shuttle,
          ),
        );
      },
      placeholderBuilder: (_, size, child) {
        return Opacity(
          opacity: 0,
          child: SizedBox.fromSize(size: size, child: child),
        );
      },
      child: Material(
        type: MaterialType.transparency,
        child: metadata,
      ),
    );
  }
}

/// Legacy imperative route — use [QuranPlayerExpandedRoute] (`/player`) instead.
@Deprecated('Use QuranPlayerExpandedRoute via GoRouter')
class QuranPlayerExpandedHeroRoute<T> extends PageRoute<T> {
  QuranPlayerExpandedHeroRoute({
    required this.pageBuilder,
    this.onTransitionStart,
    this.onTransitionEnd,
    super.settings,
  });

  final Widget Function(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  )
  pageBuilder;

  final VoidCallback? onTransitionStart;
  final VoidCallback? onTransitionEnd;

  double? _lastLoggedTransitionT;
  CurvedAnimation? _curvedPrimary;

  Animation<double> _primaryCurve(Animation<double> parent) {
    _curvedPrimary ??= CurvedAnimation(
      parent: parent,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return _curvedPrimary!;
  }

  @override
  void dispose() {
    _curvedPrimary?.dispose();
    super.dispose();
  }

  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 420);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 360);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return pageBuilder(
      context,
      _primaryCurve(animation),
      secondaryAnimation,
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Animation<double> curved = _primaryCurve(animation);

    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) {
        final double t = curved.value;
        final double? last = _lastLoggedTransitionT;
        if (last == null || (t - last).abs() >= 0.05 || t == 0 || t == 1) {
          _lastLoggedTransitionT = t;
          QuranPlayerDebugLog.hero(
            'route.transition',
            <String, Object?>{
              't': t.toStringAsFixed(3),
              'rawT': animation.value.toStringAsFixed(3),
              'status': animation.status.name,
            },
          );
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: scheme.surface.withValues(alpha: (0.88 * t).clamp(0.0, 0.88)),
            ),
            ColoredBox(
              color: scheme.scrim.withValues(alpha: (0.42 * t).clamp(0.0, 0.42)),
            ),
            child,
          ],
        );
      },
    );
  }

  @override
  TickerFuture didPush() {
    _lastLoggedTransitionT = null;
    QuranPlayerDebugLog.hero('route.push', const <String, Object?>{});
    onTransitionStart?.call();
    return super.didPush();
  }

  @override
  bool didPop(T? result) {
    _lastLoggedTransitionT = null;
    QuranPlayerDebugLog.hero('route.pop', const <String, Object?>{});
    onTransitionEnd?.call();
    return super.didPop(result);
  }
}

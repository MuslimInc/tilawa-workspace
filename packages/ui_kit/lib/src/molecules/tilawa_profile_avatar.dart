import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

/// How [TilawaProfileAvatar] renders when no photo is available.
enum TilawaProfileAvatarFallbackStyle {
  personIcon,
  initial,
}

/// Builds the network photo layer for [TilawaProfileAvatar].
///
/// Host apps can inject [CachedNetworkImage] (or similar) while keeping
/// circular clipping in the UI Kit.
typedef TilawaProfileAvatarImageBuilder =
    Widget Function(
      BuildContext context, {
      required String imageUrl,
      required Widget fallback,
    });

/// Circular user avatar with safe fallbacks for missing or failed photos.
///
/// Always renders a fixed square clipped with [ClipOval]. Never expands to
/// fill unbounded horizontal constraints.
class TilawaProfileAvatar extends StatelessWidget {
  const TilawaProfileAvatar({
    super.key,
    this.imageUrl,
    this.displayName,
    required this.size,
    this.backgroundColor,
    this.foregroundColor,
    this.fallbackStyle = TilawaProfileAvatarFallbackStyle.personIcon,
    this.textStyle,
    this.imageBuilder,
  });

  final String? imageUrl;
  final String? displayName;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final TilawaProfileAvatarFallbackStyle fallbackStyle;
  final TextStyle? textStyle;
  final TilawaProfileAvatarImageBuilder? imageBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final resolvedBackground =
        backgroundColor ?? colorScheme.surfaceContainerHigh;
    final resolvedForeground = foregroundColor ?? colorScheme.onSurfaceVariant;
    final fallback = _TilawaProfileAvatarFallback(
      displayName: displayName,
      size: size,
      backgroundColor: resolvedBackground,
      foregroundColor: resolvedForeground,
      fallbackStyle: fallbackStyle,
      textStyle: textStyle,
    );
    final resolvedUrl = imageUrl?.trim() ?? '';

    return Semantics(
      label: displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : null,
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: resolvedUrl.isEmpty
              ? fallback
              : _buildNetworkImage(
                  context,
                  resolvedUrl,
                  fallback,
                ),
        ),
      ),
    );
  }

  Widget _buildNetworkImage(
    BuildContext context,
    String url,
    Widget fallback,
  ) {
    final builder = imageBuilder;
    if (builder != null) {
      return builder(context, imageUrl: url, fallback: fallback);
    }

    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }
        return fallback;
      },
    );
  }
}

class _TilawaProfileAvatarFallback extends StatelessWidget {
  const _TilawaProfileAvatarFallback({
    required this.displayName,
    required this.size,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.fallbackStyle,
    this.textStyle,
  });

  final String? displayName;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;
  final TilawaProfileAvatarFallbackStyle fallbackStyle;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = _initialFor(displayName);
    final useInitial =
        fallbackStyle == TilawaProfileAvatarFallbackStyle.initial &&
        initial != null;

    return ColoredBox(
      color: backgroundColor,
      child: Center(
        child: useInitial
            ? Text(
                initial,
                style:
                    textStyle ??
                    theme.textTheme.titleMedium?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w800,
                      fontSize: size * 0.42,
                    ),
              )
            : Icon(
                FluentIcons.person_24_regular,
                size: size * 0.5,
                color: foregroundColor,
              ),
      ),
    );
  }

  static String? _initialFor(String? value) {
    final name = value?.trim();
    if (name == null || name.isEmpty) {
      return null;
    }
    return name.characters.first.toUpperCase();
  }
}

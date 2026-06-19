import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

/// How [ProfileAvatar] renders when no network photo is available.
enum ProfileAvatarFallbackStyle {
  personIcon,
  initial,
}

/// Circular profile image loaded from a remote URL (e.g. Firebase Auth photo).
///
/// Falls back to a person icon or an initial letter when the URL is empty or
/// fails to load.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.photoUrl,
    this.displayName,
    required this.size,
    this.backgroundColor,
    this.foregroundColor,
    this.fallbackStyle = ProfileAvatarFallbackStyle.personIcon,
    this.textStyle,
  });

  final String? photoUrl;
  final String? displayName;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final ProfileAvatarFallbackStyle fallbackStyle;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String resolvedUrl = photoUrl?.trim() ?? '';
    final Color resolvedBackground =
        backgroundColor ?? colorScheme.surfaceContainerHigh;
    final Color resolvedForeground =
        foregroundColor ?? colorScheme.onSurfaceVariant;

    if (resolvedUrl.isEmpty) {
      return _ProfileAvatarFallback(
        displayName: displayName,
        size: size,
        backgroundColor: resolvedBackground,
        foregroundColor: resolvedForeground,
        fallbackStyle: fallbackStyle,
        textStyle: textStyle,
      );
    }

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: CachedNetworkImage(
          imageUrl: resolvedUrl,
          fit: BoxFit.cover,
          placeholder: (_, _) => _ProfileAvatarFallback(
            displayName: displayName,
            size: size,
            backgroundColor: resolvedBackground,
            foregroundColor: resolvedForeground,
            fallbackStyle: fallbackStyle,
            textStyle: textStyle,
          ),
          errorWidget: (_, _, _) => _ProfileAvatarFallback(
            displayName: displayName,
            size: size,
            backgroundColor: resolvedBackground,
            foregroundColor: resolvedForeground,
            fallbackStyle: fallbackStyle,
            textStyle: textStyle,
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatarFallback extends StatelessWidget {
  const _ProfileAvatarFallback({
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
  final ProfileAvatarFallbackStyle fallbackStyle;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: backgroundColor,
      child: Center(
        child: switch (fallbackStyle) {
          ProfileAvatarFallbackStyle.personIcon => Icon(
            FluentIcons.person_24_regular,
            size: size * 0.5,
            color: foregroundColor,
          ),
          ProfileAvatarFallbackStyle.initial => Text(
            _initialFor(displayName),
            style:
                textStyle ??
                theme.textTheme.titleMedium?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w800,
                ),
          ),
        },
      ),
    );
  }

  String _initialFor(String? value) {
    final String? name = value?.trim();
    if (name == null || name.isEmpty) {
      return 'T';
    }
    return name.characters.first.toUpperCase();
  }
}

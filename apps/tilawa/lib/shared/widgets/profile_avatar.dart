import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

export 'package:tilawa_ui_kit/src/molecules/tilawa_profile_avatar.dart'
    show
        TilawaProfileAvatar,
        TilawaProfileAvatarFallbackStyle,
        TilawaProfileAvatarImageBuilder;

typedef ProfileAvatarFallbackStyle = TilawaProfileAvatarFallbackStyle;

/// Profile avatar for the phone bottom nav settings tab.
///
/// When [isSelected], draws a primary ring outside the circular photo.
class ProfileNavAvatar extends StatelessWidget {
  const ProfileNavAvatar({
    super.key,
    required this.size,
    required this.isSelected,
    required this.ringColor,
    this.photoUrl,
    this.displayName,
  });

  final String? photoUrl;
  final String? displayName;
  final double size;
  final bool isSelected;
  final Color ringColor;

  @override
  Widget build(BuildContext context) {
    final double ringWidth = Theme.of(context).tokens.focusRingWidth;
    final double avatarSize = isSelected ? size - ringWidth * 2 : size;

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: ringColor, width: ringWidth)
              : null,
        ),
        child: Center(
          child: ProfileAvatar(
            photoUrl: photoUrl,
            displayName: displayName,
            size: avatarSize,
            fallbackStyle: ProfileAvatarFallbackStyle.initial,
          ),
        ),
      ),
    );
  }
}

/// App-facing profile avatar — delegates circular layout to [TilawaProfileAvatar]
/// and uses [CachedNetworkImage] for remote photos.
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
    return TilawaProfileAvatar(
      imageUrl: photoUrl,
      displayName: displayName,
      size: size,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      fallbackStyle: fallbackStyle,
      textStyle: textStyle,
      imageBuilder: (context, {required imageUrl, required fallback}) {
        return CachedNetworkImage(
          imageUrl: imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, _) => fallback,
          errorWidget: (_, _, _) => fallback,
        );
      },
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

export 'package:tilawa_ui_kit/src/molecules/tilawa_profile_avatar.dart'
    show
        TilawaProfileAvatar,
        TilawaProfileAvatarFallbackStyle,
        TilawaProfileAvatarImageBuilder;

typedef ProfileAvatarFallbackStyle = TilawaProfileAvatarFallbackStyle;

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

import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Circular avatar that shows the teacher's initials when no photo is available.
///
/// Color is derived deterministically from the teacher's name so the same
/// teacher always gets the same colour across screens.
class TeacherInitialsAvatar extends StatelessWidget {
  const TeacherInitialsAvatar({
    super.key,
    required this.displayName,
    required this.radius,
    this.avatarUrl,
  });

  final String displayName;
  final double radius;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasPhoto = avatarUrl != null && avatarUrl!.isNotEmpty;

    if (hasPhoto) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatarUrl!),
      );
    }

    final (background, foreground) = _avatarColors(displayName, scheme);
    final rawInitials = AvatarInitialsFromName.extract(displayName);
    final textStyle = TextStyle(
      color: foreground,
      fontWeight: FontWeight.w700,
      fontSize: radius * 0.65,
    );
    final initials = AvatarInitialsDisplay.formatForTextStyle(
      rawInitials,
      textStyle,
    );

    return CircleAvatar(
      radius: radius,
      backgroundColor: background,
      child: initials.isEmpty
          ? Icon(Icons.person, color: foreground, size: radius * 0.9)
          : Text(initials, style: textStyle),
    );
  }

  static List<(Color, Color)> _palette(ColorScheme scheme) => [
    (scheme.primaryContainer, scheme.onPrimaryContainer),
    (scheme.secondaryContainer, scheme.onSecondaryContainer),
    (scheme.tertiaryContainer, scheme.onTertiaryContainer),
    (scheme.errorContainer, scheme.onErrorContainer),
    (scheme.primaryFixed, scheme.onPrimaryFixed),
    (scheme.secondaryFixed, scheme.onSecondaryFixed),
    (scheme.tertiaryFixed, scheme.onTertiaryFixed),
  ];

  static (Color, Color) _avatarColors(String name, ColorScheme scheme) {
    final hash = name.codeUnits.fold(0, (acc, c) => acc + c);
    return _palette(scheme)[hash % _palette(scheme).length];
  }
}

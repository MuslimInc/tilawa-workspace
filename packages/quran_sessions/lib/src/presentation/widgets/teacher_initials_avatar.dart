import 'package:flutter/material.dart';

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
    final hasPhoto = avatarUrl != null && avatarUrl!.isNotEmpty;

    if (hasPhoto) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatarUrl!),
      );
    }

    final color = _avatarColor(displayName);
    final initials = _initials(displayName);

    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.65,
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '؟';
    if (words.length == 1) return words[0].characters.first;
    // Use first characters of first and last word, skip common prefixes.
    final skip = {'الشيخ', 'أ.', 'د.', 'أ', 'د'};
    final meaningful = words.where((w) => !skip.contains(w)).toList();
    if (meaningful.isEmpty) return words.first.characters.first;
    if (meaningful.length == 1) return meaningful[0].characters.first;
    return '${meaningful[0].characters.first}${meaningful[1].characters.first}';
  }

  static final List<Color> _palette = [
    const Color(0xFF5B7FA6),
    const Color(0xFF7A9E7E),
    const Color(0xFF9B6B6B),
    const Color(0xFF7B6B9B),
    const Color(0xFF9B8B5B),
    const Color(0xFF5B9B9B),
    const Color(0xFF9B7B5B),
  ];

  static Color _avatarColor(String name) {
    final hash = name.codeUnits.fold(0, (acc, c) => acc + c);
    return _palette[hash % _palette.length];
  }
}

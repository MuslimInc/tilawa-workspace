import 'package:flutter/material.dart';

import '../../domain/entities/quran_teacher.dart';

/// Compact card showing teacher avatar, name, rating, and price.
/// Used in [TeacherListScreen] and search results.
class TeacherCard extends StatelessWidget {
  const TeacherCard({
    super.key,
    required this.teacher,
    required this.onTap,
  });

  final QuranTeacher teacher;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundImage: NetworkImage(teacher.avatarUrl)),
        title: Text(teacher.displayName),
        subtitle: Text('★ ${teacher.averageRating.toStringAsFixed(1)}'),
        onTap: onTap,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../domain/entities/quran_session.dart';

/// Card showing session time, teacher name, and status badge.
/// Used in [MySessionsScreen].
class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.session,
    this.onJoin,
    this.onCancel,
  });

  final QuranSession session;
  final VoidCallback? onJoin;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(session.startsAt.toLocal().toString()),
        subtitle: Text(session.status.name),
        trailing: onJoin != null
            ? TextButton(onPressed: onJoin, child: const Text('Join'))
            : null,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/quran_sessions_theme.dart';

/// Feature-scoped scaffold for Quran Tutor student flows.
class QuranSessionsScaffold extends StatelessWidget {
  const QuranSessionsScaffold({
    super.key,
    required this.title,
    required this.body,
    this.bottomNavigationBar,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final Widget? bottomNavigationBar;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final feature = QuranSessionsTheme.of(context);

    return Scaffold(
      backgroundColor: feature.scaffoldBackground,
      appBar: AppBar(
        title: Text(title, style: feature.screenTitleStyle),
        actions: actions,
      ),
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}

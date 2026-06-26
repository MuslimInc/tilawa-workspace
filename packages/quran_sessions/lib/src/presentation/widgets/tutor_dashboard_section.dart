import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Compact section title for [TeacherDashboardScreen].
class TutorDashboardSection extends StatelessWidget {
  const TutorDashboardSection({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return TilawaSectionHeader(
      title: title,
      padding: EdgeInsetsDirectional.fromSTEB(
        tokens.spaceLarge,
        tokens.spaceMedium,
        tokens.spaceLarge,
        tokens.spaceExtraSmall,
      ),
    );
  }
}

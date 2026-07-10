import 'package:flutter/material.dart';

/// Settings/Profile entry for experienced Quran teachers to apply via Google Form.
///
/// Intentionally hidden — teacher onboarding is admin-only.
class SettingsTeacherApplicationEntrySection extends StatelessWidget {
  const SettingsTeacherApplicationEntrySection({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Legacy tile kept for tests; never shown in production settings.
class SettingsTeacherApplicationEntryTile extends StatelessWidget {
  const SettingsTeacherApplicationEntryTile({
    super.key,
    this.showDivider = true,
  });

  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

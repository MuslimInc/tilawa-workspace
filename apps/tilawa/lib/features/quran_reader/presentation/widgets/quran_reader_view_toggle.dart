import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/quran_reader/domain/entities/entities.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Toggles between Mushaf pages and the Behance-style ayah list reader.
///
/// Rendered inside the reader's bottom navigation panel (thumb-reachable).
class QuranReaderViewToggle extends StatelessWidget {
  const QuranReaderViewToggle({
    super.key,
    required this.currentMode,
    required this.onPressed,
  });

  final QuranReaderViewMode currentMode;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bool switchToAyahList = currentMode == QuranReaderViewMode.mushaf;
    final IconData icon = switchToAyahList
        ? Icons.view_list_rounded
        : Icons.menu_book_rounded;
    final String label = switchToAyahList
        ? context.l10n.quranSwitchToAyahList
        : context.l10n.quranSwitchToMushaf;

    return TilawaIconActionButton(
      icon: icon,
      tooltip: label,
      semanticLabel: label,
      onTap: onPressed,
    );
  }
}

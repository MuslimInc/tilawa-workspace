import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../src/foundation/foundation.dart';
import '../src/molecules/molecules.dart';
import '../src/organisms/organisms.dart';
import '../src/previews/preview_wrapper.dart';

// --- TilawaGlassPanel Previews ---

@Preview(name: 'TilawaGlassPanel / Light', group: 'Molecules')
Widget previewTilawaGlassPanelLight() {
  return const TilawaPreviewWrapper(
    child: TilawaGlassPanel(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Text('Glass Panel Content'),
      ),
    ),
  );
}

@Preview(name: 'TilawaGlassPanel / Dark', group: 'Molecules')
Widget previewTilawaGlassPanelDark() {
  return const TilawaPreviewWrapper(
    isDark: true,
    child: TilawaGlassPanel(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Text('Dark Glass Panel'),
      ),
    ),
  );
}

// --- TilawaStatusChip Previews ---

@Preview(name: 'TilawaStatusChip / Success', group: 'Molecules')
Widget previewTilawaStatusChipSuccess() {
  return const TilawaPreviewWrapper(
    child: TilawaStatusChip(label: 'Completed'),
  );
}

@Preview(name: 'TilawaStatusChip / Warning', group: 'Molecules')
Widget previewTilawaStatusChipWarning() {
  return const TilawaPreviewWrapper(child: TilawaStatusChip(label: 'Pending'));
}

@Preview(name: 'TilawaStatusChip / Error', group: 'Molecules')
Widget previewTilawaStatusChipError() {
  return const TilawaPreviewWrapper(child: TilawaStatusChip(label: 'Failed'));
}

@Preview(name: 'TilawaStatusChip / RTL', group: 'Molecules')
Widget previewTilawaStatusChipRTL() {
  return const TilawaPreviewWrapper(
    isRTL: true,
    child: TilawaStatusChip(label: 'ناجح'),
  );
}

// --- TilawaHubNavigationGroup Previews ---

@Preview(name: 'TilawaHubNavigationGroup / Light', group: 'Molecules')
Widget previewTilawaHubNavigationGroupLight() {
  return TilawaPreviewWrapper(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: TilawaHubNavigationGroup(
        children: [
          TilawaNavigationRow(
            icon: Icons.auto_stories_outlined,
            title: 'Daily plan',
            subtitle: 'Pages and surahs scheduled for today.',
            onTap: () {},
            semanticTint: TilawaSemanticTint.ink,
          ),
          TilawaNavigationRow(
            icon: Icons.history,
            title: 'Reading history',
            subtitle: 'Past sessions and where you left off.',
            onTap: () {},
            semanticTint: TilawaSemanticTint.parchment,
          ),
          TilawaNavigationRow(
            icon: Icons.insights_outlined,
            title: 'Statistics',
            subtitle: 'Progress over the last seven days.',
            onTap: () {},
            semanticTint: TilawaSemanticTint.scholar,
            showDivider: false,
          ),
        ],
      ),
    ),
  );
}

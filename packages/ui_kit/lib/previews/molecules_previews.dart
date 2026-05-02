import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../src/molecules/molecules.dart';
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
